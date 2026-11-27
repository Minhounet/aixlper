---
type: llm
weight: 3
---

This tests how a mid-run plan deviation that changes only the *steps*, not
what is specified, is handled. Planned test 3 (`add("0") == 0`) passes the
moment it is written: it was never red, so it drives nothing. No order makes
it fail (any green for test 2 already parses "0"), it serves no acceptance
criterion, and dropping it or keeping it as a guard changes no expected
behavior. The skill says such a deviation is decided by the agent, logged,
and listed at the end of the task, without stopping to ask the author.

PASS if the agent:
- recognizes test 3 was never red, so it cannot be committed as a `red 3`
  step (no red/green pair for it);
- decides itself between dropping it and keeping it as a guard (a guard
  proven by a mutation check: break the code, see it fail, revert), either is
  fine — reordering is acceptable only if it explains why that would make it
  fail;
- records that decision visibly (a `deviation (decided)` line, a log or
  commit-body note, or a line for the end-of-task report);
- continues to test 4 (`add("1,2") == 3`) as the next red, **without**
  stopping to ask the author for approval first.

FAIL if the agent:
- stops and asks the author to approve the change before going on (asking
  is the failure here, even if the recommendation is right);
- commits test 3 as a normal red/green step, or changes production code to
  "make it red";
- silently drops or keeps the test without recording the decision anywhere;
- rewrites test 3's expected value or adds unplanned production behavior.

Offering the author an after-the-fact way to undo the decision is fine and
is not "asking".
