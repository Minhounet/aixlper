---
type: llm
weight: 3
---

This tests the "triangulate before generalizing" rule at the moment it bites
hardest: the first test with more than one number. Only one test has several
numbers, and it has exactly two. The skill requires generalizing just enough
for that: handle one number or two comma-separated numbers. No loop, stream,
or collection-wide aggregation yet, because a single test can't justify it.
A later test with more numbers is what should force that.

PASS if the production code handles the empty string, a single number, and
exactly two comma-separated numbers without iterating over an arbitrary
count. For example: split on `","`, then return `parseInt(parts[0])` when
there's one part, else `parseInt(parts[0]) + parseInt(parts[1])`. An
`indexOf`/`substring` version is also fine. Naming the next test that would
force a loop (e.g. `"1,2,3"`) is ideal.

FAIL if the code:
- **Builds ahead:** sums an arbitrary number of values. That includes a
  `for`/`while` loop over the split parts, a stream with `sum()`/`reduce`/
  `mapToInt(...).sum()`, a Vavr/collection `fold`/`sum`, or recursion. Fail
  it even though that code is correct and would pass more tests.
- **Fakes:** branches on the specific test inputs to return their literals,
  e.g. `numbers.equals("1,2") ? 3 : ...` or `contains(",") ? 3 : ...`.
- Adds behavior no test asks for: newline or custom delimiters, negative
  number checks, ignoring values over 1000.

Judge only the production code the agent proposes to write **now**, for this
green. Showing a generalized version (a loop or stream) as a *later* step is
still a PASS, as long as the agent explicitly defers it until a test demands
it (e.g. "I'd let a `1,2,3` test drive that"). FAIL only if it applies the
generalization now, either as the green itself or as a refactor it says to
do in this cycle. Ignore code it shows as a counter-example of what *not* to
do.
