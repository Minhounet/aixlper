---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Continuing a TDD session on a `StringCalculator` kata in Java.

These are the tests. The third one was red with a `NumberFormatException` on
`"1,2"`; the test files have not changed since that red:

```java
@Test
void shouldReturnZero_whenEmptyString() {
    assertEquals(0, calculator.add(""));
}

@Test
void shouldReturnNumber_whenSingleNumber() {
    assertEquals(5, calculator.add("5"));
}

@Test
void shouldReturnSum_whenTwoCommaSeparatedNumbers() {
    assertEquals(3, calculator.add("1,2"));
}
```

I wrote this production code and the scoped test run is now green, 3 of 3:

```java
public class StringCalculator {
    public int add(String numbers) {
        if (numbers.isEmpty()) {
            return 0;
        } else {
            String[] p = numbers.split(",");
            int r = Integer.parseInt(p[0]);
            if (p.length > 1) {
                r = r + Integer.parseInt(p[1]);
            }
            return r;
        }
    }
}
```

Can I commit this as `green 3` and move on to the refactor step? If not, show
exactly what should be committed as `green 3`.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
