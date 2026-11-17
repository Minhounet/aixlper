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
     Git refuses a branch another worktree holds: check out its commit
     detached (`git checkout --detach <B>`), or remove B's worktree first.
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

## Testing both together

Each task's own checks say "A works alone". To also know "A works with B":

1. Commit A and B on their branches.
2. Make a throwaway branch from A and merge B into it
   (`git checkout -b try/<A>+<B> <A>`, `git merge --no-ff <B>`).
3. Deploy it as in the test slot (jars copied in, or the branch checked out
   in the served folder for Studio Designer), and confirm what runs.
4. Run **both** tasks' checks: the point is what one breaks in the other.
5. Delete the throwaway branch and give the server back.

- **Never fix on the throwaway branch.** A conflict or a break is fixed on
  the branch that owns it, then merged again; a fix only on `try/...` is
  lost with it.
- **Record the result in both logs with both commits** ("together with B:
  A at `abc123` + B at `def456`, all pass"). A later commit on either side
  makes it stale.
- It does not clear `Not on server`: "alone" and "together" are two results.
- Studio Modeler is one shared project, so the server is always "together"
  for it: nothing to merge.
- Whichever reaches the main branch second is rebased on it and checked
  again; the combined test predicts that, it doesn't prove it.

## Basing A on B (rebase)

When B is done and A should build on it (`git rebase <B>` from A's branch):

- **Ask first if A was pushed.** A rebase rewrites A's commits, and
  publishing it needs a force push: a hard-to-reverse step, asked even in
  yolo. Merging B into A instead avoids that; offer it.
- **Conflicts are resolved in A's commits**: they belong to A, not B.
- **A now depends on B.** Write it in A's `Resume` block (`Based on: B at
  <commit>`). A can't reach the main branch before B; its review shows B's
  commits too until B is merged.
- **Every check of A is stale.** Run the full build and unit tests, then
  put A's ACs back in `Not on server` until their checks run again on the
  deployed rebased code. B's checks run with them: the server now runs B.
- **When B moves again**, rebase A again. When B reaches the main branch,
  rebase A onto it: `git rebase --onto <main> <B's commit from Based on> <A>`
  keeps only A's commits (needed when B was squash-merged, or B's commits
  come back twice; the recorded commit still works once B's branch is
  deleted), then remove `Based on` from the `Resume` block.
- The served folder: a rebase in the main folder is live at once for
  volume-synced files; jars need a redeploy.
