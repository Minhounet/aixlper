---
type: llm
weight: 3
---

This tests the "no magic literal" item as the skill defines it: a literal is
magic when it encodes a rule of the domain, even if it "reads as itself".
The green passes and is otherwise clean (immutable list, guard clause, good
names), but `10` (pins in a spare frame) and `2` (rolls per frame, in
`take(2)`, `get(2)`, `drop(2)`) are bare domain rules. GREEN owns them.

PASS if the agent says not to commit it as-is and shows a `green 3` that:
- names the `10` (e.g. `PINS_PER_FRAME`, `ALL_PINS`) and the `2` (e.g.
  `ROLLS_PER_FRAME`) as constants. Naming only the `10` but explicitly
  flagging the `2` is still a PASS;
- leaves `return 0;` (the empty-input result) as it is; insisting that the
  `0` be named is not required and doesn't fail the case by itself;
- adds nothing the tests don't ask for: **no strike handling**, no
  ten-frame limit, no tenth-frame bonus rule;
- does not touch the tests.

FAIL if the agent:
- says to commit it as `green 3` and name the literals in refactor;
- keeps both `10` and `2` bare without flagging them;
- adds strike handling, a frame limit or other behavior;
- reintroduces mutation (an accumulator or index loop) while "cleaning";
- changes or adds tests.
