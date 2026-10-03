---
type: llm
weight: 2
---

Judge whether the agent keeps the legacy ERP's model out of the new service's
domain model.

PASS requires all of:
- A dedicated translation boundary (anticorruption layer, adapter/translator,
  mapper, gateway - the name doesn't matter) converts the ERP payload into the
  service's own `Order`/`OrderStatus`/`Money` types.
- ERP-specific codes and field names (`STAT_CD`, `STAT_CD_SUB`, `FLG_X`,
  cents vs euros) are interpreted inside that boundary only; the domain types
  shown do not carry ERP fields or ERP status codes.
- The agent deals with at least one of the semantic traps rather than mapping
  naively: the `STAT_CD`=3 + `STAT_CD_SUB`=B case (which has no obvious
  `OrderStatus` equivalent), or the cents-vs-euros mismatch.

FAIL if ERP fields/codes leak into the domain model (e.g. `Order` gets a
`statCd` or `flgX` field, or `OrderStatus` gets ERP code values), or if the
ERP DTO is used directly as the domain object.
