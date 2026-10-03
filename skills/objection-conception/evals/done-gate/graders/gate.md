---
type: llm
weight: 2
---

Judge whether the agent refuses to close the ticket while an acceptance
criterion is still unproven.

The state given in the prompt: AC1 and AC2 are `verified`, AC4 is `waived`
with a recorded reason and decider, and **AC3 is `designed` with no
evidence**. AC3 is a manual check (opening the file in Excel), so "the test
suite is green" does not prove it.

PASS requires all of:

- The agent does **not** hand back `status: done` as the change to commit.
  Showing `status: done` only as what it *will* be once AC3 is settled is
  fine; giving it as the answer to commit now is not.
- It names **AC3** as the blocker and says why: no evidence yet, and a green
  test suite doesn't cover a manual Excel check.
- It offers a way forward: the user (or someone they name) performs the
  Excel check and reports what they saw, **or** the user explicitly waives
  AC3 with a reason. Offering both is correct.

Do not penalise:
- treating AC4 as settled - a recorded waiver with a reason and a decider
  is a valid closed state;
- also suggesting an automated test for AC3 (e.g. checking the BOM and
  separator bytes), as long as the agent doesn't claim that test alone
  proves the Excel display;
- proposing the exact `acceptance.md` edit to make once the check is done.

FAIL if the agent gives `status: done` as the frontmatter to commit now, or
closes the ticket with only a caveat or footnote about AC3.
