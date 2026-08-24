---
name: documentum-idempotent-scripting
description: Patterns for writing idempotent bash scripts that provision or modify an OpenText Documentum repository by composing DQL and API (iapi/idql) calls — existence-check-before-create for types, attributes and objects, output-based error detection (iapi/idql exit 0 even when a command fails), and safe session lifecycle. Use when writing or reviewing a bash script that runs DQL/API commands against a Documentum docbase, especially anything that creates or alters repository objects.
---

# Documentum Idempotent Scripting

Knowing DQL and knowing the API are both common. What's not obvious is
composing the two into a bash script that's safe to run twice — a re-run
after a partial failure, or a script applied across dev/test/prod docbases,
should converge on the same end state instead of crashing on "already
exists" or silently double-creating things. Each pattern below exists
because the naive script (call `create`, assume success) has a specific,
real failure mode against a live docbase. Skip a pattern where its problem
genuinely can't occur — these are tools for known failure modes, not a
checklist to apply blindly.

## 1. Existence check before create — for every object kind, not just types

**Failure mode:** a script calls `CREATE TYPE`, `create,c,dm_folder`, or
similar unconditionally. First run works. Second run — a re-run after the
script died partway through on something unrelated, or a re-apply to a
docbase that already has the object — fails with an "already exists" DQL/API
error, and the script (or its caller) treats that as a hard failure even
though the desired end state already holds.

**Mechanism:** every creation step is really two steps: a DQL existence
check, then a conditional create. Never branch on the create call's success
alone — branch on whether the object was there *before* you acted.

```bash
type_exists() {
  local -r type_name="$1"
  local -r count=$(idql "$DOCBASE" -U"$DM_USER" -Pf"$DM_PW_FILE" -e -q <<EOF
SELECT COUNT(*) AS cnt FROM dm_type WHERE name = '${type_name}'
EOF
)
  [[ "$count" =~ cnt[[:space:]]*[^0]|[1-9] ]]  # non-zero count, see pattern 2 for real parsing
}

ensure_type_exists() {
  local -r type_name="$1"
  if type_exists "$type_name"; then
    echo "type ${type_name} already present, skipping create"
    return 0
  fi
  create_type "$type_name"
}
```

The exact parsing shown here is a placeholder — see pattern 2 for why you
can't just trust exit codes or a naive grep, and pattern 4 for why "the type
exists" and "the type has every attribute this run wants" are two separate
checks.

## 2. `iapi`/`idql` exit 0 on error — never trust `$?` alone

**Failure mode:** a DQL syntax error, a duplicate-object error, or a
permission failure happens *inside* an `iapi`/`idql` session, but the shell
process itself still exits 0 — it successfully ran a session and printed an
error message to stdout, which from bash's point of view is success. A
script that does `idql ... || die` never trips, and a later step then acts
on a query result that was actually an error string, not data.

**Mechanism:** capture stdout and grep it for Documentum's error-code
convention — a bracketed `[DM_<AREA>_<SEVERITY>_...]` token, e.g.
`[DM_QUERY_E_SYNTAX]` or `[DM_API_E_EXIST]`. Treat that as the real failure
signal, independent of `$?`.

```bash
run_dql() {
  local -r script="$1"
  local output
  output=$(idql "$DOCBASE" -U"$DM_USER" -Pf"$DM_PW_FILE" -e -q <<<"$script")
  if grep -qE '\[DM_[A-Z_]+_E_[A-Z_]+\]' <<<"$output"; then
    echo "DQL failed: $(grep -E '\[DM_[A-Z_]+_E_[A-Z_]+\]' <<<"$output")" >&2
    return 1
  fi
  printf '%s\n' "$output"
}
```

An `[DM_API_E_EXIST]`-style "already exists" error specifically is not a
failure worth propagating if you got there through a bug in pattern 1's
check — fix the check instead of swallowing this error class, since
swallowing it hides the case where the existence check and the create
target genuinely disagree (e.g. race with another script).

## 3. Idempotent type creation — the concrete case

**Failure mode:** `CREATE TYPE` run twice against the same docbase fails
the second time with an object-already-exists error, which is exactly the
scenario in pattern 1 but worth spelling out because type creation is
DQL DDL, not an `iapi` `create,c,...` call — the check and the create use
different tools against the same object.

**Mechanism:**

```bash
ensure_type() {
  local -r name="$1" supertype="$2" columns="$3"
  if [[ $(run_dql "SELECT COUNT(*) AS cnt FROM dm_type WHERE name = '${name}'" \
          | awk '/^cnt/{getline; print $1}') -gt 0 ]]; then
    echo "type ${name} exists, skipping CREATE TYPE"
    return 0
  fi
  run_dql "CREATE TYPE ${name} (${columns}) WITH SUPERTYPE ${supertype} PUBLISH"
}

ensure_type "my_custom_type" "dm_document" "due_date DATE, priority INTEGER"
```

Run this script any number of times against the same docbase and the type
either gets created once or is left untouched — never a crash, never a
second attempt.

## 4. Attribute-level idempotency is a separate check from type-level

**Failure mode:** a later revision of the provisioning script adds a new
column to `ensure_type`'s column list. Pattern 3's check alone now lies —
the type already exists, so the whole `CREATE TYPE` is skipped, and the new
attribute silently never gets added. This is the schema-evolution trap:
"the type exists" and "the type has this attribute" are different facts.

**Mechanism:** check attribute existence independently (Documentum exposes
a type's attributes via `dm_type` composite attributes / `dump,c,type_name`
output), and add missing ones with `ALTER TYPE ... ADD COLUMN`, itself
idempotent the same way:

```bash
ensure_attribute() {
  local -r type_name="$1" attr_name="$2" attr_def="$3"
  local -r cnt=$(run_dql "EXECUTE get_type_attr_count \
    WITH type_name='${type_name}', attr_name='${attr_name}'" | awk '/^cnt/{getline; print $1}')
  if [[ "$cnt" -gt 0 ]]; then
    echo "attribute ${attr_name} already on ${type_name}, skipping"
    return 0
  fi
  run_dql "ALTER TYPE ${type_name} ADD COLUMN ${attr_name} ${attr_def} PUBLISH"
}
```

(`get_type_attr_count` stands in for whatever query your docbase version
actually uses to enumerate a type's attributes — `dump,c` parsing or a
`dmi_dd_attr_info` query both work; the point is that it's a query scoped to
one attribute, run every time, not folded into the type-level check.)

## 5. Session lifecycle: connect once, always disconnect, even on failure

**Failure mode:** a script opens an `iapi`/`idql` session per command
(cheap to write, expensive to run — repeated auth/session setup) or opens
one session and exits early on an error without disconnecting, leaking
sessions that count against the docbase's concurrent-session limit until
they time out.

**Mechanism:** open one session, capture its session id from the connect
output, and register a `trap` that disconnects on any exit path —
success, error, or an early `return`/`exit` triggered by `set -e`.

```bash
set -euo pipefail

SESSION_ID=""
cleanup() {
  [[ -n "$SESSION_ID" ]] && iapi "$DOCBASE" -U"$DM_USER" -Pf"$DM_PW_FILE" -e \
    <<<"disconnect,${SESSION_ID}"
}
trap cleanup EXIT

SESSION_ID=$(iapi "$DOCBASE" -U"$DM_USER" -Pf"$DM_PW_FILE" -e <<<"connect,${DOCBASE},${DM_USER}" \
  | grep -oE 's[0-9]+' | head -1)
```

Because `cleanup` runs from `trap ... EXIT`, a mid-script failure under
`set -e` still disconnects — the script fails loudly on the real error
instead of also leaking a session.

## 6. Get-or-create must return the object's ID either way

**Failure mode:** a "create if missing" helper (pattern 1) returns success
or failure, but callers usually need the object's `r_object_id` for the
next step — attaching a document to a folder that may or may not have just
been created, for instance. A helper that only returns on the create path
leaves the caller with no ID when the object already existed, and the
caller either crashes or re-parses output it doesn't have.

**Mechanism:** `get_or_create_*` always resolves and echoes the ID as its
last action, whether that ID came from the existence check or from parsing
the create call's `NEW OBJECT ID = ...` output line — the caller never
needs to know which branch ran.

```bash
get_or_create_folder() {
  local -r path="$1" cabinet="$2"
  local id
  id=$(run_dql "SELECT r_object_id FROM dm_folder WHERE object_name = '${path}' \
    AND FOLDER('/${cabinet}')" | awk '/^r_object_id/{getline; print $1}')
  if [[ -n "$id" ]]; then
    printf '%s\n' "$id"
    return 0
  fi
  iapi "$DOCBASE" -U"$DM_USER" -Pf"$DM_PW_FILE" -e <<EOF | grep -oE '[0-9a-f]{16}' | tail -1
create,c,dm_folder
set,c,l,object_name
${path}
link,c,l,/${cabinet}
save,c,l
EOF
}
```

## 7. Never pass the password as a bare CLI argument

**Failure mode:** `iapi docbase -Uuser -Ppassword` puts the plaintext
password on the process command line, visible to any other user on the box
via `ps aux` / `/proc/<pid>/cmdline` for as long as the process runs — a
credential leak independent of whether the script itself is otherwise
correct.

**Mechanism:** use `iapi`/`idql`'s `-Pf<file>` flag to read the password
from a file (permissions `600`, owned by the script's user) instead of
`-P<password>`, and keep that file out of version control alongside the
rest of your secrets handling.

```bash
umask 077
printf '%s' "$DM_PASSWORD" > "$DM_PW_FILE"
iapi "$DOCBASE" -U"$DM_USER" -Pf"$DM_PW_FILE" -e <<<"connect,${DOCBASE},${DM_USER}"
```
