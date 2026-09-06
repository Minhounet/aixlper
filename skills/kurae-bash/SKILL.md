---
name: kurae-bash
description: Ten hardening patterns for building a robust, interactive bash CLI tool or shell helper — readline/bind -x dispatch, annotation-driven command registries, build-time comment stripping, layered config precedence, avoiding eval on dynamic commands, atomic file writes, double-load guards, framework-free unit testing, strict mode, and exact-match list filtering. Use whenever writing or reviewing bash that defines interactive keybindings, ships as a sourced shell helper (.bashrc/profile.d), parses its own source for a command palette/help system, reads layered config files, or needs unit tests without a test framework.
---

# Bash CLI Patterns

Ten patterns for bash tools that go beyond a one-off script — things that get
sourced into a live shell, bind keys, hold config, or need tests. Each one
exists because the naive version has a specific, real failure mode. Skip a
pattern where its problem genuinely can't occur (a script with no `bind -x`
doesn't need pattern 1) — these are tools for known failure modes, not a
checklist to apply blindly.

## 1. `bind -x` runs in readline raw mode — `read` cannot receive keystrokes

**Failure mode:** you bind a key to a function that calls `read` to prompt
the user, or that needs typed arguments. Inside a `bind -x` callback the
terminal is in readline's raw input mode, so the `read` builtin silently
fails to receive keystrokes — the function looks like it hung, or it reads
garbage/empty input.

**Mechanism:** don't execute such commands directly from the keybinding.
Instead, place the command text onto the user's actual command line and let
them press Enter — at that point the shell is back in normal line-editing
mode and `read` works fine. Bash exposes the command line as `READLINE_LINE`
(with `READLINE_POINT` for cursor position) precisely for this — a `bind -x`
callback can rewrite what's about to be submitted instead of running it.

```bash
_dispatch() {
  local -r cmd="$1" needs_input="$2"
  if [[ "$needs_input" == "true" ]]; then
    READLINE_LINE="$cmd "
    READLINE_POINT=${#READLINE_LINE}
  else
    eval "$cmd"   # safe here only because $cmd is a known, non-user-derived command name
  fi
}
```

Plain commands that take no input and don't prompt can still run immediately
on keypress — the constraint only bites for anything that calls `read` or
needs the user to type arguments afterward.

## 2. Annotation-driven command registry, not a hand-maintained list

**Failure mode:** a tool with many keybindings/commands keeps a separate
help table or palette listing them. Every time a command is added, renamed,
or rebound, the table has to be updated by hand — and it drifts, because
nothing forces the two to move together. Eventually the help text lies.

**Mechanism:** put the metadata in a structured comment directly above the
function it describes, then parse those comments (at runtime from source, or
at build time into a generated index) to produce the palette/help output.
The single source of truth is the function definition itself; the listing is
derived, not maintained.

```bash
# @cmd: description="Tail a log file with a grep filter" category=Logs \
#       keybind="CTRL+X+L" args="FILE PATTERN"
function logtail() { ... }
```

A parser walks source files, matches the annotation line, and pulls fields
out with a regex per field (or by splitting on `key="value"` pairs). Because
the annotation lives next to the code, adding a new command automatically
means adding its palette entry — there's no second place to remember.

## 3. Comment-stripping build steps must preserve annotations generically

**Failure mode:** a build/minify step strips `#`-comments from the shipped
artifact to shrink it. If it does so with a naive rule, it strips the
annotation comments from pattern 2 too — the palette parser then finds
nothing in the packaged build, even though it works fine against the
uncommitted source tree. This is a nasty class of bug because it's invisible
in dev and only shows up after packaging/install.

**Mechanism:** don't special-case which annotations to keep by name (a
whitelist silently goes stale the day someone adds a new annotation type).
Instead, strip on the *shape* of the line: keep anything that looks like an
annotation, drop other comments.

```bash
# Delete comment lines EXCEPT ones starting with "# @" (any annotation).
sed -i '/^#[[:space:]]*@/!{/^#.*/d}' "$output_file"
```

Because this is shape-based, a brand-new annotation type needs zero build
changes to survive packaging.

## 4. Layered config precedence via load order, not an explicit merge

**Failure mode:** a tool supports system-wide defaults, per-user overrides,
and maybe a legacy config location, and needs later sources to win. Writing
an explicit merge function (loop over keys, compare, pick the higher-
precedence one) is extra code that has to be kept in sync with every new
setting.

**Mechanism:** source the files in low-to-high precedence order, and inside
each file only set a variable if it isn't already set (`VAR="${VAR:-default}"`
or, for exported values, guard the assignment). Precedence then falls out of
*load order* for free — no merge logic, and no risk of the merge logic
missing a variable that was added later.

```bash
[[ -f /etc/mytool/mytool.conf ]] && source /etc/mytool/mytool.conf   # lowest
[[ -f "$HOME/.config/mytool/mytool.conf" ]] && source "$HOME/.config/mytool/mytool.conf"  # highest
```

Each file's own lines use `export VAR="${VAR:-default}"` so a value already
set by an earlier (or higher-precedence, depending on direction) layer is
left alone rather than clobbered.

## 5. Never `eval` a captured/dynamic command string — write it to a file and `source` it

**Failure mode:** you capture a command as text (from `history`, user input,
a macro recorder) and later need to execute it. The tempting shortcut is
`eval "$cmd"` or interpolating it into a larger quoted string
(`eval "bind -x '...: ( $cmd )'"`). Both break the moment the captured text
contains a single quote (`echo 'hello'` closes the outer quoting early) and
both risk expanding backticks or `$()` a second time — at the wrong moment,
against the wrong environment.

**Mechanism:** write the captured commands as literal lines into a small
generated script (a function body works well), then `source` that file.
`printf '%s\n' "$cmd"` writes the text byte-for-byte with no re-parsing;
sourcing it lets bash parse it exactly once, the normal way, with no
quoting hazard.

```bash
{
  printf 'replay() {\n'
  printf '  %s\n' "${captured_commands[@]}"
  printf '}\n'
} > "$binding_file"
source "$binding_file"
```

## 6. Atomic writes: write to a temp file, then `mv` over the target

**Failure mode:** a script rewrites a state file in place (truncate and
write). If it's interrupted mid-write — crash, killed process, a concurrent
reader — the file is left half-written or empty, and whatever reads it next
gets corrupted or truncated data.

**Mechanism:** write the new content to a fresh file created with `mktemp`
(same filesystem as the target, so the following `mv` is a rename, not a
copy), then `mv` it over the real path. A rename within one filesystem is
atomic — readers see either the old file or the fully-written new one, never
a partial state.

```bash
local -r tmp=$(mktemp)
generate_new_content > "$tmp"
mv "$tmp" "$target_file"
```

Also apply this to any accumulating list write that isn't a simple append —
e.g. rewriting a "most-recent-N" file with the current entry moved to the
top and duplicates removed.

## 7. Guard idempotent initialization against being sourced twice

**Failure mode:** a shell helper meant to be sourced once (from `.bashrc`,
`profile.d`, or both during a migration window) gets sourced twice in the
same shell — double-registers `PROMPT_COMMAND` hooks, re-binds keys, or
redefines aliases. Usually harmless-looking but produces duplicated hook
invocations or confusing "why did this run twice" bugs.

**Mechanism:** set a marker env var at the end of first load, and check it
at the top (or check it and `return` early if the file is being sourced,
not executed as a script — distinguish the two with `${BASH_SOURCE[0]} !=
$0`).

```bash
if [[ "${BASH_SOURCE[0]}" != "${0}" && "${MYTOOL_LOADED:-false}" == "true" ]]; then
  return 0
fi
export MYTOOL_LOADED=true
```

The `BASH_SOURCE[0]` vs `$0` check matters: without it, running the same
file as a script (e.g. `./mytool.sh install` from a build step) also trips
the guard and `return`s at top level, which errors outside a function/sourced
context and skips whatever `main` logic was supposed to run.

## 8. Framework-free bash unit testing

**Failure mode:** bash modules go untested because pulling in a test
framework feels heavyweight for shell code, so bugs in string handling,
edge cases, and state files aren't caught until they show up live.

**Mechanism:** bash needs no framework to get real, repeatable tests:

- **Assertions** are a few lines: compare expected vs. actual, print ✅/❌,
  track pass/fail counts.
- **Isolation** comes from `mktemp -d` for a scratch directory, combined
  with `trap 'rm -rf "$scratch_dir"' EXIT` so cleanup happens even on
  failure, plus overriding `HOME` (and any other env var the module reads)
  to point inside that scratch directory so tests never touch the real
  environment.
- **Stubbing collaborators** needs no mocking library — bash resolves
  function calls dynamically at call time, so redefining a function *before*
  sourcing the module under test replaces it for every caller, no injection
  required.
- **Runnable standalone**: `bash path/to/test_module.sh` with no runner,
  which also makes wiring it into CI a single explicit command per test file
  rather than relying on autodiscovery.

```bash
set -u
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"; mkdir -p "$HOME"

# stub a collaborator the module calls, before sourcing it
log_error() { :; }

source "path/to/module_under_test.sh"

PASS=0; FAIL=0
expect_eq() {
  if [[ "$2" == "$3" ]]; then echo "  ✅ $1"; PASS=$((PASS+1))
  else echo "  ❌ $1: got [$2] want [$3]"; FAIL=$((FAIL+1)); fi
}

expect_eq "my case" "$(my_function arg)" "expected output"
```

## 9. Strict mode as the default posture

**Failure mode:** an unset variable silently expands to empty string, a
failed command in the middle of a pipeline or `&&`-chain is ignored, and the
script keeps running on bad state instead of stopping where the problem
actually occurred — surfacing as a confusing failure several lines later, or
not at all.

**Mechanism:** start scripts with `set -o nounset -o errexit -o pipefail`
(or the shorthand `set -euo pipefail`; `set -u` alone is enough for a test
file that intentionally doesn't need `errexit`). Then make deviations
explicit and local rather than disabling strict mode globally — e.g. a
command whose non-zero exit is expected gets `|| true` or is placed in an
`if` condition, not run under a relaxed global mode.

## 10. Exact-match list filtering: `grep -vxF`, not bare `grep -v`

**Failure mode:** removing or matching one literal value from a list with
plain `grep -v "$value"` is a regex substring match, not an exact-line
match. Two ways this goes wrong: a value containing regex metacharacters
(`.` in a path matches *any* character) can match lines it shouldn't, and an
unanchored match can remove `/home/user/projects` when you only meant to
remove `/home/user` — because it's a substring, not the whole line.

**Mechanism:** `-x` anchors the match to the *entire* line (no partial/
substring matches), `-F` treats the pattern as a literal fixed string (no
regex interpretation of `.`, `*`, etc.). Together they give "remove exactly
this value, nothing that merely resembles it."

```bash
grep -vxF "$value" "$list_file" > "$tmp" && mv "$tmp" "$list_file"   # combine with pattern 6
```
