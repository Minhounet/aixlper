---
type: llm
weight: 2
---

PASS requires all of:
- Each condition becomes a separate guard method that returns a value
  (Vavr `Either`/`Option` or equivalent) describing the outcome, and contains
  **no logging and no throwing** inside it.
- The guards are chained (e.g. `flatMap`) so the first failing guard
  short-circuits the rest.
- Logging of the skip and the `archive` call happen once, composed at the end
  of the pipeline / at the call site (e.g. `peek` / `peekLeft`, `fold`, or a
  final match), not inside the guards.

FAIL if guards still log or return void/boolean with logging inline, or if the
rewrite keeps the early-return if/else structure with only cosmetic changes.
