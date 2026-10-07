---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

The inspection flags `ShippingCost.compute` as too complex ("Overly complex
method", cognitive complexity 19). I want to split it up — extract the
weight band and the surcharge rules into their own methods, maybe a small
rule object per band. There are no tests on this class.

Before touching it, write the JUnit 5 characterization tests that should
guard the refactor. Show me the test class; we'll do the refactor after.

```java
package com.example.shop;

import java.math.BigDecimal;
import java.math.RoundingMode;

public class ShippingCost {

    public BigDecimal compute(int weightGrams, String country, boolean express) {
        BigDecimal base;
        if (weightGrams <= 500) {
            base = new BigDecimal("4.90");
        } else if (weightGrams < 2000) {
            base = new BigDecimal("7.90");
        } else if (weightGrams <= 10000) {
            base = new BigDecimal("12.90");
        } else {
            base = new BigDecimal("12.90")
                    .add(new BigDecimal("1.00").multiply(BigDecimal.valueOf((weightGrams - 10000) / 1000)));
        }
        if (!country.equals("FR")) {
            base = base.multiply(new BigDecimal("1.5"));
        }
        if (express) {
            base = base.add(new BigDecimal("5"));
            if (!country.equals("FR")) {
                base = base.add(new BigDecimal("5"));
            }
        }
        return base.setScale(2, RoundingMode.HALF_UP);
    }
}
```

(There is no repository in this working directory and nothing to run —
answer from the description above, in your reply.)
