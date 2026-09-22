# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `triangulate-before-generalizing` | **Strong.** 1.00 on both models; clean, unambiguous rule. |
| `scoped-build-and-evidence` | **Strong.** 1.00 on both models. |
| `one-test-per-step` | **Weak — do not read as a model signal.** |
| `scoped-build-and-evidence-gradle` | **1.00 on a single Sonnet smoke-test run** (`--runs 1`, not yet calibrated at `--runs 5` across models — see below). |

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
