# Cross-skill evals

Cases here check how the Java skills work **together**, which no single
skill's `evals/` can do: a skill-dir plugin loads one skill only. Run them
with `scripts/eval_skill_chain.sh` (it bundles `chottomatte-archi`,
`igiari-tdd` and `kanpeki-fp` into a temporary plugin), or
`make eval-chain`. `make eval` does not run them.

The graders are `tool_used` checks on the `Skill` tool, so there is no
no-skill baseline arm (`--ablation none`).

| Case | Question | Sonnet, 3 runs, 2026-10-04 (before the fix) |
|---|---|---|
| `skill-chain-natural` | A Java feature request that names no skill. Are all three loaded before any code? | 1.00. All three loaded, in the order chottomatte → igiari → kanpeki, then the structural plan, pausing for approval |
| `skill-chain-from-archi` | Same request, but "use the chottomatte-archi skill". Does it pull in the other two? | 0.33. Only `chottomatte-archi` loaded. It stops at its plan-approval gate, and the other two are never loaded |

**Reading:** the three skills load together because each one's description
matches a Java feature request, not because one skill's text pulls in the
next. When `chottomatte-archi` is invoked by name, its "load the other one
too when…" sentence doesn't fire before its plan gate. The test plan
(`igiari-tdd`) and the expression rules (`kanpeki-fp`, e.g. a sealed result
rather than `Either` for a public API) are then missing from the plan the
author approves. Run cost: $0.83 (plus a $0.38 first attempt that loaded no
plugin and was discarded).

**Fix, same day:** `chottomatte-archi`'s Related skills gained one sentence:
when the task will write production code, load `igiari-tdd` and `kanpeki-fp`
before presenting the structural plan. Re-run (Sonnet, 3 runs, $1.18):
`skill-chain-from-archi` **1.00** (3/3 load all three before the plan, up
from 0.33), and `skill-chain-natural` 1.00 (unchanged).
