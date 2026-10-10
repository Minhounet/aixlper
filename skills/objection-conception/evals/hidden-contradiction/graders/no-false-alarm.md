---
type: llm
weight: 1
---

Judge whether the agent over-flags.

The description says an email is sent "promptly" and AC1 says "within 60
seconds". These are compatible: AC1 only makes "promptly" measurable.
Likewise AC4 does not conflict with anything.

PASS if the agent does not report AC1 versus "promptly", or AC4, as a
contradiction or a blocker. Saying that AC1 usefully makes "promptly"
precise is fine.

FAIL if the agent lists the AC1/"promptly" pair, or AC4, among the
contradictions or blocking problems. This keeps the case from rewarding an
agent that flags everything.
