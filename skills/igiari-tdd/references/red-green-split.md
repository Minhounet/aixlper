# Split mode: RED and GREEN in separate subagents

> Reference for the `igiari-tdd` skill. Read when split mode is on (the
> author asked for it, or the project's instructions enable it) and the
> client can spawn subagents. Claude Code only; experimental, not yet
> dogfooded.

The rules are in `SKILL.md` and are unchanged by split mode. This file only
says who does each step and what each subagent is given.

## Roles

| Role | Runs as | Gets | Must not get | Writes |
|---|---|---|---|---|
| **Orchestrator** | you, the session following the skill | everything | — | plan, signature stubs, REFACTOR, every official red/green run |
| **Test writer** | fresh general-purpose subagent, one per cycle | plan entry N, the test class, the class under test's **public signatures** | production method bodies, your reasoning about the implementation | one test method |
| **Implementer** | fresh general-purpose subagent, one per cycle | the test class (every test so far), the red output, the class under test | **the test plan**, any future test | production code only |

The point is what each subagent lacks: one context can't be told to forget
the plan or an intended implementation, but a fresh one never had it. Both
are spawned from a role prompt (below); no agent definition files are
needed. Tool allowlists aren't the enforcement, because they're per-tool,
not per-path: an implementer that can edit production code can edit tests
too. Rule 9's frozen-test check, run by you, is what enforces the boundary.

## The cycle

0. **Plan.** Unchanged: write the plan, wait for the single go-ahead.
1. **RED**
   1. Dispatch the test writer with plan entry N.
   2. If the new test doesn't compile because the API doesn't exist yet,
      add a signature-only stub yourself (rule 4 says what it returns)
      and show it. A stub is not implementation.
   3. Run the scoped test yourself. Show the new test method's code and the
      red output; confirm it fails for the expected reason (rule 4).
      Don't pause.
2. **GREEN**
   1. Record the test files' state (rule 9).
   2. Dispatch the implementer.
   3. It returns `TEST LOOKS WRONG: <reason>` → nothing was changed; raise
      it as a plan deviation (the existing second pause).
   4. Otherwise run the frozen-test check, then the scoped test yourself.
      Show the production diff and the green output.
   5. **Review the diff against rule 5 yourself.** You are the only one
      who knows the plan, so you are the only one who can see an
      overshoot: a collection-wide loop/stream/sum backed by a single
      test, or a branch that sniffs specific test inputs to return their
      expected literals. Either one → reject: revert the production change
      and send it back to the same implementer (cheaper than a fresh
      spawn), naming the rule but **not** revealing any future test.
   6. A test file changed → revert that change and re-dispatch once, naming
      the violation. A second violation → stop and show the author.
3. **REFACTOR**: inline, exactly as in `SKILL.md`. It needs the
   whole-task view (cross-cycle duplication, deferred refinement notes) and
   may touch tests, which rule 6 already traces.
4. **Final full build**: inline, unchanged.

## Dispatch prompts

Fill the `<...>` slots. Keep the red output bounded (`tail -30`), and the
code-style bullets verbatim from `SKILL.md`.

The subagents never see `SKILL.md`: any rule the prompt paraphrases or
drops is gone for them. Quote rules verbatim, never summarise them. (First
dogfood run: shortening rule 5 to "a hardcoded return is acceptable" got a
green that sniffed test inputs, `contains(",") ? 3 : 5`.)

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
- Do not modify production code or any existing test. Do not run the build.
Return: the test method you added, and nothing else.
```

**Implementer**

```
Make the failing test pass with the MINIMAL, CLEAN production change.
Test class: <path>   Failing test: <method>   Class under test: <path>
Red output:
<bounded red output>
- Never modify any test file. If the test looks wrong, change nothing and
  return "TEST LOOKS WRONG: <reason>".
- Minimal implementation rule, verbatim: "<SKILL.md rule 5, verbatim,
  including the triangulation paragraph>"
- Read that as: generalize just enough for the tests that exist. Never
  branch on specific test inputs to return their expected literals —
  that is faking, not minimal.
- "Super Green": green is already the clean, minimal answer — clear
  names, no sloppy code to clean up later, and no structure the tests
  didn't ask for.
- Code style: <the SKILL.md "Code style" bullets, verbatim>
- You may run: <scoped test command>. Keep output bounded (tail -30).
Return: a one-line summary of the change. Do not paste the build output.
```

## Costs

- Two cold subagent starts per cycle, each re-reading the files it needs.
  Measured on the first run (String Calculator, 6 cycles): 14 subagent
  runs at ~54k tokens each, ~760k total — almost all of it per-spawn fixed
  overhead, not the work itself.
- At least one more scoped build per cycle than inline: the implementer
  may iterate, then you re-run green as the evidence.
- Without the plan, the implementer may pick a structure the next test
  forces it to undo. That's what triangulation intends, but it can mean
  more REFACTOR work.
- "Don't read method bodies" is still an instruction to the test writer,
  not enforced; a narrow single-job context just follows it more reliably.

If split mode turns out to be on for almost every trigger, this file is
costing more as a reference than it would inline. Re-run the token
self-audit and consider moving it back into `SKILL.md`.
