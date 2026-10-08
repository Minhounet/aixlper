---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Continuing a TDD session in Java (Vavr is on the classpath). A `PriceCatalog`
returns the price of a product by SKU.

These are the tests. The second one was red; the test files have not changed
since that red:

```java
@Test
void shouldReturnPrice_whenSkuIsKnown() {
    assertEquals(Option.of(1250), catalog.priceOf("APPLE"));
}

@Test
void shouldReturnNothing_whenSkuIsUnknown() {
    assertTrue(catalog.priceOf("PEAR").isEmpty());
}
```

I wrote this production code and the scoped test run is now green, 2 of 2:

```java
public class PriceCatalog {
    private final java.util.Map<String, Integer> prices = new java.util.HashMap<>();

    public PriceCatalog() {
        prices.put("APPLE", 1250);
    }

    public Option<Integer> priceOf(String sku) {
        Integer price = prices.get(sku);
        if (price == null) {
            return Option.none();
        }
        return Option.of(price);
    }
}
```

Can I commit this as `green 2` and move on to the refactor step? If not, show
exactly what should be committed as `green 2`.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
