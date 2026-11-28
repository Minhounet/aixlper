# Contribute mode: write a neutral version of an aixlper skill for another repo

Read this when `saiban-orchestrator` runs in contribute mode: the user asks
to contribute an aixlper skill or agent to another skill repository (a team
or company one), to "port", "share" or "export" it.

The goal is a skill the other team can use as their own: good practice
that holds whatever the developer's taste, not the author's way of
developing. What the author believes but others reasonably don't is left
out, or offered as an option the project turns on.

No decision log in this mode: the target repository's history is the
record. No pauses beyond the gates in steps 2 and 4.

## 1. Find both repositories

- The aixlper clone, as in `improve.md` step 1 (read only here: this mode
  never edits it).
- The target: ask for its local path once. Read its `CLAUDE.md`,
  `CONTRIBUTING`, README and two of its existing skills: its format
  (frontmatter keys, folder layout, which clients), naming, language and
  review process govern what you write, not aixlper's.

## 2. Agree the scope, and look for overlap first

Ask once, with a recommendation: which aixlper skills or agents. Then list
the target's skills whose description overlaps each one. An overlap changes
the job: the contribution becomes a proposal to that skill (what it lacks,
in its own terms), not a second skill competing for the same trigger. Show
the overlaps and ask: new skill, addition to the existing one, or drop.

## 3. Classify: spawn `tantei-inspector`

The author's own session can't sort the author's opinions from common
practice: it shares the reasons behind them. The sorting goes to
`tantei-inspector`, read-only and fresh (criteria 1 and 5). Give it this
file's path, the aixlper clone path, the skills in scope, the target path,
and the overlapping target skills. Not your view of what is opinion.

If it fails or returns nothing usable, say so and stop, as in improve mode.

## 4. What the inspector checks (contribute mode)

Read each skill in scope from the clone, and the target's overlapping
skills. Sort every rule (a rule, a gate, a checklist item, an example) into
one class:

- **practice**: widely held, and a project wouldn't argue with it (a
  failing test before a fix; one check per acceptance criterion; bound a
  command's output). Name a public source or a mainstream convention when
  one exists; "the author says so" doesn't count.
- **opinion**: a style or design choice reasonable teams make differently
  (a library, functional vs. imperative, interfaces everywhere, step size).
  Kept only as an option: "if the project uses X, ...".
- **aixlper-only**: theme names, banners, the court, aixlper paths, the
  decision-log format, coupling to another aixlper skill or agent. Dropped,
  or translated to a neutral term when the rule under it is practice.
- **project-specific**: a framework, vendor or environment the target
  doesn't use. Dropped, or kept as a reference if the target uses it.
- **already there**: the target says it already. Dropped; quote where.

Report in this shape, one table per skill, then at most 5 notes:

```
<aixlper skill> -> <proposed neutral name> (<new | addition to <target skill>>)
| # | Rule (short verbatim quote) | Class | Why (source, or the reasonable alternative) |
Note: <a rule that is practice but is worded as the author's taste, and the neutral wording>
```

Never judge whether a rule is good: only whether it is shared. Never
propose deleting anything in the aixlper clone.

## 5. Gate: the author approves the classification

Show the tables as they came back, with your one-line disagreement where
you have one. Ask once: accept, or move rows between classes. Nothing is
written before the answer.

## 6. Write in the target

For each skill, on a new branch in the target:

1. Name it by what it does, in the target's naming (no theme names).
2. Keep **practice** rows, rewritten in the target's voice and format.
   **Opinion** rows only as options, grouped under one heading the target's
   reader can skip. Nothing else.
3. Start the body with: follow the project's own conventions (its
   instructions file, the style of the code around the change); this skill
   applies where they are silent.
4. No reference to an aixlper skill, agent or path, unless that one is
   contributed in the same batch.
5. Run the target's own checks; commit in its format; report each message.
   Never push, never open a merge request unless asked.

The direction is one-way: nothing from the target goes back into the clone
in this mode. Learning from the target's skills is improve mode
(`improve.md`, item 7).

End with: what was written, where, the rows left out and why, and, for
each contributed skill, a proposed entry for `~/.claude/external-skills.md`
(`references/external-skills.md`), so the team's version can reinforce
the pipeline in their projects. The user writes it; you don't.
