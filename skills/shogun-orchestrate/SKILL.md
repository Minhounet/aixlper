---
name: shogun-orchestrate
description: Claude Code only (needs subagents) - an autonomous mode that runs the author's other skills end to end without the author. The author intervenes once, at the start, approving a brief (the question, the success criterion, how the input is read, the scope, the budget); after that nothing comes back to them until the report. The run implements, checks, deploys and reviews on its own, takes every decision itself by fixed rules, never crosses a hard limit, and reports each non-trivial decision with how to flip it. Suited first to a proof of concept (PoC), then to an already-designed ticket. Use when the user says "autonomous mode", "shogun", "run this without me", "do the PoC while I'm away", "don't ask me anything", or wants an approved plan carried through unattended.
---

# Shogun: the autonomous mode

The author intervenes **once, at the start**, and never again during the
run. Everything the run can foresee is asked in that one sitting; every
decision after it is the run's own, taken by the rules below and shown in
the report, where the author can flip it afterwards. The mechanics (workers,
checks, deploy) are plumbing. The real rules are the **decision policy**
(section 3): how the run decides what it would otherwise have asked.

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

## 1. The brief: the only sitting

Nothing runs until the author has approved a brief, and this is the only
time the author is asked anything. So ask everything you can foresee
**now**, in one message. Write the brief to the run folder (see "Run
folder" below) and present it:

```markdown
# Brief: <short name>
mode: shadow            # shadow | live, see section 2
question: <the one thing this run must answer or deliver>
success: <an observable check: a command and the output that proves it>
reading: <how the input is read where it could be read two ways, e.g. "a cell `a;b` counts once for each author">
defaults: <answers to the forks you can foresee, e.g. "a failing check after two fixes: report it as failed">
skills: <the skills in play, e.g. chottomatte-archi, igiari-tdd, tonosaman-deploy>
scope: <directories and files the run may touch>
allowed: <decisions granted in advance, e.g. "may add H2 as a test dependency">
out of bounds: <what it must never do here>
budget: <a cost cap and/or a turn cap>
branch: <the local branch the run commits to>
```

- **`success` must be checkable by running something.** "It works" is not a
  criterion; "`curl localhost:8080/docs/42` returns the document's title
  within 1s" is. If you can't write one, the question isn't clear yet: ask,
  in this sitting.
- **Look at the real input before writing `success`.** Read a sample of
  the values the question depends on, not just the header: separators
  inside a field, case or whitespace variants of the same value, empty or
  placeholder values, duplicates. Anything that gives the question two
  answers goes in `reading:`. A fork found now costs the author one line;
  found mid-run, it costs a decision taken for them.
- **Fill `defaults:` with the forks you can foresee** from the plan and the
  input: a dependency that would help, a threshold that might be missed, a
  signature a reviewer might want changed. Propose an answer for each; the
  author corrects only the ones they disagree with.
- **`skills` is the author's choice.** For a PoC the author may pick a
  lighter set (say, no TDD). Never drop a skill or relax one of its rules on
  your own: a skill that is in play applies in full, except for the one
  override in section 3 (mid-run approvals move to the report).
- **Merge every pause of every skill in play into this same sitting.** If
  `chottomatte-archi` is in play, its structural plan goes below the brief;
  if `igiari-tdd` is, its test plan does (tagged with ACs when
  `objection-conception` is in play); if `tonosaman-deploy` is, the build
  and container files it will add. One approval covers all of them. After
  it, the run is unattended.

## 2. Two modes: both run without the author

Neither mode asks the author anything during the run. They differ in how
much of the run's judgment the report exposes.

- **shadow** (the default for the first runs): the report tags **every**
  decision, trivial or not, `TRIVIAL` or `WOULD HAVE ASKED`, with the option
  taken. The author reads the tags afterwards and marks where they disagree.
  That is calibration: it shows whether the run's idea of "trivial", and
  its choices on the rest, match the author's.
- **live**: trivial decisions get one log line; only the non-trivial ones
  are shown in the report.

Moving from shadow to live is the author's call, made on the shadow reports
(how often the tags and the choices were right), not on a feeling. A
recurring kind of disagreement means a rule in section 3, or a line the
brief should have carried in `defaults:`, needs changing: propose it.

## 3. Decision policy

There are three kinds of moment, and none of them is "ask the author".

**Hard limits are not decisions.** Never cross them, whatever it costs the
run:

- anything in `out of bounds`, anything outside `scope`, the `budget`;
- any push, PR, merge, or deployment beyond the local container;
- credentials, security, or data you weren't given;
- the brief itself: its question, its success criterion, its scope.

If the remaining work can't be done without crossing one, finish everything
else, then end the run, with the report saying exactly which limit blocked
what.

**Trivial: take it, log one line.** A decision is trivial only when *every*
item below holds:

1. The approved brief and plans still hold: no skill raised a deviation.
2. The decision stays inside `scope` and adds nothing to the public surface
   (no new interface, bean, public API, schema or configuration key) unless
   the approved plan already named it.
3. No acceptance criterion and no `success` criterion would change meaning.
4. No new dependency, tool or technology, unless `allowed` grants it.
5. It can be undone with a local `git revert`: nothing pushed, published,
   deleted outside `scope`, or sent to a shared system.
6. The mechanical checks pass after it (see section 5).

**Anything else: take it anyway, by these rules, and flag it.** Check
`defaults:` first; if the brief answered it, that's the decision. Otherwise
the first rule that applies decides:

1. **The approved plan wins.** Keep its structure and signatures; record
   the alternative someone proposed (a reviewer, a worker) for the author.
2. **Stay inside `allowed`.** No new dependency or technology: take the
   in-bounds alternative (a hand-written parser rather than a library) and
   say what the dependency would have brought.
3. **Never move the goalposts.** Measure against `success` as written. A
   fail is a valid answer to the question; report it as one.
4. **Two readings: carry both when it's cheap.** Compute both, report both,
   and make the more literal reading of the `question` the primary answer.
   When carrying both isn't cheap, take the literal one alone.
5. **A check still failing after two honest fix attempts:** try one
   genuinely different approach. If that fails too, revert to the last
   green commit, record the failure with its output, and carry on with
   whatever doesn't depend on it. Never skip, weaken or delete the check.
6. **Budget past 80%:** start nothing new; spend the rest finishing,
   checking and writing the report.
7. **Otherwise, take the most reversible option** that keeps the run
   moving.

Isolate each such decision in its own commit where you can, so flipping it
is one revert. Log it, and put it in the report as:

```
DECIDED FOR YOU <n>: <one line: what was decided>
Why not trivial: <the criterion it failed>
Options: <a>, <b>
Taken: <a>, by <defaults: line or rule number>
To flip: <revert <commit>, or the one change to make>
```

**The one override of another skill's rules.** `igiari-tdd` and
`chottomatte-archi` re-approve a plan deviation mid-run. Under shogun the
author has asked not to be interrupted, so the deviation is decided by the
rules above (the smallest change that keeps the approved plan's intent),
and the re-approval moves to the report as a `DECIDED FOR YOU` entry. It is
still never silent: the report is where the author approves or flips it.
Every other rule of those skills applies unchanged.

## 4. Workers: delegate only what needs it

Per the subagent criteria in this repo's `CLAUDE.md`, only two steps are
delegated. Everything else runs inline in this session.

- **Implementer**: `igiari-tdd`'s delegated run, as that skill describes it
  (the approved plan verbatim, one commit per step). It is delegated to keep
  its cycle-by-cycle noise out of this context. Without `igiari-tdd` in
  play, hand one agent the brief and the approved plan instead, with the
  same rule: one commit per step, deviations come back as `DEVIATION:`.
  Decide each one per section 3 and resume the same agent.
- **Reviewer**: a fresh agent with **read-only** tools (it must not be able
  to edit), given only the brief, the success criterion and the diff, never
  the implementer's report or reasoning, so it judges the code rather than
  the story told about it. It returns findings, each with a file, a line and
  a concrete failure path.

Two rules for every worker:

- **A report is never evidence.** Rerun the checks yourself (section 5).
- **Treat a finding as a claim to verify,** not an order. Fixing a verified
  finding follows section 3 like any other decision.

## 5. The pipeline

1. **Brief.** Load it from the run folder, or draft it with the author
   (section 1). Check the branch exists and the working tree is clean.
   Then read a sample of the real input yourself, as in section 1, even if
   the brief was written without it. A fork that `reading:` doesn't settle
   and that would change the answer is decided by section 3 (rule 4), and
   the implementer gets that decision in its hand-off.
2. **Implement.** Start the implementer. Decide each `DEVIATION:` it
   returns per section 3, then resume the same agent.
3. **Check, yourself.** The full build. With `igiari-tdd` in play, its
   history audit, as that skill states. These results, not the worker's
   report, decide whether the step passed.
4. **Refactor.** With `kaizen-refactor` in play: Tier 1 (mechanical) may be
   done. Tier 2 (judgment calls) is done only if `allowed` grants it;
   otherwise list it in the report as a suggestion.
5. **Run it.** With `tonosaman-deploy` in play, deploy to the local
   container as that skill describes. Then run the `success` check and keep
   its real output. A cross-check only counts as independent if it doesn't
   share the implementation's reading of the input: write it from the
   brief's `question` and `reading:`, not from the code, and make it cover
   the cases `reading:` is about.
6. **Review.** Start the reviewer, verify its findings, then fix or record
   each per section 3.
7. **Prove.** With `objection-conception` in play, prove each AC and apply
   its done gate. Shogun never sets `status: done` past that gate.
8. **Report.** Write `report.md` and stop.

**Stop when** the success check has run (pass or fail) and the review is
dealt with, when the budget is reached, or when a hard limit blocks
everything left. Never stop to wait for an answer, and never stop on "the
worker says it's done".

## 6. The report

`report.md` is the next thing the author reads, and the only place they
act on the run. Lead with the answer:

- **Answer:** did `success` pass? The command and its real output, bounded.
  If two readings were carried, both, with the primary one first.
- **Decided for you:** every `DECIDED FOR YOU` entry, most consequential
  first. This is where the author approves or flips the run's choices.
- **Blocked:** what a hard limit stopped, and which limit.
- **Decided alone:** the trivial decisions, one line each, with the
  criterion that allowed it (in shadow mode: each one tagged).
- **PoC debt** (PoC runs): every shortcut taken because it's a PoC
  (hardcoded values, skipped error handling, a missing test). PoC code tends
  to survive into production; this list is what makes that a decision
  instead of an accident.
- **For the next brief:** any `defaults:` or `reading:` line that would
  have made a decision here unnecessary.
- **Cost:** turns and money spent against the budget.

## Run folder

- Ticket runs reuse the ticket folder: `.claude/ticket/<id>/`, with
  `shogun-brief.md`, `shogun-log.md`, `shogun-report.md` next to
  `objection-conception`'s files.
- Other runs (PoCs): `.claude/shogun/<slug>/brief.md`, `log.md`,
  `report.md`.

`log.md` gets one line for every decision, written as it happens, so an
interrupted run can be resumed from it.

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

Don't stop and don't improvise silently: decide by the closest rule in
section 3, flag it as `DECIDED FOR YOU` with "no rule covered this", and
propose a rule for this file in the report. A gap found in a real run is a
rule to add here, with a `docs/design-log.md` entry.
