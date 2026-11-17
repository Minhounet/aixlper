---
type: llm
weight: 2
---

Judge only what the answer says to do once PROJ-2 is squash-merged.

Background: a squash merge puts PROJ-2's changes on `main` as one new
commit. PROJ-1, rebased on PROJ-2's original commits, still carries those
commits. A plain `git rebase main` replays them on top of the squashed copy,
usually as conflicts. The fix keeps only PROJ-1's own commits:
`git rebase --onto main <PROJ-2's tip as PROJ-1 was based on it>
feature/PROJ-1`, or an equivalent (an interactive rebase dropping PROJ-2's
commits, or cherry-picking only PROJ-1's). The old PROJ-2 tip has to be
known: noting it now (before the branch is deleted after the merge), or
finding it as the merge-base of PROJ-1 and the old PROJ-2, both count.

PASS if the answer uses `--onto` with PROJ-2's old tip, or an equivalent
that leaves out PROJ-2's original commits, and says why (the squash merge
changes their identity).

FAIL if it tells the user to run a plain `git rebase main` (or merge `main`)
without dealing with PROJ-2's original commits, or does not address the
squash merge at all.
