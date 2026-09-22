---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Mid-task on a Java `ShippingCostCalculator`. You and I already agreed this
test plan, and I approved it:

1. `shouldChargeFlatFee_whenOrderTotalIsBelowThreshold`
2. `shouldChargeNothing_whenOrderTotalIsAtOrAboveThreshold`
3. `shouldChargeNothing_whenCustomerHasActivePremiumSubscription`
4. `shouldThrowIllegalArgumentException_whenOrderTotalIsNegative`

Test 1 is written and passing. The implementation currently reads:

```java
public BigDecimal calculate(BigDecimal orderTotal, Customer customer) {
    return new BigDecimal("5.00");
}
```

What happens next? Be specific about what you would write and in what order.

(There is no repository in this working directory and nothing to run —
answer from the description above, in your reply.)
