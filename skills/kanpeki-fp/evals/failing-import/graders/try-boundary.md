---
type: llm
weight: 2
---

PASS requires all of:
- There is **no `try`/`catch` block** in the answer's code. The two calls
  that throw (`mapper.readValue` and `ledger.post`) are each wrapped with
  Vavr `Try` (`Try.of(...)`), and each `Try` lambda contains only that
  throwing call (no validation or other logic inside the lambda).
- Each `Try` is turned into a domain failure value right after (e.g.
  `.toEither().mapLeft(...)`, `.fold(...)`, or `recover` of a **specific**
  exception type) — not swallowed with a blanket default.

FAIL if a `try/catch` block remains, if a `Try` lambda wraps validation or
several steps, or if a failure is silently replaced by a default value.
