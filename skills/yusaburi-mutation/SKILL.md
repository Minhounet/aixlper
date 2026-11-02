---
name: yusaburi-mutation
description: Mutation testing for Java with PIT (PITest) - checks that tests catch a change in the code, not just run it. A tool breaks the code on purpose, one small change at a time; a change no test notices (a survivor) is code no test pins. Run on the code a task touches, never per TDD cycle and never as a codebase-wide sweep - at the end of a TDD run (a survivor there is code no red asked for), and before relying on existing tests to change existing code (a survivor there is a hole in the safety net). Use when finishing a TDD run, before a judgment-call refactor or a fix of existing code, or when asked whether tests really protect some code, about mutation score, PIT or surviving mutants.
---

# Yusaburi: press the witness

*Yusaburi* (揺さぶり) is pressing the witness: you push on the testimony to
see if it holds. Here the witnesses are the tests. A mutation tool changes
the code in one small place (`<` becomes `<=`, a condition becomes `true`,
a returned value becomes `null`) and runs the tests. If one fails, the
mutant is **killed**: the tests notice that change. If all pass, it
**survived**: that line could be wrong and no test would say so.

Coverage only says a line *ran*. A mutation run says whether anything
*checked* it. That is the only reason to pay for one.

## When to run it

Only these moments, each scoped to the code the task touches:

| Moment | Scope | A survivor means |
|---|---|---|
| **End of a TDD run**, after the full build and the history audit | Production classes the run changed | Code no red asked for, or a test that asserts too little |
| **Before relying on existing tests to change existing code**: a judgment-call refactor, or a fix that touches lines its own new test does not reach | Classes about to change | A hole in the safety net, to fill before the change |
| **When the user asks** | What they name | Whatever they asked about |

Never:

- **Per TDD cycle.** Each test was already seen failing; that is the
  mutation check for the line it drove. A run per cycle adds minutes for
  nothing.
- **Across the codebase.** Survivors in code the task doesn't touch are
  not this task's work. Flag them in one line if they matter; never start
  killing them.
- **As a score to reach.** No percentage target. The output is the list of
  survivors in scope and a verdict for each one. A threshold invites tests
  written to kill mutants instead of tests that pin behavior.

## The tool does the breaking

Use the project's mutation tool (PIT for Java: `references/pitest.md`).
Don't invent mutants by hand when the tool is there: it tries every
mutation point the same way on every run, and a hand-picked set only finds
what you already suspected. A single hand-made mutation is still right for
one line, such as an `igiari-tdd` guard's mutation check.

If no tool is configured, say so and ask before adding one to the build:
it is a build change, which is the author's call.

## A verdict for each survivor

List every survivor (and every mutant with no coverage) in scope, one line
each: file, line, what was mutated. Then give each one a verdict:

1. **Unrequested code** (TDD run only): no test asked for this line or this
   condition. Remove it in a refactor step (the tests stay green, so
   behavior *as specified* is unchanged), unless the plan or an AC asks for
   it, in which case it is case 2.
2. **Behavior that matters, not pinned**: write the test that kills it.
   - In a TDD run, the code already exists, so the test passes on write:
     it is an `igiari-tdd` **guard**, committed as that skill defines, with
     the surviving mutant as its mutation check.
   - Before changing existing code, it is a **characterization test**
     (pin what the code does today), written as `kaizen-refactor`'s safety
     net says, by a context that hasn't seen the planned change.
   Re-run the mutation tool on that class and check the mutant is now
   killed.
3. **Equivalent**: the mutant behaves exactly like the original, so no
   test could kill it (for example a boundary on a value that can never be
   equal). This is the weakest verdict and the one the code's writer
   most wants to give. State the reason in one line, per survivor; "looks
   harmless" is not a reason. Where the client can spawn a reviewer with
   fresh eyes, it checks every equivalent verdict; where it can't, say that
   the same context wrote the code and judged it.

A mutant that **timed out** or caused a **run error** is the environment,
not a verdict either way: rerun or report it, never count it.

When unsure between 1 and 2, it is a decision: show the survivor and the
option you recommend. Never decide silently that a behavior doesn't matter.

## What it can't see

- **Over-generalization.** A general `stream().sum()` is fully killed by a
  `"1,2"` test. Mutation finds lines nobody checks, not code more general
  than its tests asked for; `igiari-tdd`'s generalization audit covers that.
- **Missing behavior.** It only mutates code that exists. A case nobody
  wrote is invisible to it; that is what the plan and the ACs are for.
- **Wrong expectations.** A test asserting the wrong value still kills
  mutants.

## Project specifics

| When | Read |
|---|---|
| The project is Java with Maven or Gradle (PIT) | `references/pitest.md`: setup, scoped commands, reading the report |

## Token self-audit

This file loads **in full** whenever the skill triggers and stays resident
for the rest of the session; `references/` files load only if the body
points at one. When asked to reduce token cost — or before adding anything
here — audit in this order and report what you would move, and why:

- **Needed only sometimes?** Material for one framework, one tool's exact
  commands, or a section about extending the skill itself → move to
  `references/` behind a pointer that names the condition precisely.
- **A reference opened on almost every trigger?** Then it costs *more*
  there than inline — a tool call, an extra assistant turn, and a lost
  prefix cache. Bring it back inline.
- **Does a step here run a command?** Its output is tokens too, charged
  every run and kept for the session. A mutation run prints a line per
  mutant and per test: keep the console quiet, and read only the survivors
  from the report.

Never split a rule from its own statement: a reference shows how to satisfy
a rule in one environment, it never holds the rule. **Relocate, never
delete** — removing guidance to save tokens is a regression, not a saving.

## When this skill doesn't cover the case

If you hit a situation these rules don't clearly address — an edge case,
an ambiguous rule, a step that doesn't produce the right behavior — don't
silently improvise a one-off judgment call and move on. Make the best call
you can for the situation at hand, then flag the gap explicitly, in this
format, so it can be reviewed and folded back into this file later:

```
## Skill improvement proposal
- Skill: yusaburi-mutation
- Situation: <what you were doing>
- Gap: <what these rules don't cover, or got wrong>
- Proposed rule: <the addition, worded as a rule, ready to paste in>
```
