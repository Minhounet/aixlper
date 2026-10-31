# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `done-gate` | **Clean, but not discriminating.** 1.00 with the skill and 1.00 without (Sonnet, 5+5 runs, Δ 0.00, judges unanimous, 2026-10-03). It shows no regression, not a skill effect. |
| `hidden-contradiction` | **Discriminating, modest.** 0.90 with the skill, 0.50 without (Sonnet, 5+5 runs, Δ +0.40, 2026-10-10). The effect is on *not resolving* the conflict, not on spotting it. |
| `ac-test-red-first` | **Not discriminating since the true-TDD rewording.** First grader: 1.00 with, 0.67 without (Sonnet, 3+3, 2026-10-31). After rewording the grader for true TDD (small steps through the use case, a big front-loaded test tolerated only if red): 1.00 with, 1.00 without (Sonnet, 2+2). It now shows no regression, not a skill effect. A sharper variant would plan a case where the natural order puts the use-case test last. |

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

## `hidden-contradiction`

The discriminating variant `done-gate` called for. The agent gets only the
ticket prose (`PROJ-77`, password reset), no `acceptance.md`, and a user
who says the expiry rule is "basically settled" and asks for a Decisions
draft. Planted in the ticket:

- **Lifetime stated three ways:** description 24 hours, AC2 1 hour,
  security comment 15 minutes. Graded by `expiry-conflict` (weight 2): the
  agent must give at least two values with their locations, not pick one,
  and say who decides.
- **Unanchored AC:** AC3 asks for a confirmation SMS the description never
  mentions. Graded by `unanchored-sms`.
- **Decoy:** AC1 ("within 60 seconds") is compatible with "promptly", and
  AC4 conflicts with nothing. `no-false-alarm` fails an agent that flags
  them, so flagging everything doesn't pass.

### 2026-10-10 run: Sonnet, Δ +0.40

`--runs 5 --model sonnet`, ablation on, $0.54 total. With the skill: four
runs at 1.00 and one at 0.50 (mean 0.90). Without: 0.75, 0.50, 0.25, 0.50,
0.50 (mean 0.50). Judges returned votes only, no written reasons, so the
reading below comes from the answers themselves.

- **Spotting the conflict is not what the skill adds.** All five baseline
  answers noticed that the ticket gives 24 h, 1 h and 15 min, and quoted
  the values. A strong model sees it when it writes a draft anyway.
- **What the skill adds is not settling it.** Four of five baseline runs
  failed `expiry-conflict` because they wrote the 15-minute cap into
  `## Decisions` (as default and maximum, with startup validation) and then
  listed the conflict as an open point. That picks a side, even if openly.
  With the skill, four of five left the lifetime as "configured, value
  pending" and put the three values in a discrepancy table with an owner.
- **The one with-skill failure (run 5) did the same thing:** it wrote
  "must not exceed 15 minutes" into Decisions while saying it had not
  picked a side. So the skill lowers the rate (1/5 against 4/5), it does
  not remove the behavior.
- **Over-flagging:** two baseline runs reported AC1 versus "promptly" as a
  problem (`no-false-alarm`); no with-skill run did. Small numbers: 2/5
  against 0/5.
- **SMS plant:** found by every run in both arms, so `unanchored-sms`
  discriminates nothing here. It stays as a regression check.

Caveats: five runs per arm, one model, three judges with no stated reasons,
and a grader that treats "writes the cap as a decision" as a fail. A user
may consider adopting the 15-minute cap reasonable, so the case measures
adherence to "never settle one silently", which is the skill's own rule.
Next: run it on Opus, and consider tightening the prompt so that
"configured duration" is not already a comfortable way out.

## `ac-test-red-first`

Pins the rule decided after the first full `iterate` run: **TDD wins on how
an AC is proven**. The agent gets an approved structure and a `designed` AC1
(lock after three failures) and is asked for the ordered TDD test plan for
AC1 only, tagged per AC. The natural plan unit-tests `UserAccount` first and
adds the use-case test last, where it would already pass when written - the
exact case the full run hit twice.

- `proof-test-red-first` (weight 2): a use-case-level `[AC1]` test placed
  where it fails when written (or the problem explicitly flagged and fixed).
- `tags` (weight 1): every test tagged, helper tests as `supports`.
