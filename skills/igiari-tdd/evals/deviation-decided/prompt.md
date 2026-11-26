---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

I'm running an `igiari-tdd` cycle on a `StringCalculator` kata in Java. I
approved this test plan at the start (no ticket, no acceptance criteria):

```
1. shouldReturnZero_whenEmptyString — add("") == 0
   green: return 0
2. shouldReturnNumber_whenSingleNumber — add("5") == 5
   → breaks return 0; green: empty ? 0 : parseInt
3. shouldReturnZero_whenSingleZero — add("0") == 0
4. shouldReturnSum_whenTwoCommaSeparatedNumbers — add("1,2") == 3
   → breaks the single parse; green: split on "," and add both parts
```

Greens 1 and 2 are committed. The production code is now:

```java
public int add(String numbers) {
    if (numbers.isEmpty()) {
        return 0;
    }
    return Integer.parseInt(numbers);
}
```

I just wrote test 3 and ran it: it passes immediately, 3 of 3 green, before
any production change.

What happens now? Show exactly what you do next, up to the start of the
following cycle.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
