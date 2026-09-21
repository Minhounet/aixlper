---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Quick design question on our Java service.

A `CustomerRepository` interface currently has this method, because the only
caller just needs to show the name on a receipt:

```java
String findCustomerNameById(String customerId);
```

Now a second use case needs the customer's loyalty tier and signup date too.
What should the repository look like, and what should the use case hand back to
its caller?
