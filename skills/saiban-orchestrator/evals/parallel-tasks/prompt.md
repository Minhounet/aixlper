---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Use your saiban-orchestrator skill for this. Don't run anything and don't
ask me the start questions: I only want the exact steps, in order.

Setup: one git repo, `~/work/myapp`. It holds a Nuxeo addon (`myapp-core`,
Maven) and our Studio Designer files (`studio-designer/`). Nuxeo runs
locally in Podman with podman-compose, with Postgres, Kafka and OpenSearch
that take minutes to start. A Podman volume syncs
`~/work/myapp/studio-designer` into the Nuxeo container, so a Designer edit
is live after a page reload. Addon changes go in with `./dev-deploy.sh`,
which builds `myapp-core`, copies its jars into the running container and
restarts only Nuxeo.

I work in `~/work/myapp` on PROJ-1 (branch `feature/PROJ-1`, already pushed
to origin, some uncommitted edits right now). Its AC1 and AC2 were checked
on my local Nuxeo yesterday and pass.

In parallel I started PROJ-2 in a git worktree, `~/work/myapp-proj2`, on
branch `feature/PROJ-2`. There I wrote a new Designer page
(`studio-designer/pages/invoice-list.html`) and a change in `myapp-core`.
Its unit tests pass. It has never run in Nuxeo.

1. How do I check PROJ-2's two ACs on my local Nuxeo, and then keep going
   on PROJ-1?
2. Say PROJ-2 is good. I want to rebase PROJ-1 onto PROJ-2 and continue
   PROJ-1 on top of it. PROJ-2 will be squash-merged into `main` by the
   reviewer next week, and PROJ-1 goes to `main` after that. What do I do
   now, and what do I do once PROJ-2 is merged?
