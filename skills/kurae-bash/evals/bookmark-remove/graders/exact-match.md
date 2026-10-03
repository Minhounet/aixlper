---
type: llm
weight: 2
---

Judge only the filtering bug. `grep -v $dir` is an unanchored regex substring
match: removing `/home/me/proj` also removes `/home/me/proj-old` and
`/home/me/proj/sub`, and a `.` in a path matches any character.

PASS if the agent identifies that the match is a substring/regex match that
can remove other bookmarks (not just the exact path), and fixes it with an
exact, literal whole-line match - `grep -vxF` (or `-Fx`, `--line-regexp
--fixed-strings`), or an equivalent exact comparison such as an awk/while
loop comparing whole lines with `!=`.

FAIL if the agent only adds quoting (`"$dir"`) and/or `--` without making the
match exact and literal, or does not mention the substring/regex problem.
