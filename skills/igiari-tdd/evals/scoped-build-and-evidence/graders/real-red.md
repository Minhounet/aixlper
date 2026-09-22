---
type: llm
weight: 1
---

Judge only the "what counts as evidence of red" half of the answer.

PASS if the agent requires seeing the test actually fail **for the right
reason** — real observed output naming the failing test and its assertion —
and rules out failures that are not a valid red, such as a compile error or a
filter that matched zero tests.

Requiring a non-zero exit status or `BUILD FAILURE` **as one signal among
several is correct and must not be penalised.** Only fail on this point if the
exit status is the agent's *sole* criterion, with no requirement to see which
test failed or why.

FAIL if the response does not address what counts as evidence at all, or would
accept "the build failed" without identifying the failing assertion.
