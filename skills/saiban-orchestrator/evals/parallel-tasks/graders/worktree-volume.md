---
type: llm
weight: 2
---

Judge only how the answer gets PROJ-2's Designer page onto the server.

Background: the Podman volume syncs `~/work/myapp/studio-designer`, the main
folder. Edits in the worktree `~/work/myapp-proj2` never reach the server,
so reloading the page tests PROJ-1's files, not PROJ-2's. To test PROJ-2's
page, its branch must be in the served folder: save PROJ-1's uncommitted
work (a commit, or a stash), check out `feature/PROJ-2` in `~/work/myapp`
(git refuses while the worktree holds that branch, so a detached checkout of
its commit or freeing the worktree also counts), then reload. Changing the
volume to point at the worktree also works, but needs a container recreate,
which must be said. The addon jars, by contrast, can be built in the
worktree and deployed from there.

PASS if the answer says the worktree's Designer edits do not reach the
server (or the served folder is `~/work/myapp`) and gets PROJ-2's page there
by one of the routes above, saving PROJ-1's uncommitted edits first.

FAIL if it expects the worktree's page to show after a reload or after
`dev-deploy.sh`, does not say how the Designer page reaches the server,
or checks out PROJ-2 in the main folder without saving PROJ-1's edits.
