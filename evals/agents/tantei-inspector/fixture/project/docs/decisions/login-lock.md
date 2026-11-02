## Resume
- Mode: fix
- Done: the fix
- Next: none
- Files: LoginService, LoginServiceTest

## fix - lock after three failures
- Decided: count failures per user in `LoginService`
- Why: the bug report
- Rejected: a separate `LockPolicy` class (fix mode adds no structure)
- Asked user: no

## fix - GREEN by shonin-dev
- Decided: spawned shonin-dev for green 2 with the failing test, the test command, LoginService.java and the ticket's ACs for context
- Why: it needed to know what "locked" means
- Rejected: -
- Asked user: no
