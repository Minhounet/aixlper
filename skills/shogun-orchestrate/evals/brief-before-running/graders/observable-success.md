---
type: llm
weight: 2
---

Judge the success criterion the agent proposes for the PoC.

PASS if the agent proposes a success check that can be verified by running
something: a concrete command (or test) and the observable result that
proves success, with the 1-second threshold made measurable (what is timed,
on what input, e.g. a generated 100k-line file, JVM warm-up or not). It must
also raise at least one point it cannot decide alone, such as the real CSV's
format or columns, where the file lives, or how authors are spelled.

FAIL if the success criterion is vague ("it works", "it's fast enough") or
absent, or if the agent silently assumes the CSV format without flagging it.
