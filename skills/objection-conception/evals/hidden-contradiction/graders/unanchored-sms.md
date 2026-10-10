---
type: llm
weight: 1
---

Judge only how the agent treats acceptance criterion 3 (confirmation SMS).

The description never mentions SMS, and nothing in the ticket says an SMS
channel or a stored phone number exists. The ticket's flow is entirely
email.

PASS if the agent flags AC3 as not backed by the description (a missing
requirement, a possible scope creep, or something that needs a phone number
and an SMS provider) and asks the user or PO to confirm, rather than
designing an SMS step as if it were obviously in scope.

FAIL if the agent adds an SMS step to the design without questioning it, or
does not mention AC3 at all.
