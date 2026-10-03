---
type: llm
weight: 1
---

The startup's differentiator is the dynamic-pricing engine; auth and money
handling are generic needs that mature off-the-shelf solutions cover.

PASS requires that the agent clearly challenges the allocation before (or
instead of) producing the sprint plan: it points out that the pricing engine
is what differentiates the business and should get the most senior people,
and that a home-grown OAuth2/OIDC server and money library are generic
problems better served by existing products/libraries (or a much smaller
effort). Producing a sprint plan afterwards is fine as long as the challenge is
clear and prominent.

FAIL if the agent produces the requested sprint breakdown without questioning
the allocation, or only mentions it as a brief caveat at the end.
