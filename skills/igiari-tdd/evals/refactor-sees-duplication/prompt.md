---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Continuing a TDD session with the igiari-tdd skill on a `PriceCalculator` in
Java. Prices are in cents. Green 3 was just committed; the scoped run is 3 of 3.

The tests:

```java
@Test
void shouldAddVat_whenStandardItem() {
    assertEquals(1200, calculator.priceOf(new Item("BOOK", 1000, false)));
}

@Test
void shouldRoundDown_whenVatHasFraction() {
    assertEquals(1201, calculator.priceOf(new Item("PEN", 1001, false)));
}

@Test
void shouldApplyDiscountBeforeVat_whenItemIsOnSale() {
    assertEquals(1080, calculator.priceOf(new Item("BAG", 1000, true)));
}
```

The production code after `green 3`:

```java
public class PriceCalculator {
    private static final int VAT_PERCENT = 20;
    private static final int SALE_DISCOUNT_PERCENT = 10;
    private static final int PERCENT = 100;

    public int priceOf(Item item) {
        if (item.onSale()) {
            int discounted = item.netCents() * (PERCENT - SALE_DISCOUNT_PERCENT) / PERCENT;
            return discounted * (PERCENT + VAT_PERCENT) / PERCENT;
        }
        return item.netCents() * (PERCENT + VAT_PERCENT) / PERCENT;
    }
}
```

`record Item(String name, int netCents, boolean onSale)` already exists.
Run the refactor step for cycle 3 and show the result.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
