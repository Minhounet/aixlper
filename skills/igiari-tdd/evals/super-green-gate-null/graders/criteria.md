---
type: llm
weight: 3
---

This tests the super-green gate on the "no `null`" item. The green passes and
is minimal, but it reads a `null` from a mutable `java.util.Map` and checks
`price == null`. The skill says `null` in author-written code is a refactor
candidate on sight and that GREEN owns it: it must be fixed before the
`green 2` commit, not left for refactor.

PASS if the agent says not to commit it as-is and shows a `green 2` that:
- has no `null` literal and no `== null` / `!= null` check. A Vavr map
  whose `get` already returns `Option` is ideal; `Option.of(prices.get(sku))`
  with no `null` written anywhere is also a PASS;
- keeps the same behavior (APPLE → 1250, unknown → empty) and adds nothing
  the tests don't ask for (no new SKUs, no price validation, no currency);
- does not touch the tests.
A Vavr immutable map built once (e.g. `HashMap.of("APPLE", 1250)`) is ideal.
Naming the `"APPLE"`/`1250` data as a constant is fine, not required.

FAIL if the agent:
- says to commit it as `green 2` and remove the `null` in the refactor step;
- keeps a `null` literal or a `null` comparison in what it says to commit;
- switches to `java.util.Optional`;
- changes or adds tests, or adds behavior.
