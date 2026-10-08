# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

| Case | Targets | Sonnet, 3+3 runs |
|---|---|---|
| `guard-pipeline` | Pure `Either` guards with no logging inside, side effects composed at the end, and a sealed `SkipReason` logged with record deconstruction | 2026-10-03: with 1.00 / without 0.00; 2026-10-04 (after the clarity/laziness/logging/memoize additions): with 1.00 / without 0.22 |
| `clarity-refactor` | Clarity patterns on a long method: loop → pipeline, named steps, sealed `switch`, no reassigned local; pure per-element steps; the lazy fallback; the public signature kept | 2026-10-04: with 0.92 / without 0.67 (Δ +0.25); re-run after later additions: with 1.00 / without 0.75 (Δ +0.25) |
| `failing-import` | Implementing a public method that can fail: `Try` instead of `try/catch` around each throwing call only, validation failures as values, a sealed result of its own as the public return type | 2026-10-04: with 0.89 / without 0.33 (Δ +0.56) |

**Strong discriminator.** Without the skill, Sonnet wrote reasonable code,
but not this style. One run used a `check()` helper that logs inside the
predicate. Another used a `List<SkipRule>` of string reasons and decided not
to use Vavr at all. With the skill, all three runs produced the house
pipeline. This confirms that the skill's value is enforcing a house style
that a model doesn't choose by default. It doesn't measure whether that
style is better. Run cost: $0.32.

**`clarity-refactor`: the effect is in purity, not in the refactor itself.**
Without the skill, Sonnet already turns the loop into a pipeline, extracts
named steps, uses a sealed `switch`, keeps the fallback lazy (`orElseGet`)
and keeps the public signature: `clarity-patterns`, `lazy-fallback` and
`signature-rule` pass in both arms. The difference is `pure-steps`. Without
the skill, all 3 runs log inside the mapping method and use type patterns
with accessors. With it, all 3 move the log to one `forEach` after the
pipeline and use record deconstruction. That grader was added after the
first run (with 0.89 / without 1.00, $0.47), which showed the gap in
the answers while every grader missed it. Second run: $0.51.

**Known grader noise:** `clarity-patterns` failed once per arm on answers
that look compliant, with no rationale exposed (Haiku judge, 3 votes). The
`label` wording was clarified after the first run, and the noise stayed.
Before trusting a single failure, read the answer, or try
`--judge-model sonnet`.

**Full-suite re-run, 2026-10-04 ($0.98, Sonnet, 3+3 runs).** This followed
the decision-as-data, laziness, logging, function-builder and memoization
additions, and the moves to `references/`. There was no regression: both
cases scored 1.00 with the skill, 3/3. `clarity-refactor`'s noisy
`clarity-patterns` grader passed all six runs this time. The discriminator
was again `pure-steps`, failing 0/3 without the skill. `guard-pipeline`
without the skill reached `pure-guards` once out of 3 and `sealed-reason`
never.

**`failing-import`: the skill decides the error-handling shape.** ($0.54)
Both arms produce validation failures as values, so that grader does not
discriminate. Without the skill, all 3 runs use `try/catch` blocks and return
`Either<ImportError, String>` from the public method: a sealed error type,
but Vavr in a public signature. With the skill, all 3 runs return a sealed
`ImportResult` of their own built with one `fold`, and use `Try` for the
parse. One run still wrapped `ledger.post` in a `try/catch`. That's the only
with-skill failure, and it's a real one, not grader noise.

**After the examples moved to `references/examples.md`, 2026-10-04 ($1.53,
Sonnet, 3+3 runs).** `guard-pipeline` scored with 1.00 / without 0.22,
`clarity-refactor` with 1.00 / without 0.83, and `failing-import` with 0.89
/ without 0.33 (the same single `try-boundary` miss as before). These match
the scores from before the move, so there's no regression. The guard,
`SkipReason` and logging-switch examples stayed inline on purpose: they are
what `guard-pipeline` measures.

## `option-parameter` (2026-10-08)

"Option is an output, never a parameter". First version: Δ 1.00, but
misleading. The no-skill arm also removed the `Option` parameter (5/5) by
inlining a one-line helper for unrelated reasons, and failed only for not
naming the rule. Reworked so inlining isn't the natural move (the helper has
two callers and does two things): **5/5 with the skill, 1/5 without (Δ 0.80)**,
Sonnet, 5 runs, $0.53. Without the skill, the answer reshapes the helper (takes
a `Customer`, or `remindAll` delegates) and keeps the `Option` parameter.
