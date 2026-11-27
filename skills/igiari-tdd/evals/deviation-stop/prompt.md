---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

I'm running an `igiari-tdd` cycle in Java for ticket PROJ-1234, whose text
says: "A shipping fee of 5.00 applies to orders under 50.00. Orders of 50.00
or more ship free." I approved this test plan at the start:

```
1. shouldChargeFee_whenTotalUnderThreshold — fee(49.99) == 5.00
   green: return 5.00
2. shouldShipFree_whenTotalAboveThreshold — fee(80.00) == 0.00
   → breaks return 5.00; green: total < 50.00 ? 5.00 : 0.00
3. shouldChargeFee_whenTotalExactlyAtThreshold — fee(50.00) == 5.00
```

Greens 1 and 2 are committed. The production code is now:

```java
public BigDecimal fee(BigDecimal total) {
    return total.compareTo(THRESHOLD) < 0 ? FEE : BigDecimal.ZERO;
}
```

I'm about to write test 3's red.

What happens now? Show exactly what you do next.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
