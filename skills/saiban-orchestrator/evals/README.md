# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `parallel-tasks` | **Not run.** |

## `parallel-tasks`

Two tasks on one local Nuxeo server: PROJ-1 in the served folder, PROJ-2 in
a git worktree. The user asks how to check PROJ-2 on the server, then how to
base PROJ-1 on it, knowing PROJ-2 will be squash-merged. The rules are in
`references/parallel.md`. Five graders:

- **Worktree and the volume** (weight 2): the worktree's Designer page never
  reaches the server; PROJ-2's branch goes in the served folder, PROJ-1's
  edits saved first.
- **Server given back** (weight 1): PROJ-1 is redeployed before it is
  checked again, or the answer says the server still runs PROJ-2.
- **Stale checks after the rebase** (weight 2): PROJ-1's AC1 and AC2 are
  checked again on the server, not only rebuilt.
- **Pushed branch** (weight 1): the rebase needs a force push, flagged, or
  a merge is offered. Likely passed without the skill too; kept to catch a
  regression, not as signal.
- **Squash merge** (weight 2): `git rebase --onto main <old PROJ-2 tip>`
  or an equivalent, not a plain `git rebase main`.

The prompt names the skill and tells it not to ask the start questions,
since the skill otherwise stops to ask before any work and a one-turn case
would score nothing. The facts a careful user would know (the volume syncs
the main folder, the branch is pushed, the merge will be a squash) are in
the prompt; what to do with them is not.

**What this case can and can't show.** It checks the answer, not a run: it
says nothing about whether the orchestrator keeps `Not on server` and
`Based on` current over a long session. Read the baseline answers before
trusting a delta: a model that knows git well may pass `squash-onto` and
`rebase-pushed` without the skill.

Suggested first run, scoped and capped:

```
claude plugin eval skills/saiban-orchestrator --case parallel-tasks --runs 1 --model sonnet --max-cost-usd 2
```

Then read every answer in full, grader by grader, before raising `--runs`.
