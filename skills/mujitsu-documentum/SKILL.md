---
name: mujitsu-documentum
description: Patterns for writing idempotent bash scripts that provision, bulk-update, or bulk-delete objects in an OpenText Documentum repository by composing DQL and API (iapi/idql) calls — existence-check-before-create for types, attributes and objects, output-based error detection (iapi/idql exit 0 even when a command fails), safe session lifecycle, and batching large updates/deletes into packets instead of one unbounded statement. Use when writing or reviewing a bash script that runs DQL/API commands against a Documentum docbase, especially anything that creates, alters, or bulk-mutates repository objects.
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

## 8. A successful `dmadmin` connect doesn't prove the password was checked

**Failure mode:** a script runs as the OS user matching the docbase owner
(typically `dmadmin`) directly on the content server, with trusted login in
effect for that local session. In that mode Documentum authenticates on OS
identity, not the password string — `connect,${DOCBASE},dmadmin,anything`
succeeds no matter what follows `-P`. A script (or a person debugging one)
that treats "connect succeeded" as confirmation the credential file holds
the right password gets a false positive; the same script run as a
different OS user, from a different host, or against a docbase with trust
disabled, will suddenly need the real password and fail in a way local
testing never caught.

**Mechanism:** know which trust mode a script is meant to run under, and
say so where it connects — a comment or a variable name is enough, since
there's no portable way to query trust status before connecting. Local
`dmadmin`-owner scripts can lean on trusted login and treat the password
value as a formality (this is why "hit `-Peppa`" works fine there — it's
not a real secret in that mode, pattern 7's `ps`-exposure concern just
doesn't apply to it). A script meant to also run remotely, as a different
user, or in CI needs a real credential path (pattern 7) and should not
assume a bare connect proves anything about which one it used.

## 9. Bulk update/delete in packets: `ENABLE (RETURN_TOP n)`, looped

**Failure mode:** a single `UPDATE ... OBJECTS SET ...` or
`DELETE ... OBJECTS WHERE ...` touching a large number of rows runs as one
long statement — it holds locks on every matching row for the whole
duration (blocking other readers/writers on that table), risks a huge
rollback/transaction footprint, and if the session dies partway through,
there's no visibility into how many rows actually committed before the
failure.

**Mechanism:** cap the statement with DQL's `ENABLE (RETURN_TOP n)` hint so
each execution only touches the first `n` qualifying rows, then loop the
*same* statement until it reports 0 rows affected. This is naturally
idempotent-safe as long as the `SET`/`DELETE` moves rows out of the `WHERE`
clause's matching set — each rerun's `WHERE` only sees what's still
pending, so a mid-run failure just means "run the loop again," no separate
progress tracking needed.

```bash
BATCH_SIZE=500
while true; do
  affected=$(run_dql "UPDATE dm_document OBJECTS SET a_status = 'archived' \
    WHERE a_status = 'pending' AND r_creation_date < DATE('2020-01-01') \
    ENABLE (RETURN_TOP ${BATCH_SIZE})" \
    | grep -oE '[0-9]+ objects? affected' | awk '{print $1}')
  [[ "${affected:-0}" -eq 0 ]] && break
  echo "archived ${affected} objects this batch"
done
```

`DELETE` self-terminates the same way — a deleted row can never match the
`WHERE` again, so the loop condition is automatically satisfied. The one
correctness trap: if the `WHERE` clause does **not** become false for rows
the statement just changed (e.g. the `SET` doesn't touch any column the
`WHERE` filters on), the loop re-touches the same first `n` rows forever —
verify that relationship before relying on this pattern, not after.

## 10. ID-batch + per-object API loop, when per-object logic must fire

**Failure mode:** some bulk operations can't be expressed as one set-based
DQL statement at all — checkout/checkin versioning, a lifecycle state
transition, an ACL change that needs `save`/`checkin` semantics — because
DQL's `UPDATE ... OBJECTS` only sets attributes directly and skips the
API-layer behavior (workflow triggers, lifecycle validation, versioning)
that those operations require. Forcing them into raw DQL either isn't
supported or silently bypasses that behavior.

**Mechanism:** `SELECT` ids in bounded batches (`ENABLE (RETURN_TOP n)`
again), then loop individual API commands over each id in the batch.
Unlike pattern 9, this loop is not transactional across the batch — one
object's API call failing midway leaves earlier objects in the batch
already mutated with no atomic marker — so track processed ids explicitly
and skip them on retry, the same "state must be resumable" discipline as
pattern 6's get-or-create.

```bash
BATCH_SIZE=200
while true; do
  ids=$(run_dql "SELECT r_object_id FROM dm_document \
    WHERE a_status = 'pending' ENABLE (RETURN_TOP ${BATCH_SIZE})" \
    | awk '/^090/{print $1}')
  [[ -z "$ids" ]] && break
  while IFS= read -r id; do
    grep -qxF "$id" "$PROCESSED_LOG" 2>/dev/null && continue
    iapi "$DOCBASE" -U"$DM_USER" -Pf"$DM_PW_FILE" -e <<EOF
checkout,c,${id}
set,c,l,a_status
archived
checkin,c,l
EOF
    echo "$id" >> "$PROCESSED_LOG"
  done <<< "$ids"
done
```

As in pattern 9, the `SELECT`'s `WHERE` should become false once an object
is processed (`a_status` moves off `pending`) so the candidate set shrinks
on its own across reruns — the `$PROCESSED_LOG` is still needed as a
finer-grained marker for a failure *inside* a batch, which the `WHERE`
clause alone can't detect until the whole object is actually updated.
