# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `nuxeo-dev-loop` | **Not run yet.** Written 2026-10-15 from the author's real Podman setup. No score, no baseline, no grader read against real answers. Do not read it as a signal until it has been run. |

## `nuxeo-dev-loop`

A Nuxeo addon on a running Podman stack. The user asks for a dev-deploy
script (the addon gained a third-party dependency) and for how to turn on a
flag with a plan that cannot work. Three traps, each a rule from
`references/nuxeo.md`:

- **Dependency jars** (weight 2): the addon's own jars go to `bundles/`;
  `vavr` goes to `lib/` by an explicit or filtered step. Copying the whole
  dependency set, or a fat jar, breaks the classloader.
- **Config precedence** (weight 2): the user plans to put the flag in
  `conf.d/90-local.conf`, but the key is already in `NUXEOCONF`, which is
  applied last and wins. The fix is to parameterise it in the compose file,
  and the change needs a container recreate, not the script's in-place
  restart.
- **Recreate discards copied jars** (weight 1): once the container is
  recreated, the jars copied earlier are gone, so the script runs after the
  recreate. This one is read from how containers work and from the author's
  scripts; it has not been observed on the real stack.

The prompt names the skill, because a case elsewhere in this repo scored
0.2 until it did. It says the stack follows the usual entrypoint order
(`conf.d` appended, then `NUXEOCONF` applied) without saying which wins,
so the baseline has the same facts the author's colleagues would.

**What this case can and can't show.** The rules come from one setup, so a
good score shows the skill passes that setup's knowledge on, not that the
rules hold for every Nuxeo project. A baseline that knows the `conf.d`
ordering by itself would make the config trap non-discriminating; read the
baseline answers before trusting a delta.

Suggested first run, scoped and capped (about $0.50–0.60 a case on one
model):

```
claude plugin eval skills/tonosaman-deploy --case nuxeo-dev-loop --runs 1 --model sonnet --max-cost-usd 2
```

Then read every answer in full, grader by grader, before raising `--runs`.
