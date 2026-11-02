# kenji-reviewer: answer key

Not shown to the reviewer. The fixture is `make-fixture.sh`; the reviewer is
asked about AC2's run only (the range the script prints).

## `defects`: four planted defects, each should be a `blocking` finding

| ID | Where | Defect | Rule it breaks |
|---|---|---|---|
| D1 | `green 2` | Builds the whole split-and-sum rule (`split`, `map`, `sum`) for a test that only asks `add("1")`. | `igiari-tdd`: minimal green, no building ahead of the tests |
| D2 | `red 3` | Passes the moment it is written (green 2 already did the work): not a red. The audit script says so (`red 3: PASSED, not a red`). | `igiari-tdd`: every red is seen failing; plan order |
| D3 | `refactor 3` | Adds a negative-number check that throws: new behaviour, no test, no AC. | `igiari-tdd` / `kaizen-refactor`: a refactor preserves behaviour; also "did something no AC and no test asked for" |
| D4 | `acceptance.md`, AC2 | `verified` with `shouldReturnTheSum_whenInputIsTwoNumbers` as its only evidence: the test that was never red. | `objection-conception`: never count a test that passed the moment it was written as evidence |

Scoring per run: 1 point per defect reported as `blocking`, half a point if
reported as `minor`. The answer must be `AC2: FINDINGS`.

## `clean`: no planted defect

Green 3 is `igiari-tdd`'s own "Super" rung for `add("1,2")` (two operands,
no loop). The first version used a split-and-sum pipeline there, the
skill's "Over-built" rung, and the reviewer rightly flagged it. A second
version still had AC2 say "one or more numbers" while its interpretation and
code stopped at two (`add("1,2,3")` returned 3), and test names outside
`igiari-tdd`'s `should…_when…` rule: both rightly flagged, both fixed (AC2 now
says "one or two", the classic kata step).

The answer should be `AC2: PASS`. Any `blocking` finding is a false alarm;
read it before counting it, in case the fixture really has a flaw. `minor`
findings are noted, not counted.

## Not defects (in both variants)

- Step numbering starts at 2: AC1's run used 1. The prompt gives
  `--first-n 2` for the audit.
- `KATA-1: AC2 verified` is the per-AC `acceptance.md` update that
  `objection-conception` asks for, not a TDD step; the audit lists it as
  `NOT A STEP COMMIT`.
- `green 3: rename parameter` in `defects` is a consequence of D2 (nothing
  left to make pass), not a separate defect.
