---
name: java-tdd-baby-steps
description: Enforces one-test-at-a-time Test-Driven Development for Java, non-negotiably — never more than one failing test at a time, minimal implementation only, a mandatory refactor checkpoint every cycle, and test-scoped builds during the loop with a full project build only at the very end. Use whenever writing or changing Java production code.
---

# Java TDD — Baby Steps

## Why baby steps, specifically for you (an AI)

Baby steps are usually justified as a *design-discovery* tool: a human doesn't
yet know the shape of the solution, so small steps let it emerge from the
tests. That justification is weak for you — you often already see a plausible
full solution from the first test.

The justification that actually applies to you is **containment**. You can
produce a large, fluent, confidently-wrong diff in one pass, with nothing
forcing you to check it, and you don't get a nagging feeling that something's
off the way a careful human does. One test at a time caps the blast radius of
any single mistake to a few lines, and forces you to produce *evidence*
(a shown red run, a shown green run) at every checkpoint instead of asserting
that something works.

Read every rule below through that lens: it exists to contain you, not to
simulate ignorance you don't have.

## The rules (absolute — no exceptions, no judgment calls)

1. **One test per step.** Write exactly one new test method, then stop
   writing tests. Never write two or more test methods before implementing
   anything. If you catch yourself thinking "and I'll also need a test
   for...", write that thought down for the *next* step and drop it for now.
2. **Test-first is not up for debate.** No production code is written or
   modified until the one test for this step exists and has been run and
   has been shown to fail — and it must fail for the expected reason (a
   compile error because the API doesn't exist yet is not a valid red; get
   it compiling against a stub, then see it fail on the assertion).
3. **Minimal implementation only.** Write only the code required to make
   that single test pass. Do not implement behavior no current test
   requires, even if you know a later step will need it. A hardcoded or
   degenerate return value is an acceptable, even expected, way to pass a
   test — the next test is what should force generalization.
4. **Refactor is mandatory, every cycle, not "if warranted."** After green,
   always run this checklist against the code you just touched:
   - Did this step introduce duplication with existing code?
   - Is there a name (variable, method) that doesn't say what it means?
   - Did this step leave a magic literal that should be a constant?
   - Is there now a guard clause / early return that would remove nesting?
   - Does the current structure fight the next behavior you already know
     is coming?
   If one or more apply, fix them now, then re-run the scoped test and show
   it's still green. If genuinely none apply, say so explicitly ("refactor
   checklist: nothing applies") — do not silently skip the step.
5. **Build scope is never negotiable.** During the cycle (steps 1-4), build
   and run **only the single test class** you're working on — never the
   whole project. The full project build runs **exactly once, at the very
   end**, after the last cycle of the task. See commands below.
6. **Never claim green (or red) without having actually run it.** Show the
   command and its output at every red/green checkpoint. No exceptions for
   "this is obviously going to pass."

## The cycle

Repeat for each new behavior, one at a time:

1. **RED** — Add the one test method for the next smallest behavior. Run it
   scoped to its class. Show the failure output.
2. **GREEN** — Write the minimal production code to pass that one test.
   Run the same scoped test. Show the pass.
3. **REFACTOR** — Run the mandatory checklist above. Apply what applies.
   Re-run the scoped test, show it's still green.
4. Go back to step 1 for the next behavior.

When there are no more behaviors left for the current task, run the full
project build once as the final step.

## Build commands — scoped during the cycle, full only at the end

**Maven**
```bash
# scoped (during the cycle) — one test class, or one method
mvn test -Dtest=ClassNameTest
mvn test -Dtest=ClassNameTest#methodName

# full (end of task only, once)
mvn test
```

**Gradle**
```bash
# scoped (during the cycle) — one test class, or one method
./gradlew test --tests "com.example.ClassNameTest"
./gradlew test --tests "com.example.ClassNameTest.methodName"

# full (end of task only, once)
./gradlew build
```

## Author's preferences

These are conventions to default to; the checklist and rules above stay
non-negotiable regardless.

- **Repository implementations**: prefer an in-memory implementation
  (e.g. backed by a `Map`/`List`) over a real persistence adapter whenever
  the task doesn't specifically require one. It implements the same
  port/interface a real adapter would, and keeps tests fast without mocking
  out persistence.
- **Mocking**: Mockito, with `@ExtendWith(MockitoExtension.class)` and
  `@Mock` / `@InjectMocks`. `lenient()` may be used freely — no need to
  justify each use.

<!-- Add further preferences here as they come up. -->
