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

## Does `shonin-dev` make less biased greens?

`shonin-dev` writes each green in a fresh context that never sees the test
plan, so it should not build ahead of the tests. The `ahead` count (greens
that generalize before the plan allows, from a kata's `GENERALIZE_FROM`
sidecar) measures exactly that, so the comparison uses the two katas that
have one, both arms through `saiban-orchestrator` in fix mode, differing only
by "no dev":

```
for k in bowling string-calculator; do
  scripts/kata_super_green.sh --kata $k --orchestrator dev   --runs 3 --budget-usd 3 --pmd <pmd> --out /tmp/shonin
  scripts/kata_super_green.sh --kata $k --orchestrator nodev --runs 3 --budget-usd 3 --pmd <pmd> --out /tmp/shonin
done
```

Read first: `subagents` must be above 0 on every dev run (otherwise the dev
never ran and the run says nothing), then compare `ahead`, then `lint` and
cost. Budget: 12 runs, about $0.45 each without the dev and half again with
it, so roughly $7; `--budget-usd 3` caps each run. Then read the histories of
any run whose `ahead` differs, not only the counts.

Untested: whether the audit tolerates the orchestrator's decision-log commit
in the history (the wiring was checked with a fake `claude`, nothing more).

### 2026-11-02, bowling, Sonnet, 1 run per arm

| Arm | Subagents | Greens | Reds that failed | `ahead` | Cost |
|---|---|---|---|---|---|
| `dev` | 5 (one `shonin-dev` per green) | 5 | 5/5 | 0 | $1.22 |
| `nodev` | 0 | 4 | 4/5; test 5 passed on arrival, kept as `guard 5` | 0 | $0.47 |

**Reading the histories, not the counts.** Without the dev, green 2 (test
"all ones → 20") already built the ten-frame walk (`List.range(0, FRAMES)`),
which no test asked for yet; so test 5 (perfect game) passed the moment it
was written and the plan lost a red. With the dev, green 2 only summed pins
and the frame limit arrived at green 5, when test 5 forced it. That is the
bias the dev exists to remove, seen once.

**`ahead` missed it**: bowling's sidecar allows iteration from green 2, so a
loop there is not flagged. On this kata, "a planned test passed on arrival"
(a `guard` or a `PASSED, not a red`) is the better signal.

**Cost: 2.6×** ($1.22 vs $0.47), more than the "half again" measured on a
two-AC build ticket: the dev's own context reloads the skills on every green.

One run per arm proves nothing on its own. Next: 3 runs per arm on bowling
and string-calculator, counting reds that passed on arrival.

The first version of the `subagents` count was wrong: a run started inside a
Claude Code session inherits that session's id, so both runs shared one id
and the no-dev run reported the dev run's 5 agents. The count now reads each
run's own project folder (dev 5, nodev 0, re-checked).

### 2026-11-02, larger pass: bowling and string-calculator, 3 runs per arm, Sonnet

| | `dev` (6 runs) | `nodev` (6 runs) |
|---|---|---|
| Planned tests that passed on arrival | 0 | 0 |
| `ahead` (greens built ahead) | 0 | 0 |
| Refactors flagged "adds generality" | 0 | 1, a false positive: an extraction that moved an existing `take().sum()` into a new method |
| Lint left at HEAD (`MagicNumber`) | 1 run with 1 | 1 run with 5 |
| Subagents per run | 5 every run (one per green) | 0 every run |
| Mean cost | $1.17 | $0.43 |

**No bias difference in this pass.** Without the dev, the orchestrator kept
every green minimal on both katas, all twelve times. With the first pass,
the count is 1 slip in 7 no-dev runs (bowling, green 2 built the frame walk
ahead) against 0 in 7 dev runs: too few to call it a measured effect. The
cost difference is measured: **2.7×** on these katas.

**Why the katas may undersell it.** The dev exists to stop code written for
what the orchestrator knows is coming: the plan, and in build mode the ACs
and the ticket. A five-test kata gives little to know ahead, and the model
knows these katas by heart either way. A multi-AC build-mode ticket is where
the effect, if there is one, should show; no fixture for that exists yet.

### 2026-11-05, one dev per run: bowling and string-calculator, 3 runs, Sonnet, dev arm only

`shonin-dev` now spawned once per TDD run and messaged each next failing
test, instead of spawned per green. Same katas and settings as the larger
pass above; `kata_super_green.sh` now passes "with dev" and allows
`SendMessage`.

| | dev, one per run (6 runs) | dev, one per green (6 runs, above) | nodev (6 runs, above) |
|---|---|---|---|
| Subagents per run | 1 every run | 5 | 0 |
| Planned tests that passed on arrival | 1 (bowling #2) | 0 | 0 |
| `ahead` | 0 | 0 | 0 |
| Lint left at HEAD (`MagicNumber`) | 1 run with 3 | 1 run with 1 | 1 run with 5 |
| Mean cost | $0.80 ($0.73–0.93) | $1.17 | $0.43 |

**Cost: down 31%**, from 2.7× the no-dev arm to 1.9×. The remaining
overhead is the one cold start per run plus the messages to it.

**One slip, the kind the dev exists to prevent.** In bowling #2, green 4
(strike) already capped the game at ten frames (`FRAMES_PER_GAME`), which
only test 5 (perfect game) needs; test 5 passed on arrival and was kept as
`guard 5`. `ahead` missed it, as before (the kata allows loops from green 2).
One run can't say whether the dev's memory of tests 1–4 caused it or the
model knows the kata by heart; the no-dev arm made the same slip once in 7
earlier runs. Count so far, dev per run: 1 in 6.

The audit's "possible super-green misses" on string-calculator (refactor 3,
refactor 4) are the orchestrator extracting `parseOperand` and inlining it
again one refactor later: churn, not a green that left work behind. Every
audit exits 1 on the orchestrator's decision-log commit (`NOT A STEP
COMMIT`), the case flagged untested above; the counts are unaffected.

### 2026-11-05, Opus orchestrator with the dev pinned to Sonnet, 3 runs each

Same katas, `--model opus`; `shonin-dev` now carries `model: sonnet`.
Every dev transcript shows `claude-sonnet-5-5`, every orchestrator
`claude-opus-5-5`: the pin holds in headless runs.

| | Opus orchestrator, Sonnet dev (6 runs) |
|---|---|
| Subagents per run | 1 every run |
| Planned tests that passed on arrival | 0 (every red failed, 30 of 30) |
| `ahead` | 0 |
| Lint left at HEAD | 0 |
| Refactors flagged "adds generality" | 1 (bowling #1, refactor 2: the orchestrator swapped a running total for a stored roll list, room no test had asked for yet) |
| Mean cost | $1.58 ($1.43–1.87) |

**The Sonnet dev held under an Opus planner**: cleanest pass so far. The one
flag is in the orchestrator's own refactor, which knows the plan; the dev
never refactors. Cost has no Opus-dev arm to compare with, so the saving
from the pin is not measured here; the dev's share is billed at Sonnet's
rate instead of Opus's (about half).
