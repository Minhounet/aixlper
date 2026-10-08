Implement a bowling `Game` class in package `com.example` with
`void roll(int pins)` and `int score()`, for one complete game of ten frames.

Planned tests — Game.score:
1. shouldScoreZero_whenAllGutterBalls — 20 rolls of 0 → 0
2. shouldScoreTwenty_whenAllOnes — 20 rolls of 1 → 20
3. shouldAddNextRoll_whenSpare — 5, 5, 3, then 17 rolls of 0 → 16
4. shouldAddNextTwoRolls_whenStrike — 10, 3, 4, then 16 rolls of 0 → 24
5. shouldScore300_whenPerfectGame — 12 rolls of 10 → 300
