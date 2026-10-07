---
type: llm
weight: 1
---

Judge whether the test class is written against the current public
behaviour only.

PASS if the tests call only `new ShippingCost().compute(...)` (or an
equivalent instance) and assert on its result or thrown exception.

FAIL if any test references a type or method that does not exist yet and
belongs to the planned refactor (e.g. a `WeightBand`, a rule object, an
extracted `baseFor(...)`/`surcharge(...)` method), or asserts on the
internal structure the refactor is meant to introduce.
