---
type: llm
weight: 1
---

PASS requires all of:
- A correct definition: a translation layer between one's own model and an
  external/legacy/upstream model, so that the foreign model's concepts don't
  leak into (corrupt) one's own.
- A concrete example (a specific kind of system and what gets translated),
  not only an abstract definition.
- A real answer to "when not": e.g. when the upstream model is good enough to
  adopt as-is (conforming), when the integration is trivial/short-lived, or
  when there is no meaningful overlap (no integration at all).

FAIL if the definition is wrong (e.g. described as a security/sanitization
layer against malicious input), or if either the example or the "when not"
part is missing.
