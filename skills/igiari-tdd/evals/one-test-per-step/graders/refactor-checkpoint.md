---
type: llm
weight: 1
---

Judge only whether a **refactor checkpoint** appears in the cycle the agent
describes.

PASS if, after getting test 2 to green, the agent explicitly performs or names
a refactor pass before moving on — reviewing the code just written against a
checklist, or stating that nothing meets the threshold and noting it as a
deferred refinement.

Deciding that no refactoring is warranted **is a pass**, provided the decision
is visibly made rather than skipped. The rule is that the step happens every
cycle, not that code always changes.

FAIL if the cycle goes red → green → straight to the next test with no
refactor step acknowledged at all.
