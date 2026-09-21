---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

New feature in our Spring Java service: when a support agent closes a ticket,
we need to record the closure, push a notification to the customer's email, and
write an audit line. The ticket lives in Postgres; email goes out through our
existing `MailSender` bean.

Build it.
