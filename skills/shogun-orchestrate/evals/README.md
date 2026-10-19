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
