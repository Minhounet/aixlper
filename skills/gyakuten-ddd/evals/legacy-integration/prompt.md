---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Our new order-management service (Java, clean domain model: `Order`,
`OrderLine`, `OrderStatus { PENDING, CONFIRMED, SHIPPED, CANCELLED }`,
`Money`) has to pull orders from the company's 20-year-old ERP. The ERP's REST
endpoint returns this:

```json
{
  "ORD_NO": "0004711",
  "CUST_REF": "K-00912",
  "STAT_CD": "3",
  "STAT_CD_SUB": "B",
  "AMT": "12345",
  "CUR": "EUR",
  "POS": [ { "ART": "A-77", "QTY": "2.000", "PRC": "6172.5" } ],
  "FLG_X": "J"
}
```

`AMT` is in cents, `PRC` is in euros, `STAT_CD` 3 means "shipped" except when
`STAT_CD_SUB` is "B" which means "partially returned", and `FLG_X` = "J" means
the order was migrated from the system before. The ERP team won't change
anything for us - they're busy and report to a different director.

How should I bring these orders into my service? Sketch the design and the
key code.

(There is no repository here and nothing to run - answer in your reply.)
