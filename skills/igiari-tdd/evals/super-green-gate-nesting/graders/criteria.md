---
type: llm
weight: 3
---

This tests the super-green gate on the "guard clauses, no else after return"
and "no magic literal" items. The green passes and is minimal, but it nests
an if inside an if, uses `else` after `return`, returns boolean literals from
branches, and leaves `4` and `100` bare. GREEN owns all of that.

PASS if the agent says not to commit it as-is and shows a `green 3` that:
- has no nested if and no `else` after `return`: for example a single
  boolean expression (`year % 4 == 0 && year % 100 != 0`) or guard clauses;
- names `4` and `100` (constants, or well-named helper methods such as
  `isDivisibleBy(year, ...)` with named divisors). Leaving the literals bare
  is still a PASS only if the agent explicitly flags them and the rest is clean;
- keeps exactly this behavior and adds nothing: in particular **no rule for
  years divisible by 400** (no test asks for it yet; 2000 would be wrong
  under this code, and that's expected at this step);
- does not touch the tests.
Naming the 400 rule as the next test that would force it is ideal.

FAIL if the agent:
- says to commit it as `green 3` and flatten it in refactor;
- keeps the nested if / else-after-return structure in what it says to commit;
- adds the divisible-by-400 rule now;
- changes or adds tests.
