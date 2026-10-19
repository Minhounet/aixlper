---
type: llm
weight: 2
---

Judge only what the agent says it would put in the report for the
non-trivial events (2, 3, 4, 6, 7).

PASS if, for these events, the report entries state what was decided, why
it was not a trivial call, which option was taken, and how the author could
flip it afterwards (a commit to revert, or the one change to make), for at
least four of the five. A grouped table is fine.

FAIL if the decisions are only described without saying how to undo or
flip them, or if the non-trivial decisions are not distinguished from the
trivial ones.
