# Two tasks at once: one running server

Read this when the user works a second task while another is open (a second
ticket, a bug in the middle of a feature), or resumes a log whose `Resume`
block has a non-empty `Not on server` line.

The rule it applies is in `SKILL.md` ("Two tasks, one server"): the local
server runs one version of the code at a time, so every check must say
which code it ran against, and a task written away from the server keeps
the list of what was never run there.

## Where each task lives

- **Task A** (the one already running) stays in the main folder, the one
  the server serves. In UI mode on a volume-synced stack, that is the only
  folder the server sees.
- **Task B** (the parallel one) gets its own branch and, for fix and build,
  its own git worktree. Code and unit tests (the TDD loop) need no server,
  so most of B is done there without touching A.
- Each task has its own decision log. B's code never lives only in a
  working copy or a `git stash`: commit it on its branch (a WIP commit is
  fine) before every switch.

## Not forgetting what was never run on the server

In B's `Resume` block, `Not on server` lists each AC done and unit-tested
but never checked on the running app. Add an AC when its TDD run ends away
from the server; remove it only when a check ran against B's deployed code.
The recap at start shows the count, so it cannot be forgotten.

## The test slot: checking B, then giving the server back to A

1. **Commit A** (WIP is fine) and note in A's log that the server is lent.
2. **Put B on the server**, the way the change reaches it:
   - **Addon jars** (`tonosaman-deploy`'s copy-and-restart loop): build in
     B's worktree and run the deploy from there. The deploy does not care
     which folder the build came from.
   - **Volume-synced files** (Studio Designer): a worktree's edits never
     reach the server. Check out B's branch in the main folder instead.
   - **Studio Modeler**: one Studio project serves both tasks. Ask the user
     whether A's Modeler changes conflict with B's before any hot reload.
   - Something that needs a recreate or restart: ask first if another
     session may be checking A (UI mode's rule).
3. **Confirm what runs** before trusting a check: the branch or commit
   deployed, read from the deploy itself (jar build time, branch of the
   served folder), not from memory.
4. **Run B's checks**, record each result in B's log, update `Not on server`.
5. **Give the server back**: redeploy A (or check out A's branch in the main
   folder), confirm what runs, and note it in A's log. Until then, every
   check of A tests B's code.

A second full stack (other ports, other volumes) avoids the swap but costs a
whole Nuxeo, database and search; propose it only if the user swaps often.
