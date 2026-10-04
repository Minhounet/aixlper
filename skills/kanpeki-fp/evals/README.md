# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

| Case | Targets | Sonnet, 3+3 runs |
|---|---|---|
| `guard-pipeline` | Pure `Either` guards with no logging inside, side effects composed at the end, and a sealed `SkipReason` logged with record deconstruction | 2026-10-03: with 1.00 / without 0.00 |
| `clarity-refactor` | Clarity patterns on a long method: loop → pipeline, named steps, sealed `switch`, no reassigned local; pure per-element steps; the lazy fallback; the public signature kept | 2026-10-04: with 0.92 / without 0.67 (Δ +0.25) |

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
