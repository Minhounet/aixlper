# Proposal: separate RED from GREEN in `igiari-tdd`

> Status: **Part A kept, Part B removed (2026-10-02).** Part A is rule 9 in
> `skills/igiari-tdd/SKILL.md`. Part B (split mode) was applied, dogfooded
> against an inline baseline, did worse at ~9× the tokens, and was removed
> at the author's request; see `docs/design-log.md`. Kept as the record of
> the reasoning.

## The problem this solves

`igiari-tdd` exists for *containment*: baby steps so an AI can't produce a
large, fluent, confidently-wrong diff. Most of its rules are still enforced
only by the AI agreeing to follow them, and the same mind that writes the
test also writes the code that passes it. Three failure modes survive
because of that:

1. **Bending the test to reach green.** During GREEN, the fastest route to a
   pass is sometimes to "fix" the test: loosen an assertion, change an
   expected value. Nothing in the cycle checks that the test file came
   through GREEN untouched.
2. **Building ahead from the plan.** The skill needs a whole worked example
   ("seeing the whole plan doesn't license building ahead") because the
   implementer *can* see tests 3 and 4 while writing test 1's code. Rule 5
   asks it to pretend it can't.
3. **Tests shaped by the implementation.** When one context writes both, the
   test for step N is written by something that already "knows" the
   implementation it intends to write. Rule 3 covers the worst case
   (importing a production constant), but not the general one: a test that
   asserts what the code will do rather than what the requirement says.

The proposal has two parts. **Part A** is portable and cheap, and fixes #1
everywhere. **Part B** is Claude-Code-only and opt-in, and fixes #2 and #3
structurally by giving RED and GREEN to two separate subagents that each
lack something the other one has.

## Part A — test files are frozen during GREEN (portable, always on)

A new rule, applying in every client, with or without subagents:

> **9. The test is frozen during GREEN.** Before writing production code,
> record the state of the test files (`git diff --stat -- <test paths>`, or
> checksums when the project isn't a git repository). After GREEN, check
> again. If any test file changed, the step is invalid: revert the test
> change, and either redo GREEN against the original test or, if the test
> itself is wrong, stop and raise it as a plan deviation (the existing
> deviation pause). Test changes belong in RED or in REFACTOR (traced), and
> never in GREEN.

Why it's worth it on its own: the check costs one cheap command per cycle,
its output is a single line, and it turns failure #1 from "the AI promised
not to" into "it was checked". It also makes Part B's boundary verifiable
instead of trusted.

## Part B — two-agent RED/GREEN (Claude Code only, opt-in)

### Roles

| Role | Runs as | Sees | Does not see | Writes |
|---|---|---|---|---|
| **Orchestrator** | the main session, following the skill | everything | — | plan, stubs, refactor, all *official* red/green runs |
| **Test writer** | subagent, fresh per cycle | plan entry N, the existing test class, the class-under-test's **public signatures** | production method bodies, the orchestrator's reasoning | one test method |
| **Implementer** | subagent, fresh per cycle | the test class (all tests so far), the red output, the class under test | **the plan**, future tests | production code only |

The design point is what each subagent *doesn't* see. The implementer can't
build ahead because the future tests aren't in its context. The test writer
can't shape the test to an implementation because it was never told one.

### Why subagents, against this repo's own criteria

This rests on criterion #5 in `CLAUDE.md`, added for this proposal:
**the step must *not know* something the caller knows.** Here that's the
implementer not knowing the plan, and the test writer not knowing the
intended implementation. A skill can't make a single context forget. Only a
fresh one starts without it. Of the original four, only #3 (isolated
context) partly applies.

Tool allowlists (#1) are deliberately **not** the enforcement mechanism. A
subagent's tool list is per-tool, not per-path: an `Edit`-capable implementer
can edit test files as easily as production ones. Enforcement comes from
Part A's frozen-test check, run by the orchestrator after every GREEN. The
subagents are general-purpose ones spawned with a role prompt, so the repo
ships **no `.claude/agents/` files** and stays inside its scope.

### The cycle, with the split

0. **Plan.** Unchanged. The orchestrator writes the plan and waits for the
   single go-ahead.
1. **RED.**
   1. Dispatch the test writer with plan entry N and the paths above.
   2. If the new test fails to compile because the API doesn't exist yet,
      the orchestrator adds a **signature-only stub** (default return, or
      `throw new UnsupportedOperationException()`) and shows it. A stub is
      not implementation, and rule 4 already requires one.
   3. The orchestrator runs the scoped test itself and **shows the new test
      method's code and the red output**, then checks the red is an
      assertion failure (rule 4). No pause: the author can read it and
      interrupt, but the run continues.
2. **GREEN.**
   1. Record the state of the test files (Part A).
   2. Dispatch the implementer with the test class, the red output and the
      class under test. It may run the scoped test while it works, and that
      output stays in its context.
   3. If the implementer reports "this test looks wrong", nothing is
      changed. The orchestrator raises it as a plan deviation (the existing
      second pause).
   4. Otherwise the orchestrator runs the frozen-test check, then the scoped
      test, and **shows the production diff and the green output**.
   5. Test file changed → revert that change and re-dispatch once, with the
      violation named. A second violation → stop and show the author.
3. **REFACTOR.** Inline in the orchestrator, unchanged. It needs the
   whole-task view (duplication across cycles, deferred refinement notes)
   and may touch tests, which is already traced.
4. **Final full build.** Inline in the orchestrator, unchanged.

Rule 8 (never claim red or green without running it) is satisfied by the
orchestrator's own runs, never by a subagent's report. This follows the
design log's "you get the conclusion, not the evidence" lesson.

### Dispatch prompts (drafts)

**Test writer**

```
You write exactly ONE JUnit test method, then stop.
Behavior to specify: <plan entry N, verbatim>
Test class: <path>   Class under test (public API only): <path>
- Read the class under test's signatures only; do not read method bodies.
- Name: should<ExpectedResult>_when<Condition>().
- Expected values are literals written in the test; never import or reuse
  a production constant or call production code to compute an expectation.
- Use the existing @BeforeEach wiring; do not add a field initializer.
- Do not modify production code. Do not run the build.
Return: the test method you added, and nothing else.
```

**Implementer**

```
Make the failing test pass with the MINIMAL production change.
Test class: <path>   Failing test: <method>   Class under test: <path>
Red output:
<bounded red output>
- Never modify any test file. If the test looks wrong, change nothing and
  return "TEST LOOKS WRONG: <reason>".
- Implement only what the tests in the test class require. A hardcoded
  return is acceptable; do not generalize (loop, recursion, abstraction)
  unless an existing test forces it.
- Code style: <the SKILL.md "Code style" bullets, verbatim>
- You may run: <scoped test command>. Keep output bounded (tail -30).
Return: a one-line summary of the change. Do not paste the build output.
```

### Costs, stated honestly

- **More spawns.** Each cycle starts two subagents cold, so a 4-test kata
  spawns 8. Each one re-reads the files it needs. Expect a slower, more
  expensive run than inline.
- **Extra builds.** The implementer may iterate on its own scoped runs, and
  the orchestrator re-runs green as the official evidence. That's at least
  one more scoped build per cycle than today.
- **Worse context for the implementer.** Without the plan, it may pick a
  structure that the next test forces it to undo. That's exactly what
  triangulation intends, but it can mean more REFACTOR work.
- **Partly compliance-based.** "Don't read method bodies" for the test
  writer is still an instruction. A narrow context with a single job follows
  it more reliably, but it isn't enforced.

### Where it lives (token budget)

`SKILL.md` is already ~28KB, over the repo's ~20KB guideline. Part B is
conditional (Claude Code only, opt-in) and mechanics-heavy, so it fits
`references/` per the progressive-disclosure rules:

- **`SKILL.md`** gains rule 9 (Part A, ~0.6KB) and a short "Split mode"
  pointer (~0.5KB) stating the guarantees: what each role must not see,
  orchestrator-only evidence, and the frozen-test check.
- **`references/red-green-split.md`** (new) holds the roles table, the
  cycle-with-split steps and the dispatch prompts.

The token self-audit warns that a reference opened on almost every trigger
costs more than inline. That's why Part B is **opt-in** while it's being
trialled: it's used only when the author asks for it ("use split mode") or a
project's `CLAUDE.md` turns it on. If it becomes the default in Claude Code,
re-run the audit and probably bring it back inline.

In Gemini CLI, or anywhere subagents aren't available, the skill runs inline
exactly as today, plus Part A.

## How to tell whether it's actually more effective

Following the repo's own testing method, before making anything default:

1. **Kata dogfood, A/B.** Run the same kata (String Calculator is already
   the skill's running example) once inline with Part A, and once in split
   mode, in a throwaway git-initialised scratch directory. Record:
   - build-ahead violations (code with no test forcing it),
   - test edits caught by the frozen-test check,
   - tests that assert implementation details instead of the requirement,
   - wall time and token cost.
2. **Evals.** `triangulate-before-generalizing` is the existing case most
   likely to move under split mode. First check whether `claude plugin eval`
   lets a case spawn subagents. If it doesn't, the kata is the only evidence
   and that should be said in the log.

If split mode only matches inline-plus-Part-A on violations, Part A alone
is the win and Part B isn't worth its cost.

## Decisions (author, 2026-10-02)

1. **No per-test approval.** Split mode keeps the single plan-time pause.
   Each test and its red output are shown as the run continues, without
   stopping.
2. **No cheaper model.** The implementer and the test writer run on the
   same model as the main session.
3. **No reviewer subagent.** REFACTOR stays inline in the orchestrator.
4. **Part A only.** Test edits during GREEN are caught by the frozen-test
   check after the fact. No `PreToolUse` hook.
5. **Criterion added.** `CLAUDE.md` now lists "must not know something the
   caller knows" as a 5th reason for a subagent step.
