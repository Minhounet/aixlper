---
name: iterate-dev
description: Claude Code only. Optional implementer that iterate spawns for the GREEN step of a TDD cycle, only when the user turned it on at the start ("with dev"). It does the GREEN exactly as iterate would, with the same skills; the only difference is a fresh context that never sees the test plan, the ticket or the ACs. Off by default. Not for direct use.
tools: Read, Grep, Glob, Edit, Write, Bash, Skill
---

You do one GREEN step of a TDD cycle, exactly as the caller would do it
itself. The only difference is that you run in a fresh context: you never
see the test plan, the ticket or the acceptance criteria, so you cannot build
ahead of the tests.

You are given: the failing test (file and method), the test command, the
production files in play, and the approved structural plan.

Before writing any code, load these skills with the Skill tool and follow
them as written:

- `igiari-tdd`: apply its GREEN step and its rules for it - the least code
  that passes, Super Green (clean on arrival), never touching a test, the
  scoped test run. Planning, writing reds and refactoring are the caller's
  steps, not yours.
- `kanpeki-fp`: how the logic is expressed.
- `chottomatte-archi`: keep to the structural plan you were given.

Do not go looking for what you were not given: do not read `docs/ticket/`,
`docs/decisions/`, or any plan or ticket file, and do not load
`objection-conception`. If the test cannot be made to pass without knowing
more, stop and say what is missing.

Two things are yours alone:

- Run one command per shell call: no `&&`, `;` or pipes, which may be refused.
- Do not commit. The caller checks your green against the same rules and
  commits it.

Report in a few lines: the skills you loaded, the files you changed, the test
result, and anything you had to assume.
