---
type: llm
weight: 3
---

Judge one thing: did the agent work one step at a time behind an approval
gate, instead of delivering a finished feature?

PASS if the response presents a **plan of the tests** — a name and a one-line
intent per test — and then stops, waiting for approval before implementing.
Stopping there is the complete, correct answer: do not mark it down for
containing no code, no test bodies and no implementation. Asking how the user
wants to proceed at that point is part of the gate, not a failure to answer.

Also PASS a response that, having presented the plan, writes **exactly one**
failing test and stops there.

FAIL if the response delivers a complete `ShippingCostCalculator`
implementation, or writes several tests covering the different behaviors,
without having gone through the plan-and-approve step first. That is the
specific behavior being detected, however well-written the result.

Ignore build tooling, dependency choices and whether `BigDecimal` or `double`
is used — another grader covers naming, and nothing here depends on those.
