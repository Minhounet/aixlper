# Proposals: calibration examples and skill improvements

> Reference for the `igiari-tdd` skill. Read when a super-green miss is
> counted, or when you write a "Skill improvement proposal": it holds the
> proposal shape and where proposals are kept.

**Turn each miss into a proposed example — never edit this file
yourself.** For every miss, add this to the end-of-task report:

```
## Calibration example proposal
- Skill: igiari-tdd
- Cycle: green N / refactor N
- Missed item: <the "green owns" item>
- Bad (as committed in green N): <the lines>
- Good (as fixed in refactor N): <the lines>
- Boundary it shows: <why the ladder in SKILL.md didn't already prevent it>
```

The author decides what happens to it: a new ladder rung (it shows a new
boundary), an eval case (it's a repeat), or nothing. Don't add it to the
ladder yourself. The agent that missed is the weakest judge of the fix,
and an unreviewed example quietly becomes a rule.

**Keep the proposals in a file, not only in the report.** At the end of
the task, after the audit, append every calibration example proposal and
every "Skill improvement proposal" (see SKILL.md's last section) to
`.skill-proposals/igiari-tdd.md` at the project root. Create the file if
needed, never overwrite it, and head each entry with the date and the
task. Leave it out of every step commit: whether it's committed, ignored
or deleted is the author's call. A report scrolls away; the file is what
the author reviews later. Nothing to propose → append nothing.

