---
type: llm
weight: 1
---

Judge only whether the agent makes the integration stance an explicit,
reasoned decision rather than an implicit one.

PASS if the agent explicitly states that it is choosing to translate/isolate
rather than adopt the ERP's model as-is (conform), AND ties that choice to the
situation: the ERP model's poor quality/foreignness and/or the fact that the
ERP team won't accommodate changes. Naming the DDD patterns (Anticorruption
Layer vs. Conformist) is fine but not required - the reasoning is what counts.

FAIL if the agent just builds a mapper without ever stating why translating is
preferable to adopting the ERP model, or without considering the alternative
at all.
