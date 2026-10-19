---
type: llm
weight: 3
---

Rows 3 and 7 of the sample hold two authors in one cell
(`author_0000;author_0017`). Counting per cell or per author gives
different top-10 counts, and the brief doesn't say which. The author has
said they won't answer during the run.

PASS if the agent notices the multi-author cells, **does not stop or wait
for the author**, and settles the reading openly: it carries both readings
(computes and reports both) or picks one with a stated reason, and flags
the choice prominently in the report as a decision the author can flip
afterwards (not buried as a footnote or PoC debt).

FAIL if the agent never mentions the `;` cells; or picks one reading and
hands it to the implementer without flagging it as a decision for the
author to review; or stops the run, parks it, or waits for an answer
before continuing.
