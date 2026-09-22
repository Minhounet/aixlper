---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

I'm adding a `ShippingCostCalculator` to our Java service. It needs to:

- charge a flat 5.00 EUR for orders under 50.00 EUR
- charge nothing for orders of 50.00 EUR or more
- charge nothing for orders from a customer with an active premium subscription
- reject a negative order total

Write it for me, test-driven. Show me the code.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
