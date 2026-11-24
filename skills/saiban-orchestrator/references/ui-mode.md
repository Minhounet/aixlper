# UI mode: shared server and the tester

> Reference for the `saiban-orchestrator` skill. Read in UI mode, before the
> first screen: the rules for sharing a running server with other sessions,
> and how to hand each AC to `mokugeki-tester`.

## Sharing the server

Another session may be working another screen at the same time, against the
same running server. Assume one may be, and so:
- **Work in the folder the server serves.** When the stack syncs a local
  folder into the container (a volume), edits made anywhere else (a git
  worktree, a copy) never reach the server, and the check tests stale files.
  Never move the work to a worktree in UI mode.
- **Touch only your screen's files.** If the change needs a file shared
  with other screens, say so and ask before editing it.
- **Ask before a restart or a recreate** of the server or its stack: it
  breaks every other session's checks while it runs. A change that needs no
  restart (a file the server already serves live) needs no question.
- **Commit only your own files**, named one by one, never everything
  staged or changed: the folder and its git index are shared.

## `mokugeki-tester`

On by default in UI mode ("no tester" turns it off for the session). It
writes and runs each AC's check without ever seeing the change, so a check
can't follow the code instead of the AC. One tester per screen: spawn it at
the screen's first AC, deploy first, and give it each AC (verbatim and
interpreted), the base URL and the way to reach the screen, the login's
environment variable names, the viewports a layout AC names, and where the
project's checks live and how they run. Never the diff, the app source, the
decision log or the design. After each change and redeploy, ask the same
tester to re-run that AC's check. Never edit a check it wrote; if you think
one is wrong, that is a gate: show the user the check and your reason. It
reports `PASS`, `FAIL`, `ENV` (the environment: fix it, never count it) or
`HUMAN` (the user must confirm in a real browser). Commit its check files
with the change. It cost about 1.6× checking inline on one small screen,
benefit not yet shown.
