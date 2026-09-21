---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Review this Java class from our codebase and tell me what you'd change:

```java
public class InvoiceNumberPolicy {

    public String nextNumber(String customerCode, int sequence) {
        String year = String.valueOf(Instant.now().atZone(ZoneId.of("Europe/Paris")).getYear());
        String suffix = UUID.randomUUID().toString().substring(0, 4);
        int padded = Math.max(sequence, 1);
        return "%s-%s-%05d-%s".formatted(customerCode, year, padded, suffix);
    }
}
```
