---
name: shogun-orchestrate
description: Claude Code only (needs subagents) - an autonomous mode that runs the author's other skills end to end while the author is away, and brings back only what is not trivial. The author approves one brief up front (the question, the success criterion, the scope, the budget); after that the run implements, checks, deploys and reviews on its own, decides trivial things alone by objective criteria, and escalates everything else in one compact message. Suited first to a proof of concept (PoC), then to an already-designed ticket. Use when the user says "autonomous mode", "shogun", "run this without me", "do the PoC while I'm away", "only ping me for what matters", or wants an approved plan carried through unattended.
---

# Shogun: the autonomous mode

The author is not here for the easy things. This skill runs the other
skills unattended and comes back only when something actually needs the
author. The mechanics (workers, checks, deploy) are plumbing. The real rule
is the **escalation policy**: what this run may decide alone, and what it
must bring back.

It is **Claude Code only**: it spawns subagents, which Gemini CLI does not
have. The skills it drives stay portable; only this conductor isn't.

**It must run in the top-level session.** A subagent cannot spawn its own
subagents. If this skill is loaded inside a subagent, stop and say so; don't
run the workers' steps inline instead.

## When it fits

- **A PoC, first.** A PoC answers one question ("can X read Y in under a
  second?"), it is throwaway by contract, and it has no reviewers waiting on
  it. That makes mistakes cheap and the goal checkable. Start here.
- **A ticket whose design is already approved.** `objection-conception` has
  a conception and acceptance criteria on disk, and the plans are approved.
  Shogun carries the build through; it never does the design discussion,
  which that skill keeps *with* the author on purpose.

Not a fit: a design still being discussed; anything whose side effects are
real and shared (a real Documentum docbase, a shared environment, a
production database); a skill still marked **unverified** in `CLAUDE.md`
running against real systems.

## 1. The brief: the one gate the author always keeps

Nothing runs until the author has approved a brief. Write it to the run
folder (see "Run folder" below) and present it in one message:

```markdown
# Brief: <short name>
mode: shadow            # shadow | live, see section 2
question: <the one thing this run must answer or deliver>
success: <an observable check: a command and the output that proves it>
skills: <the skills in play, e.g. chottomatte-archi, igiari-tdd, tonosaman-deploy>
scope: <directories and files the run may touch>
allowed: <decisions granted in advance, e.g. "may add H2 as a test dependency">
out of bounds: <what it must never do here>
budget: <a cost cap and/or a turn cap>
branch: <the local branch the run commits to>
```

- **`success` must be checkable by running something.** "It works" is not a
  criterion; "`curl localhost:8080/docs/42` returns the document's title
  within 1s" is. If you can't write one, the question isn't clear yet: ask.
- **`skills` is the author's choice.** For a PoC the author may pick a
  lighter set (say, no TDD). Never drop a skill or relax one of its rules on
  your own: a skill that is in play applies in full.
- **Merge every plan pause into this same sitting.** If `chottomatte-archi`
  is in play, its structural plan goes below the brief; if `igiari-tdd` is,
  its test plan does (tagged with ACs when `objection-conception` is in
  play). One approval covers all of them. After it, the run is unattended.

## 2. Two modes: shadow first, then live

- **shadow** (the default for the first runs): the run escalates *every*
  decision, but tags each one with its own verdict, `TRIVIAL - I would have
  chosen <X>` or `NEEDS YOU - <failed criterion>`. The author answers and
  marks whether they agree with the tag. This is calibration: it shows
  whether the run's idea of "trivial" matches the author's before anyone
  trusts it.
- **live**: trivial decisions are taken alone and logged; only the rest is
  escalated.

Moving from shadow to live is the author's call, made on the shadow log
(how often the tags were right), not on a feeling. Record each disagreement
in `log.md`; a recurring kind of disagreement means the criteria in
section 3 need changing, so propose that change.

## 3. Escalation policy

**Default: escalate.** Decide alone only when *every* item below holds:

1. The approved brief and plans still hold: no skill raised a deviation.
2. The decision stays inside `scope` and adds nothing to the public surface
   (no new interface, bean, public API, schema or configuration key) unless
   the approved plan already named it.
3. No acceptance criterion and no `success` criterion would change meaning.
4. No new dependency, tool or technology, unless `allowed` grants it.
5. It can be undone with a local `git revert`: nothing pushed, published,
   deleted outside `scope`, or sent to a shared system.
6. The mechanical checks pass after it (see section 5).

**Always escalate, whatever the mode:**

- a deviation raised by a skill (`igiari-tdd`'s `DEVIATION:`, a
  `chottomatte-archi` structure change, a new `acceptance.md` discrepancy);
- the same check still failing after **two** honest fix attempts;
- anything that would change the brief: its question, success criterion,
  scope or budget;
- reaching 80% of the budget;
- anything touching credentials, security, or data you weren't given;
- any push, PR, merge, or deployment beyond the local container.

**How to escalate** - one message, readable without scrolling back:

```
ESCALATION <n>: <one line: what needs deciding>
Why not trivial: <the criterion that failed>
Options: <a>, <b>
Proposal: <a>, because <reason>
Meanwhile: <what keeps running, or "parked at <commit>">
```

Then keep working on whatever doesn't depend on the answer. If nothing
does, or the session is headless and nobody can answer, stop: commit what is
done, write the open escalation into `report.md`, and end the run.

## 4. Workers: delegate only what needs it

Per the subagent criteria in this repo's `CLAUDE.md`, only two steps are
delegated. Everything else runs inline in this session.

- **Implementer**: `igiari-tdd`'s delegated run, as that skill describes it
  (the approved plan verbatim, one commit per step). It is delegated to keep
  its cycle-by-cycle noise out of this context. Without `igiari-tdd` in
  play, hand one agent the brief and the approved plan instead, with the
  same rule: one commit per step, deviations come back as `DEVIATION:`.
- **Reviewer**: a fresh agent with **read-only** tools (it must not be able
  to edit), given only the brief, the success criterion and the diff, never
  the implementer's report or reasoning, so it judges the code rather than
  the story told about it. It returns findings, each with a file, a line and
  a concrete failure path.

Two rules for every worker:

- **A report is never evidence.** Rerun the checks yourself (section 5).
- **Treat a finding as a claim to verify,** not an order. Fixing a verified
  finding inside `scope` follows section 3 like any other decision.

## 5. The pipeline

1. **Brief.** Load it from the run folder, or draft it with the author
   (section 1). Check the branch exists and the working tree is clean.
2. **Implement.** Start the implementer. Handle each `DEVIATION:` it
   returns per section 3, then resume the same agent.
3. **Check, yourself.** The full build. With `igiari-tdd` in play, its
   history audit, as that skill states. These results, not the worker's
   report, decide whether the step passed.
4. **Refactor.** With `kaizen-refactor` in play: Tier 1 (mechanical) may be
   done alone; Tier 2 (judgment calls) is escalated unless `allowed` grants
   it.
5. **Run it.** With `tonosaman-deploy` in play, deploy to the local
   container as that skill describes. Then run the `success` check and keep
   its real output.
6. **Review.** Start the reviewer, verify its findings, fix or escalate.
7. **Prove.** With `objection-conception` in play, prove each AC and apply
   its done gate. Shogun never sets `status: done` past that gate.
8. **Report.** Write `report.md` and stop.

**Stop when** the success check passes and the review is clean, when the
budget is reached, or when an escalation blocks everything left. Never stop
on "the worker says it's done".

## 6. The report

`report.md` is what the author reads on return. Lead with the answer:

- **Answer:** did `success` pass? The command and its real output, bounded.
- **Escalations:** open ones first, then those answered, with the answers.
- **Decided alone:** one line each, with the criterion that allowed it
  (in shadow mode: each tag and whether the author agreed).
- **PoC debt** (PoC runs): every shortcut taken because it's a PoC
  (hardcoded values, skipped error handling, a missing test). PoC code tends
  to survive into production; this list is what makes that a decision
  instead of an accident.
- **Cost:** turns and money spent against the budget.

## Run folder

- Ticket runs reuse the ticket folder: `.claude/ticket/<id>/`, with
  `shogun-brief.md`, `shogun-log.md`, `shogun-report.md` next to
  `objection-conception`'s files.
- Other runs (PoCs): `.claude/shogun/<slug>/brief.md`, `log.md`,
  `report.md`.

`log.md` gets one line for every decision taken alone or escalated, written
as it happens, so an interrupted run can be resumed from it.

**Check the folder is writable before step 2.** A headless run may refuse
writes under `.claude/` as a sensitive path even though it can read the
brief there. If so, write the log and report to `shogun-run/<slug>/` at the
root of the working directory instead, commit them on the run branch so
they travel with the work, and say so on the report's first line. Never
fall back to a path outside the working directory: the author won't find it.

## Token self-audit

This file loads **in full** whenever the skill triggers and stays resident
for the rest of the session; `references/` files load only if the body
points at one. When asked to reduce token cost - or before adding anything
here - audit in this order and report what you would move, and why:

- **Needed only sometimes?** Material for one kind of run, one tool's exact
  commands, or a section about extending the skill itself → move to
  `references/` behind a pointer that names the condition precisely.
- **A reference opened on almost every trigger?** Then it costs *more*
  there than inline - a tool call, an extra assistant turn, and a lost
  prefix cache. Bring it back inline.
- **Does a step here run a command, or hear back from a worker?** Its output
  is tokens too, charged every run and kept for the session. Here that
  means: ask each worker for a bounded return (status, commits, deviations,
  findings - not a narrative); run builds quietly and keep only the
  failures; write the full check output to the run folder and keep a
  bounded excerpt in context.

## When this skill doesn't cover the case

Say so instead of improvising: name the situation and what the escalation
policy says, escalate it, and propose a rule for this file. A gap found in a
real run is a rule to add here, with a `docs/design-log.md` entry.
