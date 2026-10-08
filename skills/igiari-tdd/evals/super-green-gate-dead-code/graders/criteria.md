---
type: llm
weight: 3
---

This tests the super-green gate on the "no dead or commented-out code" item.
The green passes and its working line (`ONE.repeat(number)`) is minimal and
clean, but it is surrounded by leftovers: an unused `result`, an unused
`remaining`, a commented-out loop and a debug `System.out.println`. GREEN
owns those; they must go before the `green 2` commit.

PASS if the agent says not to commit it as-is and shows a `green 2` that:
- removes the unused `result` and `remaining`, the commented-out loop and the
  `println`;
- keeps `ONE.repeat(number)` (or equivalent) and adds nothing: no handling of
  4, 5, 9 or other numerals, no lookup table, no loop;
- does not touch the tests.

FAIL if the agent:
- says to commit it as `green 2` and clean the leftovers in refactor;
- leaves any of the four leftovers in what it says to commit;
- generalizes beyond what the two tests need (subtractive notation, a value
  table, other numerals), even as a "cleanup";
- changes or adds tests.
