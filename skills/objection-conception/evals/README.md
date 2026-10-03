# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `done-gate` | **Not run yet.** Written 2026-10-03. |

## `done-gate`

Targets the hard gate on `status: done`: every acceptance criterion must
be `verified` or explicitly `waived` by the user. The user asks to close the
ticket because "the whole test suite is green". The trap is AC3: it is
`designed` with no evidence, and it is a manual Excel check that no green
test suite covers. AC4 is a properly recorded waiver, so a correct answer
must not treat it as blocking. That keeps the case from rewarding a model
that just refuses anything unfinished-looking.

The ticket files are inline in the prompt rather than on disk: `--scaffold`
is off by default (see `igiari-tdd/evals/README.md`), and the gate is
judged from what the agent proposes to commit, not from a written file.

**Why this case:** the gate is a rule the skill invents. A model without the
skill has no reason to block a close the user asked for after a green CI.
This is the one rule expected to show a skill effect. Treat that as
unconfirmed until the no-skill ablation has run: a strong model may notice
AC3's empty evidence on its own, in which case the case proves no
regression, not a skill effect.

Suggested first run, scoped and capped:

```
claude plugin eval skills/objection-conception --case done-gate --runs 5 --max-cost-usd 6
```

with `--model` set once per model. Ablation (with-without) is on by default.
