---
type: llm
weight: 3
---

This tests the precise line the skill draws: the trigger for wrapping a call
behind an owned interface is **non-determinism, not staticness**.

PASS requires BOTH:

- `Instant.now()` and `UUID.randomUUID()` are identified as non-deterministic
  and moved behind interfaces the codebase owns (a `Clock`-style port and an
  id/suffix generator port), injected via the constructor.
- `Math.max(...)` is **left alone** — it is a pure static call, deterministic,
  and needs no wrapping.

FAIL if the response wraps `Math.max` behind an interface, or justifies
wrapping on the grounds that a call is "static" rather than that it is
non-deterministic.

FAIL if it leaves `Instant.now()` or `UUID.randomUUID()` called directly inside
the class, including if it only suggests a test-time workaround such as mocking
statics or a static setter.
