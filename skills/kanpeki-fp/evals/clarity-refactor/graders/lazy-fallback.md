---
type: llm
weight: 2
---

In the original, `customers.loadDefaultCustomer()` (a remote call) only runs
when no customer is found.

PASS if the refactored code still calls `loadDefaultCustomer()` only when the
customer is absent — e.g. `getOrElse(() -> customers.loadDefaultCustomer())`,
`getOrElse(customers::loadDefaultCustomer)`, `orElseGet(...)`, or an explicit
branch.

FAIL if the fallback is passed eagerly as a value, so it runs every time —
e.g. `getOrElse(customers.loadDefaultCustomer())` or
`orElse(customers.loadDefaultCustomer())`.
