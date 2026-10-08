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

First calibration, 2026-10-08, Sonnet, 3 runs per kata and arm (string
calculator: 3 with the skill, 3 baseline). PMD rules as committed after the
"returned literal" fix. Totals over 12 runs per arm:

| | With skill | Baseline (no skill, same commit format) |
|---|---|---|
| Issues introduced by greens | 18 | 83 |
| Fixed by the next refactor (super-green misses) | 5 | 2 |
| Still there at the end (never fixed) | 8 | 48 |
| Mutated locals / accumulators | 0 | 26 |
| Cost per run | ~$0.44 | ~$0.14 |

Almost every issue left with the skill is a number (`take(2)`, `== 4`).
See `docs/design-log.md` ("Calibrating Super Green with katas") for the
reading of these numbers and their limits.

Re-run: `scripts/kata_super_green.sh --kata <name> --runs 3 --budget-usd 2
--pmd <pmd> [--baseline]`, then compare the `lint total` lines.
