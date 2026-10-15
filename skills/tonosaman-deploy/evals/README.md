# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `nuxeo-dev-loop` | **Moderate, one trap discriminates.** 1.00 with the skill vs 0.60 without (Δ +0.40, Sonnet, 1+1 run, $0.15, 2026-10-15). Only `config-precedence` separated the arms, and its judges split 2–1 against the baseline. See below. |

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

### 2026-10-15 first run: Sonnet, `--runs 1`, ablation on

`claude plugin eval skills/tonosaman-deploy --case nuxeo-dev-loop --runs 1
--model sonnet`, $0.15 total. The answers were read in full.

| Grader | With skill | Without skill |
|---|---|---|
| `config-precedence` (2) | PASS PASS PASS | FAIL PASS FAIL |
| `dependency-jars` (2) | PASS PASS PASS | PASS PASS PASS |
| `recreate-discards-jars` (1) | PASS PASS PASS | PASS PASS PASS |

- **With the skill** stated the `conf.d` then `NUXEOCONF` order as fact, made
  the key a `${VAR:-false}` in `NUXEOCONF` with a gitignored `.env`, and
  ordered the steps recreate, then script. It built an explicit
  `vavr,vavr-match` list, bounded the readiness wait, and said none of it was
  run.
- **Without the skill** (it reported that no such skill exists, so the arm
  really was bare) did not claim the `conf.d` plan would work. It said it
  couldn't tell which of the two is applied last, proposed restating the
  whole JSON in an uncommitted compose override, and said the change needs a
  recreate. It also suggested trying the `conf.d` plan first because that
  "only needs a restart". That last suggestion is what two judges failed.
  The split vote is a fair reading of a hedged answer, not a clear miss.
- **The other two traps did not discriminate.** The baseline filtered the
  dependency copy to `io.vavr` (so `vavr-match` came along) and kept the
  `lib/` and `bundles/` split. It also said a recreate loses the copied jars
  and ran the script second. Both are regression checks on this model.

So the measured skill effect is one fact: the order in which the image
applies `conf.d` and `NUXEOCONF`. That fact comes from the author's setup
comment, and the prompt withholds it on purpose. One sample per arm and a
2–1 vote is thin. Do not read +0.40 as a stable number.

**What would make the case sharper**, not done yet:
- Drop the `-DskipTests` and readiness details nobody grades, and add a
  trap the baseline cannot reason out: a second `NUXEOCONF` key the user
  wants to change, so a baseline that learned the order from the first
  still has to apply it.
- Run `--runs 5` on Sonnet, and once on Opus, only after that.
