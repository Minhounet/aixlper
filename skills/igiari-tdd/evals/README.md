# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `triangulate-before-generalizing` | **Strong.** 1.00 on both models; clean, unambiguous rule. |
| `scoped-build-and-evidence` | **Strong.** 1.00 on both models. |
| `one-test-per-step` | **Weak — do not read as a model signal.** |
| `scoped-build-and-evidence-gradle` | **Not yet run.** New case — score not yet established; do not cite it until calibrated (see below). |

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

Written but not yet run against either model — before citing a score, run it
at `--runs 5` per case-strength discipline above, and read a few transcripts
first: per the grader-defect history in `docs/design-log.md`, a first pass
is as likely to reveal a bad grader as a bad skill.
