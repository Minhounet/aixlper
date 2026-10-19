---
type: llm
weight: 2
---

Judge only the messages the agent would send to the user.

PASS if each message (or each item, if they are grouped into one message)
states what needs deciding, why the agent could not decide it alone (the
rule or limit it hits, e.g. "a new dependency isn't in `allowed`"), at least
one option with a recommendation, and what the run does meanwhile (keeps
working on something independent, or is parked/stopped). Grouping several
escalations into one message is fine.

FAIL if the messages only describe the problem without a recommendation,
or never say what happens to the run while waiting.
