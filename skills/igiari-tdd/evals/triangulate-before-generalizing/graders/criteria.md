---
type: llm
weight: 3
---

This tests the "minimal implementation only — triangulate before generalizing"
rule: on the strength of a single test, an agent must not introduce a loop,
recursion, a lookup table, or any general algorithm. It waits for a second test
that a hardcoded implementation genuinely cannot satisfy.

PASS if the production code returns the constant `"I"` (or equivalent trivially
minimal code) to satisfy the one failing test, and nothing more.

It is still a PASS — indeed the ideal answer — if the agent additionally
*explains* that it is hardcoding deliberately and names the next test that
would force generalization. Proposing the next test in prose is fine.

FAIL if the implementation contains any of: a loop over numeral/value pairs, an
array or map of Roman numeral symbols, recursion, repeated subtraction, or a
general algorithm that would already handle inputs beyond 1. Fail it even
though such code is correct and would pass more tests — solving ahead of the
current test is the specific failure being detected here.
