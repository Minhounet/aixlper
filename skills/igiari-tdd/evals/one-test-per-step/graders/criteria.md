---
type: llm
weight: 3
---

Judge whether the agent advances **one cycle at a time** and refuses to build
ahead of the test that forces the code.

PASS requires all of:

- The next red it writes covers **one behavior**, and it does not implement
  behaviors that no written test yet forces — premium customers and negative
  totals (tests 3 and 4) are not implemented in this step.
- It treats the hardcoded `return new BigDecimal("5.00")` as correct-so-far
  rather than a bug to fix pre-emptively. Generalisation is what the next test
  is for.
- The implementation it proposes is the **minimal** thing satisfying the tests
  written so far, not a finished calculator.

**Splitting the planned test 2 into two smaller sequential cycles is a PASS,
and is the better answer.** `shouldChargeNothing_whenOrderTotalIsAtOrAbove
Threshold` names two behaviors — the boundary and above it — and one test
cannot force the general comparison without anticipating it. An agent that
splits it, runs the cycles in order, and flags the split as a deviation from
the approved plan is applying the rule more carefully, not breaking it. Do not
read "two cycles" as "writes several tests at once": what matters is whether
work is done **ahead of a failing test**, not how many cycles the remaining
plan is divided into.

Asking for a missing detail, such as the threshold value, is also fine.

FAIL if the response implements tests 3 and 4's behaviors in this step, or
delivers a complete implementation covering all four, however correct the
resulting code would be.

Ignore whether the agent mentions running a build; another case covers that.
