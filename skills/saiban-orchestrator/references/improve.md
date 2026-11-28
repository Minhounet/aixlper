# Improve mode: change the skills and agents from how they were used

Read this when `saiban-orchestrator` runs in improve mode: the user asks to improve the
skills or agents, to act on the "Improvements" of earlier reports, or to
look back at a run and fix what rubbed, or to feed the skills from code
worth learning from (`Seen:` entries, or code the user points to), or from
another team's skills (external skills).

Improve mode is the only mode that edits the aixlper skills and agents. It
turns the proposals other modes only write down (the final report's
"Improvements", `No skill:` entries, process notes) into reviewed edits in the
author's aixlper clone.

No decision log in this mode: the clone's `docs/design-log.md` is the
record, one entry per accepted change. No pauses beyond the gate in step 5.

## 1. Find the clone, before anything else

The skills and agents are edited where they live, never in the installed
copy. Resolve the links:

- `readlink -f ~/.claude/skills/saiban-orchestrator` ends in `<clone>/skills/saiban-orchestrator`;
  `<clone>` is two levels up. Check it has `CLAUDE.md` and `skills/`.
- Agents: `readlink -f ~/.claude/agents/saiban-orchestrator.md` ends in
  `<clone>/global/agents/saiban-orchestrator.md`.

If either is a plain file or directory (installed by copy, or as a plugin),
there is nothing safe to edit: the next install overwrites a copy. Say so,
do the inspection anyway, and at the end print the approved changes as a
patch for the user to apply in their clone. Point to
`./scripts/install.sh --link` for next time.

The clone is its own repository with its own `CLAUDE.md`. Read it now: its
rules govern every edit below (commit format, design log, what must not be
removed), not the current project's.

## 2. Agree the scope

Ask once, with a recommendation: all skills and agents, or named ones; which
evidence (this session only, or the project's history too). Skip what the
first message already says. For exemplar code: which `Seen:` entries
(all not yet harvested, by default) and any file or snippet the user points
to; for code outside the project, ask where it comes from and whether it may
be read. For external skills: which ones (the entries of
`~/.claude/external-skills.md`, or a path the user gives), and whether they
may be read.

## 3. Inspect: spawn `tantei-inspector`

The inspection goes to `tantei-inspector`, a read-only helper. Three reasons,
each one of the repo's criteria for an agent: it must not write; it must
not know the working session's reasons for what it did, so it judges the
run against the text as written instead of against the excuses; and it reads
long transcripts whose bulk should not enter this context.

Give it: the path of this file, the clone path, the scope, and the evidence
paths that exist (check each before listing it):

- `docs/decisions/*.md` in the project: `No skill:` entries, deviations,
  gates the user answered, takeovers.
- `docs/ticket/*/retro.md`: difficulties logged during runs.
- the `Improvements:` lines in those decision logs, and final reports'
  "Improvements" the user saved or pasted.
- `~/.claude/process-notes.md`: processes done by hand, repeated.
- the session transcripts, `~/.claude/projects/<project dir>/*.jsonl` (the
  newest first, the current one included when the user asks about this
  session). `global/cycle-cost.py` in the clone shows how they are laid out.
- exemplar code: the `Seen:` lines in those decision logs and in
  `process-notes.md`, and the files the user pointed to. Give the paths and
  line ranges, not your opinion of the code.
- external skills: the path of each one's `SKILL.md` (and its references),
  and the aixlper skill it overlaps, if any.

Do not tell it what you think went wrong. That is the point of a fresh
context.

If it fails or returns nothing usable, say so and stop: doing the
inspection yourself would bring back exactly the bias it exists to avoid.

## 4. What the inspector checks

This section is the inspector's checklist (`tantei-inspector` reads it here).

Load each skill and agent in scope as written (read the files in the clone,
not a memory of them). Then look in the evidence for:

1. **A rule that was broken and nobody noticed**, or broken by the review
   too. Usually the rule is unclear or in the wrong place: propose clearer
   wording or a better place, not a louder version.
2. **A rule that caused friction**: a gate asked for a decision that wasn't
   the user's, a pause nobody needed, a step done twice, a skill loaded too
   late (or not at all) for the step that needed it.
3. **A gap**: the same `No skill:` entry, or the same note in
   `process-notes.md`, at least twice. Propose a skill, a mode of `saiban-orchestrator`,
   or a helper agent, by the repo's own criteria; for an agent, name the
   criterion it meets.
4. **A contradiction** between two skills, or between an agent and the
   skill it loads (an agent restating a rule in its own words counts).
5. **Token waste**: output not bounded, a reference opened on almost every
   trigger, a `SKILL.md` past ~20KB. Use each skill's own "Token self-audit".
6. **Exemplar code** (only when given): read the code, then state the
   pattern apart from it, in a skill's own terms. Then one of: a skill that
   should hold it (a missing rule, example or reference); a rule it
   contradicts, quoted verbatim on both sides (the author decides, never you);
   or no skill covers it (a new skill, by the repo's skill-vs-agent check).
   Already said by a skill, or good only for that codebase: drop it and say
   so. Two guards on every proposal from code:
   - **The shape, never the code.** The clone is public: the proposed wording
     is written fresh, with `com.example.*` / `PROJ-1234` placeholders, no
     internal name, host or ticket ID, no copied block.
   - **Observed, not proven.** Mark it as seen in one codebase. A change to a
     core rule of `igiari-tdd` or `chottomatte-archi` says which kata or eval
     would prove it before it counts as settled.
7. **External skills** (only when given): compare each with the aixlper
   skill covering the same work, rule by rule. Propose only what the
   aixlper skill lacks and that holds beyond that team (a practice, not
   their convention), in the aixlper skill's own terms; or a contradiction,
   quoted verbatim on both sides, for the author to decide. What aixlper
   already says, or a company convention: drop it and say so. Item 6's two
   guards apply, and more strictly: another team's skill is usually not
   public, so its name, wording and examples never reach the clone; the
   evidence line names it only as "an external skill".

Only what the evidence shows. No style opinions, no rewrite of a skill that
worked, and never a proposal to delete a section: name the problem and let
the author decide.

Report each proposal in this shape, most useful first, at most 7:

```
P<n>: <file in the clone> - <clarify | move | add | new skill | new mode | new agent (criterion)>
Evidence: <file> "<short verbatim quote>"; a transcript quote also names the session and date; exemplar code gives <path>:<lines> instead of a quote
Problem: <one or two lines>
Change: <the exact old wording> -> <the exact new wording>
Log: <one line for docs/design-log.md>
```

The quote is the evidence: anyone can find it again. Add a line number only
when it comes from reading that one file (`grep -n` on it alone); a number
counted across several files read together points to no file.

If nothing holds up, say `No proposals` and what you looked at.

## 5. Gate: the author approves each proposal

Show the proposals as they came back, each with your one-line opinion where
you disagree (say why). Ask in one question: accept, reject or change, per
proposal. A new skill, mode or agent is always its own decision, never
bundled. Nothing is edited before the answer.

## 6. Apply in the clone

For each accepted proposal, in the clone:

1. Make the change exactly as approved. If it no longer fits the file (it
   moved since), show the new placement and ask again; never improvise.
2. Add the design-log entry the clone's `CLAUDE.md` asks for: what changed,
   the evidence, and the reasoning. For exemplar code, the evidence is
   genericized like the change ("a Nuxeo listener in a client project"), and
   the entry says "observed, not proven".
3. Run its checks (`make validate`).
4. Commit in the clone with its commit format, one commit per proposal or
   one for the batch, as the user prefers; report each message. Never push
   unless asked.

Never commit to the current project in this mode, and never change a file
outside the clone.

Say what takes effect when: a changed skill applies the next time it loads,
not in this session, which still holds the old text; a changed agent applies
to the next session started with it.
