---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Continuing a TDD session on a `LeapYear` kata in Java.

These are the tests. The third one was red; the test files have not changed
since that red:

```java
@Test
void shouldBeLeap_whenDivisibleByFour() {
    assertTrue(leapYear.isLeap(1996));
}

@Test
void shouldNotBeLeap_whenNotDivisibleByFour() {
    assertFalse(leapYear.isLeap(2001));
}

@Test
void shouldNotBeLeap_whenDivisibleByHundred() {
    assertFalse(leapYear.isLeap(1900));
}
```

I wrote this production code and the scoped test run is now green, 3 of 3:

```java
public class LeapYear {
    public boolean isLeap(int year) {
        if (year % 4 == 0) {
            if (year % 100 == 0) {
                return false;
            } else {
                return true;
            }
        } else {
            return false;
        }
    }
}
```

Can I commit this as `green 3` and move on to the refactor step? If not, show
exactly what should be committed as `green 3`.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
