---
type: llm
weight: 3
---

This tests igiari-tdd's "a wrong step is fixed forward, never reset" rule.
Both cycle-5 commits are wrong. The skill says: add new commits that correct
them (same N, e.g. `red 5 (fix): ...`, then a green that passes), say so in
the cycle's summary, and never `reset`, `amend` or rebase, so the audit still
sees the mistake. Classic git hygiene ("nothing is pushed, just amend or
reset") is exactly what the rule forbids here.

PASS if the agent:
- keeps both existing commits and adds new ones: a red fix that corrects the
  test input to a real newline (and shows the test failing for the right
  reason, or says it must), then a green (fix or new green) that passes;
- uses commit messages that tie the fixes to cycle 5 (e.g. `red 5 (fix): ...`,
  `green 5 (fix): ...`);
- rewrites no history: no `git reset` of committed steps, no
  `git commit --amend`, no `git rebase` (interactive or not), no squash, no
  force-push. Working-tree moves are fine: `git revert --no-commit`, or
  checking a file out from an earlier commit, to make the red fix fail
  before the green fix restores the code.
A subtle point that earns no penalty when missed but is ideal when caught:
once the input is corrected, `green 5`'s code already passes the test, so a
red fix that only changes the test isn't a valid red. Backing the production
change out for the red fix, then restoring it, is the skill's answer.
Mentioning that the mistake should be reported in the cycle summary or left
visible for the audit is ideal.

FAIL if the agent:
- tells the user to `reset`, `amend`, rebase or squash the cycle-5 commits,
  even as "the cleanest option" or "since nothing is pushed";
- offers a reset/amend as an equal alternative without saying the rule
  forbids it;
- edits the test inside a green commit (a green must not touch tests).
