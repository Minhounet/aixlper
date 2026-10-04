---
type: llm
weight: 2
---

The public method `summarize(List<Invoice>, String)` is called directly by a
test and by other modules, so it is an interface.

PASS if the refactored `summarize` keeps exactly the same name, parameter
types and `String` return type. Changing the **private** helper
`findCustomer` (e.g. to return `Option<Customer>` or `Optional<Customer>`, or
removing it) is allowed and does not affect this grade. A response that
keeps the signature but *proposes* a different public return type as a
separate, clearly-labelled suggestion needing approval also PASSES.

FAIL if the delivered code changes the public method's return type (e.g. to
`Either`, `Option`, a record) or its parameters, or renames it.
