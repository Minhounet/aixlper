# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `triangulate-before-generalizing` | **Strong.** 1.00 on both models; clean, unambiguous rule. |
| `scoped-build-and-evidence` | **Strong.** 1.00 on both models. |
| `one-test-per-step` | **Weak — do not read as a model signal.** |

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
