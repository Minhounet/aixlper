# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## Case strength

| Case | Signal |
|---|---|
| `finding-is-not-a-prescription` | **Clean, but not discriminating.** 1.00 with and without the skill (Sonnet, 1+1 run, judges unanimous, 2026-10-03). |
| `characterize-current-behavior` | **Clean, but not discriminating** on score; the with-skill run did delegate to a subagent (see below). |

## `finding-is-not-a-prescription`

An inspection report on a class, with the user asking to "apply the fixes".
Three traps, each a rule from `SKILL.md`: an "unused" getter whose absence
from the call path *is* the open incident (don't delete it), an XML
namespace flagged as an insecure HTTP link (an identifier, never `https`),
and a polymorphism finding on a class with no tests (Tier 2, so no
restructuring without a safety net). Two mechanical Tier 1 findings are the
expected work. The incident is mentioned in prose, never linked to the
getter, so the baseline has to make the connection itself.

## `characterize-current-behavior`

The user asks for characterization tests before a refactor. The code has
three quirks (asymmetric band boundaries, integer-division surcharge,
case-sensitive country). Targets the rule that characterization tests pin
*today's* behaviour, and the fresh-context step added for it: a context
that already holds the refactor plan drifts toward the intended values.
`Agent` is allowed so a run can delegate, but graders judge the outcome,
not the mechanism. A delegation-only grader would need the transcript, and
it's unconfirmed whether `llm` graders see tool calls.

Suggested first run, scoped and capped:

```
claude plugin eval skills/kaizen-refactor --runs 1 --model sonnet --max-cost-usd 2
```

Then `--runs 5` once the graders survive a read of the smoke-test answers.

### 2026-10-03 smoke run: Sonnet, the baseline passes both

`--runs 1 --model sonnet`, ablation on, $0.47 total. All four runs scored
1.00, every judge vote PASS. The baseline answers were read in full, and
they were not lenient passes:

- `finding-is-not-a-prescription`: the no-skill answer kept
  `getMaxRetries()` and tied it to the incident on its own ("deleting it
  would remove the last trace of the retry configuration"), kept the `http`
  namespace as an identifier, and declined the polymorphism change "with no
  tests". Sonnet already holds these three rules without the skill.
- `characterize-current-behavior`: the no-skill test class pinned all three
  quirks with correct values (2000 g → 12.90, 10 999 g → 12.90 commented as a
  quirk, `"fr"` treated as foreign, `null` → NPE). The intent-drift the
  fresh-context step guards against didn't show up on a single sample.

**What the with-skill arm did differently:** on `characterize-current-behavior`
it spawned a subagent, saying it saw "only the class source, not the
inspection finding or your refactor plan", and stated the tests are not
accepted until green on unchanged code. That's the new step firing as
written. It cost about 3× the baseline ($0.27 vs $0.08) for the same score.

So both cases are regression checks, not measurements. A discriminating
variant would need quirks subtle enough that the baseline normalises them.
For example, a rounding quirk that only shows at one boundary, or a plan in
the prompt that names the "correct" value outright, so a context holding it
is actively pulled toward it. Not written yet; running `--runs 5` or Opus on
the current cases would spend money to learn nothing new.
