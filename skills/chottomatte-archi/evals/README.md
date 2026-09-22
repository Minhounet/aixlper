# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `repository-returns-domain` | **Strong.** 1.00 on both models (third calibration run, `--runs 5`). |
| `invert-nondeterministic-dependency` | **Strong.** 0.80 Sonnet / 1.00 Opus, after two grader-wording fixes that had penalized the better answer (see `docs/design-log.md`). |
| `plan-structure-first` | **Moderate, not confounded.** Approval-gate discipline is genuine signal — Sonnet lands 0.76–0.88 across two calibration passes, Opus 1.00. Unlike `igiari-tdd`'s retired `plan-then-one-test`, this case discriminates: Sonnet visibly skips the pause some fraction of the time rather than scoring identically to Opus. |

## `plan-structure-first` — two graders, second one extended 2026-09-22

Split into two independent LLM graders:

- **`criteria`** (weight 3) — the structural-plan approval gate itself: does the response present the plan and stop, rather than going straight to implementation.
- **`spring-out-of-core`** (weight 2) — dependency direction and Spring placement in whatever the response commits to. Extended 2026-09-22 to also require every repository port to list an in-memory implementation in the plan, matching the new `SKILL.md` rule "Every repository port ships with an in-memory implementation."

Third calibration run (`docs/design-log.md`, `--runs 5`, both models): combined case score 0.76 Sonnet / 1.00 Opus.

**Smoke test of the `spring-out-of-core` extension, 2026-09-22 (Sonnet only, `--trust-plugin`):**

- Two isolated `--runs 1` samples: both scored 0.40 — `criteria` FAIL 3/3 judges both times (the response announced it would implement immediately after the plan, with no pause for approval), `spring-out-of-core` PASS 3/3 both times.
- Follow-up `--runs 5` batch on the same `SKILL.md`: `criteria` PASS 4/5, `spring-out-of-core` PASS 5/5 (one run had a single dissenting judge, 2/3, still a net PASS). Case score 0.88.
- Combined across all 7 samples that day: `criteria` passed 5/7 (0.71) — consistent with the 0.76 calibrated baseline within sampling noise. The two back-to-back fails were a short unlucky streak, not a regression from the new rule.
- `spring-out-of-core`'s new in-memory-adapter check held up on every sample: the response consistently named `InMemoryTicketRepository`/`InMemoryAuditLogWriter` unprompted, confirming the model picks up the new `SKILL.md` rule even though the prompt never mentions tests.

Cost for the 2026-09-22 smoke test: $0.34 + $0.33 + $0.90 = **$1.57** (7 runs total, Sonnet only, `--ablation none`).

## `invert-nondeterministic-dependency` — grader on its third revision

Tests the skill's precise line: the trigger for wrapping a call behind an owned
interface is non-determinism, not staticness. Went through two grader defects
before stabilizing, both of which penalized a *better* answer than the one the
grader's author had imagined:

1. First grader said `Math.max` must be "left alone" and failed *any* mention
   of it — both models had correctly declined to wrap it while separately
   flagging a real bug (`nextNumber(c, 0)` and `nextNumber(c, -5)` both mint
   invoice `00001`). Narrowed to judge dependency direction only.
2. Second grader required `UUID.randomUUID()` to be "moved behind a port" —
   Opus argued instead that the 4-hex-char suffix should be **deleted**
   outright (uniqueness belongs in the sequence plus a DB constraint), which
   the skill's own logic agrees is a better answer than wrapping a dependency
   you don't need. The grader now accepts removal as an equal-or-better PASS.

Current state matches the file on disk: dependency direction only, removal
credited. Stable at 0.80 Sonnet / 1.00 Opus across the third calibration run.

## `repository-returns-domain` — clean from the start

No grader-defect history. Tests that a repository returns the domain object
(not a primitive/projection) and that the use case maps to its own `Response`
rather than handing the entity back. 1.00 on both models across every
calibration run so far — the most reliable case in this suite for judging
whether a model change (or a cheaper model) still holds this skill's rules.

## Reading this table

`repository-returns-domain` is the cleanest signal for model comparison — no
known grader defects, perfect and stable across models. `plan-structure-first`
and `invert-nondeterministic-dependency` favor Opus on judgment-shaped
questions but are not confounded like `igiari-tdd`'s retired
`plan-then-one-test`: Sonnet's lower score reflects real, sometimes-skipped
discipline (the approval pause, the non-determinism/staticness line), not a
sandbox or grader artifact. Full cost/run history: `docs/design-log.md`.
