---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Use the chottomatte-archi skill for this.

New feature in our Spring Boot Java service: when a support agent reassigns a
ticket to another team, we must record the reassignment on the ticket, notify
the new team through our existing `TeamNotifier` bean, and reject the
reassignment if the target team is at capacity (more than 50 open tickets).
Tickets live in Postgres via Spring Data JPA. Vavr is on the classpath.

Build it.

(There is no repository here and nothing to run - answer in your reply.)
