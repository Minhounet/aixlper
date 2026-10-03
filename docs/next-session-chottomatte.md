# Next session: study `chottomatte-archi`

> Handoff brief written at the end of the `igiari-tdd` study session
> (2026-10-02). Delete this file, and its pointer in `CLAUDE.md`, once the
> study is done and logged in `docs/design-log.md`.

## Goal

Do for `chottomatte-archi` what the previous session did for `igiari-tdd`:
find where the skill is ambiguous or contradicts itself, settle each point
with the author, and check that its evals actually measure the skill. Read
the `igiari-tdd` entries at the end of `docs/design-log.md` first. They show
the method and what it found.

## Method that worked (do it in this order)

1. **Branch.** Work on a fresh branch from `main`, separate from any other
   skill's work.
2. **Kata dogfood.** Pick a small kata with **real collaborators** (per
   `CLAUDE.md`: a repository plus a gateway/clock, not a pure algorithm). Set
   it up in the scratchpad as a git repo, never committed to this repo. Follow
   `chottomatte-archi` literally, with `igiari-tdd` loaded too, as in real use:
   the structural plan comes first and the test plan is written against it.
   Show real command output at every checkpoint.
   - To avoid bias, have a **fresh subagent** run the kata reading only the
     two `SKILL.md` files. The session's own context already knows the
     pitfalls. The previous session's inline baseline did this.
   - Note every friction point: ambiguous rules, rules that contradict each
     other, rules that contradict the skill's own examples, missing
     fallbacks.
3. **Contradictions one at a time.** Put each friction point to the author
   as a question with a recommended option, apply the decision, add a
   design-log entry, commit, and push. One decision per commit. Never fix
   one silently.
4. **Evals against the no-skill baseline.** The 3 cases in
   `skills/chottomatte-archi/evals/` (`invert-nondeterministic-dependency`,
   `plan-structure-first`, `repository-returns-domain`) are only reported at
   1.00 on Sonnet. Run each with the default ablation, `--runs 5` and
   `--max-cost-usd 3` (about $0.50–0.60 per case on one model).
   - **Δ 0 means the case proves nothing.** `igiari-tdd`'s
     `triangulate-before-generalizing` scored 1.00 with and without the
     skill.
   - Before trusting any verdict, read every surprising one against the
     actual answer. Grader defects that penalised the better answer have
     happened five times in this repo.
   - If a case doesn't discriminate, find the failure models make
     *unprompted* and build the case around it. `igiari-tdd`'s
     `generalize-just-enough` went from Δ 0 to Δ 1.00 that way.

## Also look at (added after the delegated-run work)

`igiari-tdd` gained an opt-in **delegated run**: after plan approval, one
agent runs every cycle, foreground or background, with one commit per step,
and the main session audits the git history. `chottomatte-archi` gets **no**
delegated mode of its own; it shapes structure and doesn't run cycles. Two
questions for this study, both for the author to decide:

1. **Combined use.** With both skills loaded and a delegated run requested,
   does the existing hand-off work? Both plans should be approved first,
   then one agent follows both `SKILL.md` files. Running the kata delegated
   tests this directly. If something is missing, the fix is one sentence in
   `igiari-tdd`'s delegated-run section, not a new section here.
2. **Checkable rules.** Which `chottomatte-archi` rules can the audit
   *check* rather than trust? Candidates: a full build ran after each
   structural change; `new ConcreteThing(...)` appears only at the
   composition root (searchable); every repository port has an in-memory
   implementation.

## Lessons from the `igiari-tdd` study

- **Enforce rules by checking, not by asking.** Rule 9 (test files frozen
  during GREEN, checked with one command) was the lasting win. Look for a
  `chottomatte-archi` rule that could be checked the same way.
- **Subagents don't fit these skills.** Split mode cost about 9× the tokens
  and did worse than inline, and it was removed. Don't propose it again
  without new evidence.
- **The skill's own examples count as rules.** Several contradictions were
  an example disagreeing with a rule.
- **Never remove or "clean up" a section without the author asking** (see
  `CLAUDE.md`). Ask explicitly.
- `chottomatte-archi/SKILL.md` and `igiari-tdd/SKILL.md` are both well over
  the ~20KB guideline. A token self-audit is due, but only as a separate step
  and only if the author wants it.
