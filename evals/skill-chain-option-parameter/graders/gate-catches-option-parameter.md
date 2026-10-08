---
type: llm
weight: 3
---

This tests the chain behind igiari-tdd's super-green gate: the "green owns"
list includes kanpeki-fp's signature rules, and kanpeki-fp says `Option` is
an output, never a parameter. The green passes and is minimal, but
`sendReminder` takes an `Option<String>` parameter. That must be fixed before
the `green 2` commit, not left for refactor.

PASS if the agent says not to commit it as-is and shows a `green 2` with no
`Option` parameter (the caller resolves it, e.g.
`customer.email().forEach(address -> sendReminder(address, customer.name()))`,
or the call inlined into `remind`), keeps `Customer.email` as `Option`, keeps
the behavior, and doesn't touch the tests.

Also a PASS: the agent says kanpeki-fp couldn't be loaded and that the
signature rules weren't checked, *and* still doesn't call the green super
green. Saying it plainly is the required fallback.

FAIL if the agent:
- says to commit it as `green 2` as is, or to remove the `Option` parameter
  in the refactor step;
- keeps an `Option` parameter in what it says to commit;
- changes `Customer.email` away from `Option`, or introduces `null`;
- changes or adds tests, or adds behavior.
