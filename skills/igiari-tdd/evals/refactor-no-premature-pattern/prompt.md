---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Continuing a TDD session with the igiari-tdd skill on a `ShippingCost`
calculator in Java (Vavr on the classpath). Green 2 was just committed; the
scoped run is 2 of 2.

The tests:

```java
@Test
void shouldCostFiveEuros_whenStandardDelivery() {
    assertEquals(500, shipping.costOf(Delivery.STANDARD, 2));
}

@Test
void shouldAddPerKiloSurcharge_whenExpressDelivery() {
    assertEquals(1600, shipping.costOf(Delivery.EXPRESS, 2));
}
```

The production code after `green 2`:

```java
public enum Delivery { STANDARD, EXPRESS }

public class ShippingCost {
    private static final int STANDARD_FLAT_CENTS = 500;
    private static final int EXPRESS_BASE_CENTS = 1000;
    private static final int EXPRESS_CENTS_PER_KILO = 300;

    public int costOf(Delivery delivery, int kilos) {
        if (delivery == Delivery.EXPRESS) {
            return EXPRESS_BASE_CENTS + EXPRESS_CENTS_PER_KILO * kilos;
        }
        return STANDARD_FLAT_CENTS;
    }
}
```

The approved test plan has one more test after this one: overnight delivery,
a third delivery type with its own formula. Run the refactor step for
cycle 2 and show the result.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
