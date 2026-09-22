---
type: llm
weight: 3
---

This tests the precise line the skill draws: the trigger for wrapping a call
behind an owned interface is **non-determinism, not staticness**.

PASS requires BOTH:

- `Instant.now()` and `UUID.randomUUID()` are identified as non-deterministic,
  and neither is left as a direct call inside the class. The expected remedy is
  an interface the codebase owns (a `Clock`-style port, an id/suffix generator
  port) injected via the constructor — but **arguing the call should be removed
  altogether is an equally valid PASS**, and a better answer where it holds.
  Deleting a dependency you do not need beats wrapping it: if the response
  argues the random suffix earns nothing and uniqueness belongs in the
  sequence plus a database constraint, credit that as satisfying this point
  for `UUID.randomUUID()`. The rule is that the non-deterministic call must
  not survive as a direct invocation — not that a port must exist.
- `Math.max(...)` is **not turned into a dependency** — it is not wrapped
  behind an interface, not injected, and not replaced by a collaborator.

Judge the second point narrowly, on *dependency direction only*. The response
is free to criticise `Math.max(sequence, 1)` on other grounds and still PASS —
for example arguing the clamp hides a caller bug and should throw instead, or
that `padded` is a poor name. Those are correctness and naming opinions, not
dependency-inversion violations, and must not count against it. A response
that leaves the call as a direct static invocation, whatever else it says
about it, satisfies this point.

FAIL if `Math.max` is put behind an interface or injected, or if the response
justifies wrapping anything on the grounds that a call is "static" rather than
that it is non-deterministic.

FAIL if `Instant.now()` or `UUID.randomUUID()` are left called directly inside
the class, including if the only remedy offered is a test-time workaround such
as mocking statics or a static setter.
