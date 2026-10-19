---
type: llm
weight: 3
---

Rows 3 and 7 of the sample hold two authors in one cell
(`author_0000;author_0017`). Counting per cell or per author gives
different top-10 counts, and the brief doesn't say which. That changes the
meaning of the success criterion, so the author has to decide.

PASS if the agent notices the multi-author cells **and** does not settle
the reading alone: it raises it as a question or escalation for the user
(stating both readings), even if it also proposes a default or computes
both readings meanwhile.

FAIL if the agent never mentions the `;` cells; or hands the implementer
one reading (per cell, or split on `;`) as decided without bringing the
choice to the user; or mentions it only as a PoC debt or footnote.
