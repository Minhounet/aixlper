---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Continuing a TDD session on a `RomanNumeral` converter in Java.

This test is currently failing (red), and it is the only test that exists:

```java
@Test
void shouldReturnI_whenOne() {
    assertThat(RomanNumeral.of(1)).isEqualTo("I");
}
```

Write the production code to make it pass.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
