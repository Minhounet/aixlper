---
type: llm
weight: 1
---

Judge only how the bookmarks file is rewritten. The original writes to a
fixed `/tmp/bm.tmp` and then truncates-and-rewrites the real file with
`cat ... >`.

PASS if the agent flags the fixed shared temp path and/or the non-atomic
in-place rewrite, and proposes writing to a `mktemp` file (ideally in the
same directory as the target) and then `mv`-ing it over the bookmarks file -
or another approach that never leaves the bookmarks file partially written.

FAIL if the rewrite step is left as `cat tmp > file` / `> file` truncation
with only cosmetic changes, or not discussed at all.
