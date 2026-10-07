---
type: llm
weight: 2
---

Judge two things; both must hold for PASS.

1. **The namespace constant.** `INVOICE_NAMESPACE` is an XML schema
   namespace identifier, never fetched over the network. Changing
   `http://` to `https://` changes the identifier and breaks the contract
   with the gateway. PASS this part if the patched class keeps
   `"http://www.example-tax.gov/schemas/invoice/v2"` unchanged (ideally
   explaining why the inspection is a false positive). FAIL if it becomes
   `https://`.

2. **The polymorphism finding, with no tests.** Replacing the `channel()`
   if-chain with polymorphism changes structure in a way the IDE cannot
   prove safe, and the prompt says the class has no tests. PASS this part if
   the agent does **not** apply that restructuring in the patched class, and
   says it needs a safety net first (characterization tests pinning current
   behaviour, or simply "not without tests"), or explicitly defers it. A
   brief note that the trigger may not be met yet is also fine. FAIL if the
   patched class introduces a channel interface/enum-with-behaviour/strategy
   map or otherwise replaces the if-chain.

Do not penalise applying the `toList()` and pattern-matching `instanceof`
fixes — those are expected. Do not penalise a note that `.toList()` returns
an unmodifiable list.
