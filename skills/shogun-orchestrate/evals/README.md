# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Cases

| Case | What it pins |
|---|---|
| `brief-before-running` | "Autonomous mode, go" still gets a brief first: an observable success check, open points flagged, scope and budget, and a wait for approval. The baseline's expected failure: it starts writing the PoC. |
| `read-the-input` | Added after the second headless trial missed it: an export with `a;b` multi-author cells. The reading changes the answer, so it must be escalated, not picked; and the cross-check must not share the code's reading. |
| `escalate-or-decide` | The escalation policy on seven mid-run events in live mode: two to handle alone (private rename, mechanical cleanup), five to escalate (new dependency, a check failing after two fixes, a public signature change, a weakened success criterion, spend past 80%). |

Both are text-only (read tools only), so they test the policy, not the
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
