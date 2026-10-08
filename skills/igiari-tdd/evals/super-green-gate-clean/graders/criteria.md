---
type: llm
weight: 3
---

This is the false-positive check for the super-green gate. The green is
already minimal and clean: guard clause, descriptive names, a named delimiter,
no mutation, nothing untested. The right answer is to commit it as `green 3`
unchanged. The duplicated `Integer.parseInt` across branches is refactor's
make-room work (extracting `parseOperand()`), not something to fix in GREEN.

PASS if the agent says yes, commit it as `green 3` as it is (or with only a
purely cosmetic remark it explicitly says is optional), and leaves any
`parseOperand()` extraction or loop for the refactor step or a later test.

FAIL if the agent:
- says it must not be committed as-is, or rewrites it before committing;
- generalizes it now (a loop, a stream, `sum`, `reduce`, recursion) as the
  green or as a change "before committing";
- adds behavior (other delimiters, negatives, limits) or changes tests.
A refactor-step suggestion such as extracting `parseOperand()` is fine as long
as it is presented as refactor work after the `green 3` commit.
