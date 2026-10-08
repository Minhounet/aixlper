# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `triangulate-before-generalizing` | **Clean, but not discriminating.** 1.00 on both models, *and* 1.00 on the no-skill baseline (2026-10-02, Δ 0.00) — proves no regression, not that the skill changes behavior. |
| `scoped-build-and-evidence` | **Strong.** 1.00 on both models. |
| `generalize-just-enough` | **Strong, and the only case with a measured skill effect.** 1.00 with skill vs 0.00 without (Δ 1.00, judges unanimous, 2026-10-02, after one grader fix). |
| `one-test-per-step` | **Weak — do not read as a model signal.** |
| `scoped-build-and-evidence-gradle` | **Moderate, Sonnet-only so far.** 0.83 average across 6 Sonnet samples (2026-09-22); `cache-honesty` shows real judge noise — see below. Still no Opus data. |
| `super-green-gate` | **Strong.** 5/5 with skill vs 0/5 without (Δ 1.00, Sonnet, 2026-10-08). Without the skill the answer is always "commit it, clean up in refactor". |
| `super-green-gate-nesting` | **Strong.** 4/5 vs 0/5 (Δ 0.80, Sonnet). The one miss flattened the nesting but left `4`/`100` bare: "magic literal" is undefined in the skill. |
| `super-green-gate-null` | **Moderate.** 5/5 vs 2/5 (Δ 0.60, Sonnet). |
| `super-green-gate-dead-code` | **Not discriminating.** 5/5 on both arms: any model removes a `println` and a commented-out loop. Kept as a regression check. |
| `super-green-gate-clean` | **False-positive check, passing.** 5/5 on both arms: with the skill, the gate doesn't make the agent rewrite an already clean green. |
| `super-green-gate-literal` | **Strong.** 4/5 vs 0/5 (Δ 0.80, Sonnet, 2026-10-08), after the magic-literal definition. The miss answered "commit, clean in refactor", the no-skill answer. |
| `fix-forward` | **Strong.** 5/5 vs 0/5 (Δ 1.00, Sonnet, 2026-10-08). Without the skill the answer is always "nothing is pushed, amend/rebase". First version scored 0.2: the skill didn't load on a git-only question (prompt now names it), and the grader wrongly failed a working-tree `git revert --no-commit`. |

## `one-test-per-step` — weak discriminator

It scores mid-range on *both* models (~0.70 Sonnet, ~0.75 Opus) and they sit
close together, which indicates the case is hard to grade rather than that the
models differ.

The difficulty is real, not a wording bug: the case asks whether the agent
advanced "one step", and a good answer can legitimately split an over-broad
planned test into two smaller cycles — which is the triangulation rule applied
*more* carefully, while superficially looking like "wrote several tests". The
grader was rewritten once to stop penalising exactly that, which lifted both
scores, but judging "one step" reliably from prose remains fuzzy.

It replaced an earlier case, `plan-then-one-test`, which was unsalvageable
without a scaffold: it tested an approval gate that pauses work *before doing
it*, in a sandbox where no work can be done, so both models scored ~0.25
identically. Note that `--scaffold` is off by default, so adding a
`scaffold_script` would not have fixed it under a plain `make eval` either.

Use the two strong cases for model comparison. Treat this one as a regression
check on the skill's wording, not as a measurement.

## `scoped-build-and-evidence-gradle` — new, untested

`scoped-build-and-evidence` only ever exercised Maven. `SKILL.md`'s Gradle
guidance carries a rule with no Maven equivalent — a green result can be
`UP-TO-DATE`/`FROM-CACHE` without the test actually re-executing, which is
safe for a normal bytecode-driven cycle but not for a test depending on an
untracked input (the clock, an env var, a file outside declared inputs, an
external service). This case targets exactly that: the test asserts against
`LocalDate.now()`, and the `cache-honesty` grader checks whether the agent
calls for `--rerun`/`--no-build-cache` instead of trusting a bare green, and
flags `cleanTest` as the specific wrong fix `SKILL.md` warns about.

First smoke-test run (Sonnet, `--runs 1`) scored 0.50: `cache-honesty` passed
3/3, but `criteria` failed 3/3 on a command that was actually correct —
`./gradlew :billing-core:test --tests "*.InvoiceDueDateTest.method" --console=plain | tail -30`.
The grader's PASS example only showed a bare, unqualified `--tests
"com.example.ClassName"`, so the judge read the module-qualified task path
and the `*.` wildcard (both valid Gradle syntax, and the agent had itself
flagged the wildcard's tradeoff as a caveat) as non-conforming — the same
"penalised a better answer" signature `docs/design-log.md` documents
repeatedly. Fixed by naming both forms as acceptable in `criteria.md`;
re-run with no other change scored 1.00. Still only one Sonnet run — full
`--runs 5` × both models calibration is outstanding before this case's score
means anything beyond "the grader no longer has that specific blind spot."

### 2026-09-22 smoke test: `cache-honesty` has its own judge-noise problem

Ran the whole `igiari-tdd` suite Sonnet-only (`--runs 1 --ablation none`,
$0.44 total): `one-test-per-step`, `scoped-build-and-evidence`, and
`triangulate-before-generalizing` each scored a clean 1.00 — one sample, so
read as "no surprise," not new confirmation of the historical numbers above.
`scoped-build-and-evidence-gradle` scored 0.50, `cache-honesty` FAIL 3/3.

That FAIL didn't hold up on inspection. The response it judged explicitly
proposed `--rerun` on the scoped task, explained why the clock isn't a
tracked Gradle input, never proposed `cleanTest`, and covered every point
`cache-honesty.md`'s own PASS list asks for — by the grader's stated
criteria this should have passed. Followed up with `--runs 5` on just this
case (`$0.60`) to see whether that was a fluke: 4/5 scored 1.00 (`cache-honesty`
unanimous PASS), 1/5 scored 0.50 with a **split judge vote** — FAIL PASS FAIL
on the same response text, i.e. the three judges disagreed with each other,
not just across runs. Case score for the batch: 0.90.

Combined across all 6 Sonnet samples that day: case-score average 0.83,
`cache-honesty` judge-vote pass rate 13/18 (~72%). Unlike the `criteria` fix
above, this isn't a clear single wording bug to point at — the grader's own
text already states the PASS bar precisely and the failing responses met it.
Read this as: the case now has a real, still-open source of judge noise on
`cache-honesty` specifically, worth a closer read of borderline transcripts
(`--keep-temp`) before trusting a future score change on this grader as
signal rather than variance. No change made to `cache-honesty.md` yet — the
existing wording doesn't look like the culprit, so rewriting it without
knowing what would fix it risks the same "fixed a symptom, not the cause"
mistake documented elsewhere in this file. Still no Opus data for this case.

### 2026-10-02: `triangulate-before-generalizing` passes without the skill

Re-run after rule 5 was clarified (a hardcoded value is minimal only while one
value satisfies every test): `--runs 5`, default ablation, session model,
$0.53. With skill 5/5 at 1.00, **without skill 5/5 at 1.00**, Δ 0.00, judges
unanimous. The single-test scenario ("hardcode `"I"`") is something models do
unprompted, so this case can only catch a regression, not show the skill's
effect, and it doesn't touch the clarified half of rule 5 at all (the second
test, where per-input literals like `n == 1 ? "I" : "II"` are now faking). A
two-test case is the open gap.

### 2026-10-02: `generalize-just-enough` — the first case that shows the skill working

Built to cover the half of rule 5 clarified that day. First attempt was a
Roman-numeral `I`/`II` case: 10/10 answers wrote `"I".repeat(number)`, with or
without the skill, so it was discarded (never committed) — the faking failure
it targeted only appears when a prompt *pushes* hardcoding, not unprompted.

Rebuilt around the String Calculator moment where the split-mode dogfood
overshot: `""→0`, `"5"→5`, new red `"1,2"→3`. The skill's answer is two-operand
code; the unprompted answer is a loop/stream sum over all parts.

- Run 1 (`--runs 5`, $0.59): with 1.00, without 0.40. Inspection found a
  grader defect: a baseline answer that wrote two-operand code and showed a
  stream only as an explicitly *deferred* next step got a split FAIL PASS FAIL
  — the grader never said a deferred generalization is allowed. Fixed by
  judging only the code proposed for *this* green.
- Run 2 (`--runs 5`, $0.60): **with 1.00 (5/5), without 0.00 (5/5)**, all
  votes unanimous; each answer's green code checked by hand against its
  verdict. Across both runs the baseline built ahead 7/10 times.

One model (the session's default), 10 samples per arm — enough to show the
effect, not to measure its size precisely.

## Opus pass on the super-green gate cases (2026-10-08)

With the skill only (`--ablation none`), 3 runs per case: **18/18** on the six
`super-green-gate*` cases, with the skill loaded every run. The first attempt
lost 5 runs to an account usage limit mid-run ("session limit" from the
agent or the judge). Those were re-run, not counted as failures. $4.47 in all.
No no-skill Opus arm yet.
