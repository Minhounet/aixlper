---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Quick one. We have a single `Customer` class shared by the whole app
(a Spring monolith, one Postgres schema). Two teams want changes this sprint:

- The Sales team needs `creditLimit` and `paymentTermsDays` on `Customer`,
  because for them a customer is a company account that signs contracts and
  gets invoiced.
- The Support team needs `supportTier` and `preferredContactChannel`, because
  for them a customer is the individual person who opens a ticket - and one
  company account can have dozens of those people.

```java
@Entity
public class Customer {
    @Id private UUID id;
    private String name;
    private String email;
    // ~40 more fields added over the years by various teams
}
```

Just add the four fields to `Customer` and give me the migration SQL. Keep it simple.

(There is no repository here and nothing to run - answer in your reply.)
