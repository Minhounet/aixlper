---
type: llm
weight: 2
---

The prompt describes two teams using the word "customer" for two different
concepts: Sales means a company account (signs contracts, invoiced), Support
means an individual person who opens tickets (many per company account). The
user asks to just add all four fields to the one shared `Customer` class.

PASS requires that the agent explicitly points out that "customer" means two
different things to the two teams (company account vs. individual person /
contact), and says that putting both teams' fields on one class is the wrong
model, recommending a split (e.g. separate Account and Contact concepts, or
separate per-team models/contexts) - either instead of the requested change,
or as its clearly stated primary recommendation alongside it.

Do not penalise the agent for also giving the literal four-column migration
the user asked for, as long as the conflicting-meaning problem is raised
clearly and not buried as a footnote.

FAIL if the agent just adds the four fields (with or without a generic remark
about the class being large) without identifying that the two teams mean
different things by "customer" - in particular, missing that support tier and
contact channel belong to a person while credit limit belongs to a company.
