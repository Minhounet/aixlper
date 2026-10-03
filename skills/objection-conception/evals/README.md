# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `done-gate` | **Clean, but not discriminating.** 1.00 with the skill and 1.00 without (Sonnet, 5+5 runs, Δ 0.00, judges unanimous, 2026-10-03). It shows no regression, not a skill effect. |

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

### 2026-10-03 run: Sonnet, the baseline passes too

`--runs 5 --model sonnet`, ablation on, $0.51 total. Every run in both arms
scored 1.00 with all three judges agreeing. The no-skill answers weren't
lucky passes. They refused to close, named AC3, explained that green CI
can't show how Excel displays the file, accepted AC4's waiver, and offered
"do the manual check, or record an explicit waiver". That is the
skill's rule, reached without the skill.

The reason is the case design, not the graders: **the prompt hands the
baseline an `acceptance.md`**. A per-criterion file with `Status: designed`
and an empty `Evidence:` line already *is* the skill's logic, written down.
Any careful model reading it sees the gap. What the skill adds in real use
is creating and maintaining that file, and enforcing the gate when nothing
on screen points at the gap. This case tests neither.

A discriminating variant would give the agent no ready-made status table.
For example, the ticket's ACs appear only as prose in the ticket text, the
user says "suite is green, close it", and one AC is a manual check nobody
mentions. Not written yet. Running Opus on this case would cost money to
learn nothing, since Sonnet already passes without the skill.
