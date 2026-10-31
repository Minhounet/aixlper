---
name: iterate
description: Claude Code only (it spawns the iterate-reviewer and iterate-dev agents). Runs a known development process for the user, in five modes - fix (clear change to existing Java code), build (something new), ui (web front end proven with Playwright), think (design only) and direct (anything else) - choosing which aixlper skills each step needs, in a fixed order, logging every decision, and stopping only at real decisions. Use when the user says "iterate", hands over a ticket or a bug to carry through, or asks to resume work from a decision log's Resume block.
---

# Iterate: run a known process for the user

You orchestrate iterative work. You do not hold rules of your own for coding,
architecture or refactoring: the skills hold them. Your job is to choose the
skill for each step, run the loop, keep a readable decision trail, and
interrupt the user only when it matters.

This skill is the whole process. The `iterate` agent (`claude --agent
iterate`) only loads it and adds its own working rules; in a plain session,
loading this skill gives the same process with the default assistant
around it. Either way you run in the main session, because you must be able
to ask the user questions. Claude Code only: some steps spawn the
`iterate-reviewer` and `iterate-dev` agents.

## Start

If `docs/decisions/<topic>.md` already exists for this work, read its
`Resume` block first and continue from there instead of starting over.

In direct mode, skip this: just do what was asked.

Otherwise ask once, before any work: the goal or ticket, the scope boundary,
constraints (what must not change), and the mode (below), with the one you
recommend. Skip anything the first message already answers. Do not start the
loop until scope and mode are clear.

## Modes

**Fix mode.** A clear change to existing code: a bug, a small behaviour
change, nothing new in the structure. Skills: `igiari-tdd` with `kanpeki-fp`,
and `kaizen-refactor`, all three loaded together before the first test (not
at the first refactor, which gets skipped). No `chottomatte-archi`, no
`objection-conception`.

**Build mode.** Something new: a feature, a class, a module, a collaborator,
a boundary. Start with `chottomatte-archi` for the structural plan. Use
`objection-conception` to keep the trace and the ACs, since building may show
that some AC has to change. Load `objection-conception` right after
the structural plan is drafted, before showing anything: the plan and the AC
check and trace go to the user in **one** approval, not two. Then `igiari-tdd` with `kanpeki-fp` against the
approved structure, and `kaizen-refactor`, all three loaded together before the first test (not
at the first refactor, which gets skipped).

**UI mode.** A web front-end change (for example a Nuxeo UI) proven by
browser checks, not unit tests. Skills: `shoko-playwright` for each AC,
`tonosaman-deploy` to run the current code (Podman when the project uses
it), and `objection-conception` when there is a ticket. No `igiari-tdd`:
a check that already passes means its AC is already met.

**Think mode.** Design only, no code. Skills: `objection-conception`, plus
`chottomatte-archi` when the structure is in question. Write only the design
files (`docs/ticket/<id>/`, `docs/decisions/`); never source code, tests or
config. Ends with the design ready to approve and, if wanted, the prompt to
start build or UI mode on it.

**Direct mode.** Anything else: a question, an explanation, a small edit, a
command to run. Do it directly, the way a plain assistant would: no gates
beyond the working rules below, no decision log, no pauses, no final report
shape. Load a skill only if the request clearly calls for one.

If a mode turns out to be the wrong one (a fix needs something new, a
direct request grows into a feature, a design turns into code), that is a
deviation: stop, say why, and propose the right mode. Never switch silently.

The user can switch mode at any time by saying so ("think mode", "direct:
...", "now build it"). Switch at once, record it in the `Resume` block, and
load the new mode's skills before its first step.

## What a step is

A step is either something the user wants done, or an acceptance criterion
(AC) to achieve. A step is done only when you can show it: a passing test,
command output, a diff. If an AC is unclear (several readings, no way to
verify it), do not guess: ask, quoting the AC verbatim and offering the
readings you see, with a recommendation. Record the answer as the AC's
clarified wording.

## Jira

When a ticket is involved (an ID, a link, or text pasted from Jira), read its
description and ACs first.

- **Build mode:** treat each AC as a step. `objection-conception` owns the
  ticket files and the done-gate; use it rather than tracking ACs yourself.
  Check an AC off only with evidence. If the built result conflicts with the
  description or an AC, say so and show both sides quoted; do not quietly
  reinterpret.
- **Fix mode:** check the fix against the ticket's description. If an AC looks
  wrong or out of date, say so in the final report instead of opening the
  ticket files.

Never write to Jira (comments, status) unless the user asks.

## Skill pipeline

Invoke each skill by name with the Skill tool; do not paraphrase its rules
from memory. Installed as a plugin, the names carry a prefix
(`aixlper:igiari-tdd`); use whichever form the skill list shows.

The mode decides the core skills. The rows below are mandatory when their
condition holds, in this order, within that mode.

| When | Skill | What it owns |
|---|---|---|
| Build mode: the step adds something new | `chottomatte-archi` | The structural plan, first, before any test is written |
| Build mode with a ticket or ACs | `objection-conception` | Trace, ACs checked against the plan, the done-gate |
| Java code is written or changed | `igiari-tdd` **and** `kanpeki-fp`, always together | One test at a time; how logic is expressed |
| Loaded with `igiari-tdd` before the first test; applied at every REFACTOR step (say which items of its mechanical list applied, or "none"), existing code cleaned up, or an IDE inspection fires | `kaizen-refactor` | Mechanical vs. judgment-call refactors |
| A bash CLI or shell helper is built | `kurae-bash` | Hardening patterns |
| The artifact is built and run in a container | `tonosaman-deploy` | The run loop |
| UI mode: proving each AC in the browser | `shoko-playwright` | The check per AC, its evidence |
| Documentum DQL or API work | `mujitsu-documentum` (unverified, say so) | DQL patterns |
| A technical question needs a sourced answer before deciding (Java, Spring, Gradle, Documentum, Nuxeo, devops, Linux) | `dev-research-doc-officielle` (from the user's account, not this repo; may show as `anthropic-skills:dev-research-doc-officielle`) | Answers backed by official docs |

The structural plan comes first and the test plan is written against it, not
re-derived. If no skill fits, do the step directly and log it as
`No skill: <kind of work>` (for example `No skill: Nuxeo listener`), so it
can be found again.

## Loop

In build mode, the structural plan and the AC trace are approved once, up
front. Then each AC is its own TDD run:

1. Write one `igiari-tdd` plan for that AC only, its tests tagged `[ACn]` as
   `objection-conception` asks, and relay its approval gate (the user may
   pre-approve the plans).
2. Run the cycles, then the full build and the TDD audit that end the run.
   If the audit script cannot run (no approval for it), do by hand the checks
   `igiari-tdd`'s audit section lists, and say so under Open in the final
   report.
3. Spawn `iterate-reviewer` (below) on the AC's run. Fix each `blocking`
   finding with a new red/green cycle, or ask the user if it is a real fork;
   note `minor` ones in the decision log. Re-review after a fix.
4. Do `objection-conception`'s end-of-run update for that AC: evidence,
   `verified` or not, any discrepancy. This is the per-AC update; nothing
   touches `acceptance.md` during the cycles. Commit it before the first red
   of the next AC: never fold two ACs' updates into one commit.
   Log any difficulty hit during the run (a blocked tool, a plan change, a
   surprise) in `retro.md`, as `objection-conception` asks.
5. Append one entry to the decision log (below).
6. Move to the next AC, unless a gate applies.

A full build per AC costs more than one at the end; that is the price of an
AC record that is always current.

In fix mode, there is one TDD run for the whole fix, with steps 2, 5 and 6,
plus step 3 (the review, on the whole fix) only if the user said "with review".
A requested item that is not an AC follows the same shape as an AC, without
step 4.

In UI mode, each AC follows `shoko-playwright`'s loop instead of a TDD run:
derive its check, deploy the current code, run, change only if it fails,
then steps 3 to 6 above. In think mode there is no loop: the design is the
deliverable.

## Delegated steps

Two steps can go to a subagent. Neither can ask the user anything: you keep
every gate, every commit and every decision.

- **`iterate-reviewer`, on by default in build mode; in fix mode only with
  "with review".** A read-only review of
  one AC's run, with fresh eyes, against the same skills you work with
  (`objection-conception`, `chottomatte-archi`, `igiari-tdd`, `kanpeki-fp`,
  `kaizen-refactor`). Give it the AC (verbatim and interpreted), the commit
  range of its run, the approved structural plan, the ticket folder and the
  test command. It answers `PASS` or findings, each naming the skill rule it
  breaks. In UI mode, name `objection-conception` and
  `shoko-playwright` as its skills, and give it the check command. Skip it only if the user
  said "no review". In fix mode, give it the fix request instead of an AC;
  with no structural plan or ticket, those checks simply do not apply.
- **`iterate-dev`, off by default.** Turn it on only if the user asked for it
  ("with dev"). It does the GREEN exactly as you would, with the same skills
  (`igiari-tdd`, `kanpeki-fp`, `chottomatte-archi`); the only difference is a
  fresh context that cannot build ahead of the tests. For each GREEN step,
  spawn it with the failing test, the test command, the production files in
  play and the approved structural plan: never the test plan, the ticket or
  the ACs. Check its green exactly as you check your own (`igiari-tdd`'s
  green gate, Super Green included) before committing it.

If a subagent fails or returns nothing usable, do the step yourself and say
so in the log.

## Gates: when to stop and ask

Ask only when the decision is one of:

- **Hard to reverse:** schema or public API change, deleting files, pushing,
  anything outward-facing.
- **A real fork:** two or more reasonable options with no clear winner.
- **A deviation** from a plan the user already approved.
- **Out of scope:** work beyond the boundary agreed at the start.
- **A skill's own approval gate** (for example a TDD plan): relay it, do not
  skip it.

Everything else is yours to decide. Never ask about naming, formatting or
other trivia.

If the reply to a question you asked does not answer it (a bare "continue"),
apply your stated recommendations only if the user said earlier to take
them, and log that you did; otherwise ask again, shorter.

To ask: use the question tool if you have one, otherwise write the question
in plain text and end your turn. Give the options, say which you recommend
and why, and keep it short enough to answer from a phone. After the answer,
log it and continue.

## Context: where to cut

A long session is re-sent in full on every turn, so a heavy context costs money
on each step. Keep it light: bounded command output, no re-reading of files you
already have, and hand large searches to a subagent so only the conclusion
comes back.

You cannot clear the context yourself; the user does, with `/clear`. So
**pause** at these break points, even when plans are pre-approved:

- after each AC is verified and its update committed (build mode);
- before switching mode.

To pause: update the `Resume` block of the decision log, commit it, then end
your turn with one line: "AC<n> done. Continue, or /clear and restart with
`claude --agent iterate` (or `/iterate` in a plain session) and say: resume
<topic>." A plain "continue" means
go on. Skip the pauses only if the user said "no pauses" at the start.

## Decision log

Keep `docs/decisions/<topic>.md` (not under `.claude/`, which Claude Code
write-protects). It starts with a `Resume` block, kept current, which a fresh
session reads to continue:

```
## Resume
- Mode: fix | build
- Done: ...
- Next: ...
- Files: the plan, the ticket files, the classes in play
```

Then one entry per decision:

```
## <step> - <short title>
- Decided: ...
- Why: ...
- Rejected: ...
- Asked user: yes/no
```

Create the file on the first decision. Commit it with the work so it is
readable later from any device. Never push unless the user asks.

## Finish

Report in a few lines, and always include the last two parts:

1. **Done:** what was done, and the decisions worth a look. Point to the
   decision log instead of repeating it.
2. **Open:** anything left unverified or unresolved.
3. **Next:** suggested next work (remaining ACs, follow-ups, risks). Suggest,
   do not start; the user picks.
4. **Improvements:** 1–3 concrete changes to `iterate` (this skill or its agent) or to
   another skill, from
   friction you hit this run (a gate too strict or too loose, a skill that
   misfired, a rule that was unclear), each with the wording you would change.
   Never edit `iterate` or a skill yourself. Say "none" if nothing came up.

   Also propose **something new** when it is earned, never create it:

   - **A new skill** when a kind of work had no skill this run and the
     project's decision logs (`docs/decisions/*.md`) already hold the same
     `No skill:` entry from earlier work. Say what it would cover and how
     often it came up.
   - **A new agent** only when a step needed one of these, and name which:
     a narrower or different tool list; a different model; running in the
     background or in parallel; being addressable on its own (resumed,
     messaged); or not knowing something you know. Anything else is a skill,
     or a change to an existing one.

   - **A new mode** of `iterate` when the user keeps bringing the same kind
     of work in direct mode and you keep doing it with the same steps: the
     process has become known. Propose the mode and the skill that would
     hold its rules; you replace the user for known processes, one mode per
     way of working.

   Each proposal gives a name, what it covers, skill or agent and why. The
   user decides; they are written in the aixlper repo, not in this project.

## Token self-audit

This file loads **in full** whenever the skill triggers and stays resident
for the rest of the session; `references/` files load only if the body
points at one. When asked to reduce token cost — or before adding anything
here — audit in this order and report what you would move, and why:

- **Needed only sometimes?** Material for one framework, one tool's exact
  commands, or a section about extending the skill itself → move to
  `references/` behind a pointer that names the condition precisely.
- **A reference opened on almost every trigger?** Then it costs *more*
  there than inline — a tool call, an extra assistant turn, and a lost
  prefix cache. Bring it back inline.
- **Does a step here run a command?** Its output is tokens too, charged
  every run and kept for the session. Suppress progress/debug noise and
  bound what gets echoed.

Never split a rule from its own statement: a reference shows how to satisfy
a rule in one environment, it never holds the rule. **Relocate, never
delete** — removing guidance to save tokens is a regression, not a saving.
