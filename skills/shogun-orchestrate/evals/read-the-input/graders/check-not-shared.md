---
type: llm
weight: 1
---

PASS if the agent says the independent check must not just repeat the
implementation's reading of the author column (e.g. it covers both readings
of `a;b` cells, or is written from the question rather than from the code),
or otherwise makes the check exercise the multi-author cells.

FAIL if the agent's cross-check would count whole cells the same way the
implementation does without remarking on it (e.g. a plain
`cut -d, -f3 | sort | uniq -c` presented as sufficient), or proposes no
cross-check at all.
