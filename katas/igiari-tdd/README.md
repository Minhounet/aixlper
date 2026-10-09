# igiari-tdd katas: measuring super green on real runs

Each `<kata>.md` is an approved test plan. `scripts/kata_super_green.sh`
gives it to a fresh headless `claude` with the Java skills loaded, in a
throwaway Maven project, then runs `audit-tdd-history.sh` with PMD
(`skills/igiari-tdd/scripts/super-green-pmd.xml`) on the resulting history.

The prompt never mentions super green or that the run is measured. The
numbers that matter, per green: issues it introduced, issues its refactor
fixed (super-green misses), issues still there at the end (never fixed).
These files are not eval cases (no `prompt.md`), so `claude plugin eval`
ignores them.

**Building ahead (rule 5).** Cleanliness isn't the whole of super green:
for an AI, the bigger risk is doing more than the tests ask. An optional
`<kata>.audit` sidecar, never shown to the agent, declares
`GENERALIZE_FROM=<N>`, the first green allowed to loop, stream, fold or
recurse. The harness passes it to the audit with
`skills/igiari-tdd/scripts/generalization-pmd.xml`, and any earlier green
that adds such a construct counts as building ahead. Declared for
`string-calculator` (4) and `bowling` (2, weak: it can't tell rolls from
frames). Not declared for `roman-numerals` or `password-validator`: rule 5
doesn't give an unambiguous threshold there, and a guessed one would
measure the guess.

**Refactors that add instead of making room (rule 6).** Every run is also
audited with `skills/igiari-tdd/scripts/iterating-methods-pmd.xml`: a
refactor that raises the number of iterating methods is flagged. A loop
turned into a stream inside the same method keeps the count, so a clarity
refactor doesn't trip it. Re-measured on the existing runs: no refactor
added generality, with or without the skill (one baseline refactor turned a
loop into a stream, correctly not flagged).

## Results so far

Sonnet, 2026-10-08, all runs re-measured with the final rule set
(`UnusedPrivateMethod` counting method references, returned literals exempt).
Issues are counted per green commit; "misses" are the ones the next refactor
fixed, "never fixed" the ones still there at the end.

| Arm | Runs | Issues introduced | Misses | Never fixed | What they are |
|---|---|---|---|---|---|
| Baseline (no skill, same commit format) | 12 | 83 | 2 | 60 | 39 numbers, 29 mutated locals, 12 strings, 3 short names |
| With skill, before the magic-literal definition | 12 | 17 | 2 | 9 | 15 numbers, 2 strings |
| With skill, after it (bowling, Roman numerals only) | 6 | 4 | 0 | 4 | 4 numbers |

Same two katas before the definition: 17 issues over 6 runs, 9 never fixed
(bowling 2/6/1, Roman numerals 1/4/3). After: 4, all `get(1)`/`get(2)`
roll offsets in bowling (bowling 0/2/2, Roman numerals 0/0/0).

Bowling after the offset clause was added to the definition (3 runs): 0/0/2
issues introduced, **0 never fixed**. The 2 were fixed in the next refactor
(misses). Bowling over the three batches: 9 → 4 → 2 introduced, 9 → 4 → 0
never fixed.

Reading and limits: `docs/design-log.md`, "Calibrating Super Green with
katas" and the entries after it. One model, three runs per kata; the
baseline loads no skill at all, so it also lacks `kanpeki-fp`'s style.

Re-run: `scripts/kata_super_green.sh --kata <name> --runs 3 --budget-usd 2
--pmd <pmd> [--baseline]`, then compare the `lint total` lines.

### Building ahead, re-measured on the existing runs

| Kata | With skill | Baseline |
|---|---|---|
| String calculator (loop allowed from green 4) | 0/3 runs build ahead | **2/3**: a `for` loop summing all operands at green 3 (two numbers) |
| Bowling (from green 2) | 0/9 | 0/3 |

Bowling's threshold is too early to discriminate. String calculator is the
one real signal so far, and it matches the `generalize-just-enough` eval
(1.0 with the skill vs 0.0 without).
