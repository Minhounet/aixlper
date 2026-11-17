---
type: llm
weight: 2
---

Judge only what the answer says about PROJ-1's checks after the rebase.

Background: AC1 and AC2 of PROJ-1 passed yesterday against PROJ-1 alone.
After the rebase PROJ-1's code runs on top of PROJ-2's, so those results no
longer count: the build and unit tests run again, PROJ-1 is redeployed, and
AC1 and AC2 are checked again on the server.

PASS if the answer says AC1 and AC2 (or PROJ-1's server checks) must be run
again on the rebased, redeployed code, not only the build or unit tests.

FAIL if it only rebuilds or reruns unit tests, treats yesterday's checks as
still valid, or does not mention checking PROJ-1 again on the server.
