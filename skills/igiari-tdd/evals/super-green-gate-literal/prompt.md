---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Continuing a TDD session on a bowling `Game` kata in Java (Vavr is on the
classpath). `roll(int pins)` records a roll, `score()` scores the game.

These are the tests. The third one was red; the test files have not changed
since that red:

```java
@Test
void shouldScoreZero_whenAllGutterBalls() {
    rollMany(20, 0);
    assertEquals(0, game.score());
}

@Test
void shouldScoreTwenty_whenAllOnes() {
    rollMany(20, 1);
    assertEquals(20, game.score());
}

@Test
void shouldAddNextRoll_whenSpare() {
    game.roll(5);
    game.roll(5);
    game.roll(3);
    rollMany(17, 0);
    assertEquals(16, game.score());
}
```

I wrote this production code and the scoped test run is now green, 3 of 3:

```java
import io.vavr.collection.List;

public class Game {
    private List<Integer> rolls = List.empty();

    public void roll(int pins) {
        rolls = rolls.append(pins);
    }

    public int score() {
        return scoreFrames(rolls);
    }

    private static int scoreFrames(List<Integer> remaining) {
        if (remaining.isEmpty()) {
            return 0;
        }
        int framePins = remaining.take(2).sum().intValue();
        if (framePins == 10) {
            return framePins + remaining.get(2) + scoreFrames(remaining.drop(2));
        }
        return framePins + scoreFrames(remaining.drop(2));
    }
}
```

Can I commit this as `green 3` and move on to the refactor step? If not, show
exactly what should be committed as `green 3`.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
