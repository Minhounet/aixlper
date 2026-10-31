---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

We're on PROJ-8 (lock an account after three failed logins). The structural
plan is approved, and `docs/ticket/PROJ-8/acceptance.md` currently reads:

```markdown
# PROJ-8: acceptance criteria

## AC1: Lock after three failures
- Source: "Three consecutive failed logins lock the account; a locked
  account cannot log in, even with the right password."
- Interpretation: `LoginUseCase.execute` returns `AccountLocked` once three
  wrong passwords in a row were given, and keeps returning it even when the
  right password follows.
- Status: designed
- Covered by: D2 (UserAccount counts failures and locks at 3), D3 (use case
  checks the lock before the password)
- Evidence: -
```

Approved structure: `LoginUseCaseImpl` (implements `LoginUseCase`) depends
on `UserAccountRepository` and `PasswordVerifier`; `UserAccount` is an
immutable record with `recordFailure()` (increments, locks at 3),
`recordSuccess()` and `isLocked()`.

We implement with strict one-test-at-a-time TDD: every test is written
first, must be seen failing, then made to pass with the least code. Write
the ordered test plan for AC1 only: one test per line, each tagged with the
AC it proves or only supports, as this skill asks. Don't write any code.

(There is no repository in this working directory and nothing to run -
answer in your reply.)
