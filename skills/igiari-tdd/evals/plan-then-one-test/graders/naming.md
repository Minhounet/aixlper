---
type: llm
weight: 1
---

Judge only the naming of the test methods that appear anywhere in the response.

PASS if test methods follow a `should<ExpectedResult>_when<Condition>` shape —
for example `shouldChargeFlatFee_whenOrderBelowThreshold`.

FAIL if they use a different convention (`testShippingCost`,
`calculateShippingCost_works`, `givenX_whenY_thenZ`).

If the response deliberately stopped at a test plan and the plan lists test
names in that shape, that counts as a PASS. If no test name appears at all,
score this grader as a FAIL.
