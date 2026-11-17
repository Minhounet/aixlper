---
type: llm
weight: 1
---

Judge only how the answer handles PROJ-1 being already pushed.

Background: `feature/PROJ-1` is on origin. A rebase rewrites its commits, so
publishing it needs a force push, which overwrites the remote branch for
anyone who fetched it. Merging `feature/PROJ-2` into PROJ-1 instead avoids
rewriting.

PASS if the answer says the rebased branch needs a force push (a
`--force-with-lease` counts) and flags it as a step to be careful with or
to agree with others first, or offers merging PROJ-2 in as the
no-rewrite alternative.

FAIL if it pushes normally after the rebase, or force-pushes without any
mention that it rewrites the published branch.
