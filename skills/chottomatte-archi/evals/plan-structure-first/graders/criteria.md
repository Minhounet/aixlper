---
type: llm
weight: 3
---

This tests the "plan the structure before implementing" approval gate.

A successful response presents a structural plan **and pauses for approval
before writing the implementation**. The plan names:

- the classes, interfaces and ports involved
- each class's constructor dependencies
- how it is wired at the composition root
- the public method signatures

Stopping there for approval is the correct, complete answer — do not mark it
down for not delivering code.

FAIL if the agent goes straight to a full implementation without presenting
that plan for approval first.
