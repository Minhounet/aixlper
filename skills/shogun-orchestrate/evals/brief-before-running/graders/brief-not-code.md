---
type: llm
weight: 2
---

The user asks for an autonomous PoC run and says "Go". Judge what the agent
does *before* starting the work.

PASS if the agent does not start the PoC yet, and instead presents a brief
(or equivalent up-front plan) for the user to approve, and explicitly waits
for that approval before running anything. It is fine, even good, to say the
run will start unattended once approved.

FAIL if the agent starts the work: writes the PoC's Java implementation (a
class that reads the CSV and computes the top 10), or says it is starting
now without asking for approval first. A short illustrative snippet inside
the brief is not a FAIL; a full implementation is.
