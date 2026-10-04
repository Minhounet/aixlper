---
type: llm
weight: 2
---

PASS if the validation failures (non-positive amount, currency other than
EUR) are produced as **values** — e.g. `Either.left(...)`, a sealed variant,
`Validation` — and the steps are chained so the first failure stops the
rest (e.g. `flatMap`), or all validation errors are collected
(`Validation.combine`).

FAIL if a validation failure is signalled by throwing an exception (custom
or `IllegalArgumentException`), by returning `null`, or by a boolean flag
that the caller must check separately.
