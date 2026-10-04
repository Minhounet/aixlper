# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

| Case | Targets | Sonnet, 3+3 runs, 2026-10-03 |
|---|---|---|
| `guard-pipeline` | Pure `Either` guards with no logging inside, side effects composed at the end, and a sealed `SkipReason` logged with record deconstruction | with 1.00 / without 0.00 |

**Strong discriminator.** Without the skill, Sonnet wrote reasonable code,
but not this style. One run used a `check()` helper that logs inside the
predicate. Another used a `List<SkipRule>` of string reasons and decided not
to use Vavr at all. With the skill, all three runs produced the house
pipeline. This confirms that the skill's value is enforcing a house style
that a model doesn't choose by default. It doesn't measure whether that
style is better. Run cost: $0.32.
