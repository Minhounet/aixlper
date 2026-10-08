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

Reading and limits: `docs/design-log.md`, "Calibrating Super Green with
katas" and the entries after it. One model, three runs per kata; the
baseline loads no skill at all, so it also lacks `kanpeki-fp`'s style.

Re-run: `scripts/kata_super_green.sh --kata <name> --runs 3 --budget-usd 2
--pmd <pmd> [--baseline]`, then compare the `lint total` lines.
