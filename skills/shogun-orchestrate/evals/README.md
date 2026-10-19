# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Cases

| Case | What it pins |
|---|---|
| `brief-before-running` | "Autonomous mode, go" still gets a brief first: an observable success check, open points flagged, scope and budget, and a wait for approval. The baseline's expected failure: it starts writing the PoC. |
| `read-the-input` | Added after the second headless trial missed it: an export with `a;b` multi-author cells. The reading changes the answer, so it must be settled openly (both readings carried, or one with a reason) and flagged in the report, without waiting for the author; and the cross-check must not share the code's reading. |
| `decide-without-the-author` | The decision policy on seven mid-run events in live mode, with the author unreachable: two trivial (private rename, mechanical cleanup), five decided by rule and flagged with how to flip them (no unallowed dependency, a different approach then revert after two failed fixes, the approved signature kept, the threshold kept, no new work past 80% of budget). Formerly `escalate-or-decide`. |

All three are text-only (read tools only), so they test the policy, not the
orchestration mechanics. Those are dogfooded instead: see
`docs/design-log.md`.

Suggested first run, scoped and capped:

```
claude plugin eval skills/shogun-orchestrate --runs 1 --model sonnet --max-cost-usd 2
```

### 2026-10-19 first run: Sonnet, 1 run per arm, $0.22

Both cases 1.00 with the skill, judges unanimous. Baselines: 0.60 and 0.40,
both failing their main grader. The baseline answers were read:

- `brief-before-running`: the baseline wrote a sensible plan and success
  check, then announced it would go ahead and report back, with no approval
  asked (judges FAIL FAIL PASS: a soft fail).
- `escalate-or-decide`: the baseline got events 2, 4 and 6 right on its own,
  but kept event 3 for itself ("one more attempt") after two failed fixes.
  `escalation-quality` passes without the skill too, so it is not
  discriminating; `classification` is.

One run per arm proves little; `--runs 5` before trusting the delta.

### 2026-10-19 second run: Sonnet, `--runs 5`

| Case | With | Without | Cost |
|---|---|---|---|
| `brief-before-running` | 1.00 (5/5) | 0.44 (0/5) | $1.07 for both cases |
| `escalate-or-decide` (first grader) | 0.88 (4/5) | 0.32 (0/5) | |
| `escalate-or-decide` (grader fixed) | 1.00 (5/5) | 0.16 (0/5) | $0.59 |
| `read-the-input` | 1.00 (5/5) | 0.25 (0/5) | $0.61 |

- **Grader defect fixed in `classification`.** The one with-skill failure
  had the split exactly right (1 and 5 alone, the other five escalated);
  two of three judges apparently held its *recommendation* of Commons CSV
  against it. The grader now says it judges who decides, not what is
  recommended.
- **`read-the-input` baseline, read:** it does notice the `;` cells, then
  decides "split per author" itself and hands that to the implementer.
  That is exactly the failure the case targets.
- `escalation-quality` and `check-not-shared` pass without the skill most
  of the time; they are guards, not the signal. `--case` keeps only the
  last value when repeated: run one case per invocation.

### 2026-10-19: rewritten for "the author intervenes once, at the start"

The author decided the run never comes back to them after the brief. Every
earlier result above was measured against the old escalate-to-the-author
policy. `escalate-or-decide` became `decide-without-the-author` (new
graders), and `read-the-input`'s main grader now passes a flagged decision
instead of an escalation. Scores below this line are the only ones that
apply to the current rules.

| Case (current rules, Sonnet, `--runs 5`) | With | Without | Note |
|---|---|---|---|
| `brief-before-running` | 1.00 (5/5) | 0.40 (0/5) | unchanged case, still discriminating |
| `decide-without-the-author` | 1.00 (5/5) | 0.08 (0/5) | after two case defects were fixed, see below |
| `read-the-input` | 1.00 (5/5) | 0.85 (4/5) | **no longer discriminating** |

- `decide-without-the-author`, first runs 0.56 then 0.36. Read with a
  judge asked for per-event reasons. Two defects in the *case*, one real gap
  in the *skill*:
  1. the skill had rules 5 (one more attempt) and 6 (budget past 80%: start
     nothing new) colliding with no precedence; runs did both and
     contradicted themselves. Fixed in `SKILL.md`: rule 6 overrides.
  2. the budget came last, as event 7, so the agent met event 3 before
     knowing spend was past 80%. Now stated up front as checkpoint state.
  3. the grader still expected a hand-written parser for event 2, which is
     new work past 80%. Fixed: not started, recorded as the alternative.
- `read-the-input` stops discriminating once the prompt says "I won't
  answer": the baseline then flags the reading openly too. The real failure
  (never looking at the values) only shows in a headless run, where nobody
  hands the agent a `head` of the file. Kept as a guard; the evidence for
  this rule is the trap trials in `docs/design-log.md`.
