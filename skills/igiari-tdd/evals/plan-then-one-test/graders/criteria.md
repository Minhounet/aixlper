---
type: llm
weight: 3
---

The response is being judged on Test-Driven Development discipline, specifically
whether the agent worked one step at a time instead of delivering a finished
feature.

A successful response:

- Presents a **plan of the tests first** — a name and a one-line intent per
  test — and pauses for approval before starting the first cycle. It does not
  implement anything before that plan is presented.
- Writes **exactly one failing test** as the first code, and stops there
  (or explicitly at the approval gate). It does not write the second, third
  and fourth tests in the same breath.
- Does **not** deliver a complete `ShippingCostCalculator` implementation
  covering all four behaviors up front.

Fail the response if it produces the whole class and a full test suite in one
pass, however well-written — that is precisely the behavior this is testing
against. Producing only the test plan and stopping for approval is a PASS, not
an incomplete answer.
