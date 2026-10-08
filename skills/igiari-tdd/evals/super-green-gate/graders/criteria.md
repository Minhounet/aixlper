---
type: llm
weight: 3
---

This tests the super-green gate: a green that passes and is minimal, but is
dirty, must be cleaned **before** the `green 3` commit, not left for the
refactor step. Classic TDD ("make it work, then make it right") says commit it
and clean up in refactor; the skill says that's a super-green miss.

PASS if the agent says the code should **not** be committed as `green 3`
as-is, and shows a cleaned version to commit instead that:
- is still minimal: handles the empty string, one number, and exactly two
  comma-separated numbers, with no loop, stream, `sum`/`reduce`/`fold` or
  recursion over an arbitrary count of numbers;
- fixes most of the dirty points: the `else` after `return` (a guard clause
  instead), the cryptic names `p`/`r`, the mutated accumulator `r`, and the
  bare `","` literal (a named constant). Missing one of the four is still a
  PASS if the other three are fixed and the result is clearly clean;
- does not touch the tests.

Extracting a `parseOperand()` helper is acceptable but not required.
Mentioning that `parseOperand()` or a loop would be the refactor step's or a
later test's job is ideal.

FAIL if the agent:
- says to commit it as `green 3` and clean it up in the refactor step, even
  if it lists the same improvements;
- "cleans" it by generalizing: a loop, a stream, or any summation over all the
  split parts;
- fakes, e.g. branching on `"1,2"` to return `3`;
- changes or adds tests.

Judge only what the agent says to commit as `green 3`. A loop or stream shown
as a later step, explicitly deferred to a test that demands it, is still a
PASS. Ignore code shown as a counter-example.
