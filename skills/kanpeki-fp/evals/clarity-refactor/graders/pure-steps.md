---
type: llm
weight: 2
---

PASS requires both:
- The per-invoice steps of the pipeline (the filter predicate and the
  method that maps an invoice to its line/amount) are pure: they contain
  **no logging**. The "counted invoice" debug log is done separately, after
  or around the pipeline (e.g. a `forEach`/`peek` at the end of the chain in
  `summarize`, or over the resulting list) — never inside the mapping or
  filter method.
- The fee `switch` over `Delivery` binds record components with record
  deconstruction patterns, e.g. `case Delivery.Express(BigDecimal weight,
  int hours) ->`, not type patterns followed by accessor calls
  (`case Delivery.Express e -> e.weight()`).

FAIL if a mapping/filter method logs, or if the switch uses type patterns
with accessor calls.
