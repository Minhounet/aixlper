# Everyday shell hygiene

Read this when reviewing or writing a bash script that rewrites a state file
in place, removes or matches one value in a list file, or runs without strict
mode. These rules were patterns 6, 9 and 10 of `kurae-bash` until 2026-10-03.
They moved here because a model applies them without the skill, so they
weren't worth loading on every trigger.

## Atomic writes: write to a temp file, then `mv` over the target

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

## Strict mode as the default posture

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

## Exact-match list filtering: `grep -vxF`, not bare `grep -v`

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
grep -vxF "$value" "$list_file" > "$tmp" && mv "$tmp" "$list_file"   # combine with the atomic write above
```
