---
type: llm
weight: 1
---

Judge only the "what counts as evidence" half of the answer.

PASS if the agent requires seeing the test actually fail for the expected
reason — real observed output naming the failing test and its assertion — and
treats a build that errors for an unrelated reason (a compile error, zero tests
matched) as NOT a valid red.

FAIL if it treats a non-zero exit code alone as proof of red, or does not
address evidence at all.
