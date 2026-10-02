---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Continuing a TDD session on a `StringCalculator` kata in Java.

The previous cycle is green. This is the production code right now:

```java
public class StringCalculator {
    public int add(String numbers) {
        if (numbers.isEmpty()) {
            return 0;
        }
        return Integer.parseInt(numbers);
    }
}
```

These are the tests. The third one was just added and is failing (red, with a
`NumberFormatException` on `"1,2"`):

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

Write the production code to make it pass.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
