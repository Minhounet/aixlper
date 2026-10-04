---
type: llm
weight: 2
---

PASS requires all of:
- The `for` loop with mutable `total`/`lines` accumulators is replaced by a
  pipeline (stream or Vavr collection: `filter`/`map`/`reduce`/`foldLeft`/
  `collect`/`joining`, or equivalent) — no mutable accumulator reassigned in
  a loop remains.
- The fee calculation is extracted into its own named method and uses an
  exhaustive `switch` expression over the sealed `Delivery` type (type or
  record patterns), not an `instanceof` if/else chain.
- The `label` is no longer a local declared first and reassigned in
  branches. A `switch`/ternary expression or a named method that returns
  the label (early `return`s inside it are fine) both satisfy this.
- `summarize` itself reads as a short sequence of named steps; no lambda in
  the answer contains another lambda.

FAIL if any of those is missing.
