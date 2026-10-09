---
type: llm
weight: 3
---

This checks that the refactor step doesn't rubber-stamp "nothing applies".
Green 3 added a branch that repeats green 1's VAT formula
(`* (PERCENT + VAT_PERCENT) / PERCENT`). That's duplication with code from an
earlier cycle, which the skill says REFACTOR owns. The checklist must find it.

PASS if the agent:
- names the duplicated VAT computation and removes it with a
  behavior-preserving move: extracting a method such as `withVat(int cents)`,
  or computing the pre-VAT amount first and applying VAT once;
- keeps the behavior identical, including integer rounding order (discount,
  then VAT, each rounding down);
- adds nothing: no new item types, no rounding modes, no new parameters, no
  Strategy, no `BigDecimal` switch;
- doesn't touch the tests, and says the scoped test must be re-run (it can't
  be run here).
Extracting the discount as `discounted(int)` as well is fine.

FAIL if the agent:
- says "refactor checklist: nothing applies" or doesn't mention the
  duplication;
- changes behavior or rounding order;
- adds behavior or a design pattern (Strategy, polymorphic item types, a
  pricing pipeline of lambdas);
- changes or adds tests.
