---
type: llm
weight: 2
---

Judge where the plan puts the test that proves AC1 at the level of its
interpretation: a test that calls `LoginUseCase.execute` (or
`LoginUseCaseImpl`) with three wrong passwords and then checks the result,
including the right password returning `AccountLocked`.

Under strict TDD every test must fail when it is written. If the plan first
unit-tests `UserAccount.recordFailure()` locking at 3 and the use case
checking `isLocked()`, a use-case-level AC1 test added **after** them would
already pass when written: it can never be seen red, so it cannot count as
evidence.

PASS requires all of:

- The plan contains at least one test tagged as proving AC1 (`[AC1]` or
  equivalent) that exercises the use case, not only `UserAccount`.
- That test is placed where it will fail when written: before the tests
  that would force all of its behavior (typically first in the plan, or
  early enough that the lock behavior is still missing). Alternatively, the
  plan explicitly notes the problem and resolves it (for example by flagging
  that a late use-case test would pass on arrival and moving it earlier).

FAIL if the only use-case-level AC1 test comes last, after unit tests that
already force the lock and the lock check, with no remark that it would pass
immediately; or if no test proves AC1 at use-case level and this is not
flagged.
