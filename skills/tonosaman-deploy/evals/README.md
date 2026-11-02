# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `nuxeo-dev-loop` | **Moderate, and sensitive to the prompt's wording.** 1.00 with the skill vs 0.69 without (Δ +0.31, Sonnet, 5+5 runs, $0.96, 2026-10-15, neutral wording). With a wording that asks "whether my plan works" the gap shrank to +0.06. Only the `NUXEOCONF` precedence rule separates the arms clearly. See below. |

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

**What would make the case sharper:** a second key, so a baseline that
learned the order from the first still has to apply it. That was done; see
the next section.

### 2026-10-15 sharpened case: a second key, `--runs 5`, Sonnet

The prompt now asks for two settings. `myapp.sync.enabled` is in
`NUXEOCONF` (the plan fails). `myapp.audit.verbose` is not (the `conf.d`
plan works once the container is recreated). A new grader, `add-is-allowed`
(weight 2), checks that the answer treats them differently. Two runs, 5 per
arm each, $1.19 and $0.96:

| Prompt's last line | With skill | Without | Δ |
|---|---|---|---|
| "tell me for each setting **whether my plan works**, what to do instead if it doesn't" | 1.00 | 0.94 | +0.06 |
| "tell me **how to switch both settings on** and what to run, in which order" | 1.00 | 0.69 | +0.31 |

**The wording matters more than the second key.** Asking "whether my plan
works" prompts the baseline to doubt the plan. In all five no-skill answers
it hedged ("I can't tell which is applied last") and then took the safe
route anyway: an uncommitted compose override, and a recreate. With the
neutral ask, the baseline mostly did not doubt it. The skill's value, on this
model, is that it *volunteers* the suspicion and states the order as a fact.
The nudged wording was my addition and made the case look weaker than it is;
the neutral wording is the one kept in `prompt.md`.

Neutral-wording run, per grader (judge votes, 5 runs per arm):

| Grader | With skill | Without |
|---|---|---|
| `config-precedence` (2) | 5/5 pass | 1/5 pass |
| `add-is-allowed` (2) | 5/5 pass | 4/5 pass |
| `dependency-jars` (2) | 5/5 pass | 5/5 pass |
| `recreate-discards-jars` (1) | 5/5 pass | 4/5 pass |

What the no-skill failures were, from reading the answers:
- Runs 1, 2 and 5 told the user to add `myapp.sync.enabled=true` to
  `90-local.conf` and run the script, or to try that first. Runs 2 and 5
  said the script's restart re-reads `conf.d`. The author's setup says it
  does not: `conf.d` is read when the container is recreated.
- Run 4 pointed to the override file but its steps contradict one another
  (one judge passed it, two failed it).
- Run 5 also said the copied jars survive "a restart" and, if the container
  is recreated, to rerun the script. It put the config edit before the
  script and called the recreate optional, which the recreate grader failed
  on a 2–1 vote.

**One failure is arguable.** In run 3 the no-skill answer wrote "`myapp.audit.
verbose` isn't in `NUXEOCONF`, so that line would work", then used one
compose override for both keys. The `add-is-allowed` grader failed it
unanimously, though its own PASS clause allows that. The grader text is now
clearer. The numbers above were scored with the earlier text. Scoring run 3
as a pass would put the no-skill mean near 0.74 and Δ near +0.26. The case
has not been re-run since the edit.

**What the prompt leaks.** It says the entrypoint "appends the files in
`conf.d`, and also applies the `NUXEOCONF` JSON". One no-skill answer (run 3)
read that as "conf.d, then `NUXEOCONF`" and stated the order as fact. The
order is the thing under test, so a stricter version would drop "also" or
reorder the sentence.

**Cost so far:** $0.15 + $1.19 + $0.96 = $2.30 for three runs of this case,
all on Sonnet. Nothing has been run on Opus.
