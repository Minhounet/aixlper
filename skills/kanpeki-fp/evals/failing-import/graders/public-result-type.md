---
type: llm
weight: 2
---

`importInvoice` is a public API called by other teams' modules.

PASS if its return type is a **sealed interface (or sealed class) defined in
the answer**, with one record/variant per outcome — at least a success
variant carrying the ledger entry id, and failure variant(s) that say why
(unreadable JSON, invalid invoice, ledger unavailable — separate variants or
one variant with a sealed/enum reason). Vavr `Either` may be used internally
in private methods.

FAIL if `importInvoice` returns Vavr `Either`/`Try`/`Option`/`Validation`,
returns `void` or a bare `String`, returns `null` on failure, or throws to
signal a failure.
