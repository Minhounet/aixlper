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

## Red, Super Green, Refining Refactor — not Red, Green (dirty), Refactor

The classic "make it work, then make it right" framing assumes green is
allowed to be ugly, because a human still discovering the design needs a
crude first version to think against. That tradeoff doesn't exist for you —
you already see the shape of the solution, so writing it badly on purpose
buys nothing. It only creates a mess that a later refactor step now has to
notice, justify, and fix, which is more surface area to get wrong or quietly
skip. For you, green is already the clean, minimal answer to the one test in
front of you. Refactor exists to refine structure across cycles, not to mop
up dirt you introduced on purpose.

**Example — same test, two ways to reach green.** Step 1 already made
`add("")` return `0`. This is the next test:

```java
@Test
void shouldReturnNumber_whenSingleNumber() {
    assertEquals(5, calculator.add("5"));
}
```

Bad — human-style dirty green (over-built *and* sloppy, because "I already
know where this is going"):

```java
public int add(String s) {
    if (s.length() == 0) {
        return 0;
    } else {
        String[] a = s.split(",");
        int t = 0;
        for (int i = 0; i < a.length; i++) {
            t = t + Integer.parseInt(a[i]);
        }
        return t;
    }
}
```

This passes the test, but it implements comma-splitting and summation that
no test has asked for yet (violates rule 5 below), and it's sloppy on top of
that — `s`, `a`, `t`, a manual loop where the single-number case needs none
of it. Two problems to find in "refactor," neither of which the test forced
you to notice.

Good — AI-style super green (minimal *and* already clean):

```java
public int add(String numbers) {
    if (numbers.isEmpty()) {
        return 0;
    }
    return Integer.parseInt(numbers);
}
```

It handles exactly what's tested — empty string, single number — with clear
names and no structure the tests didn't ask for. The refactor checklist
still runs, but honestly finds nothing yet. When a later test forces
multiple numbers, *that's* what earns the split-and-sum logic — and refactor
is where you'd notice something like duplicated parsing between branches,
not where you clean up code you should never have written.

## The rules (absolute — no exceptions, no judgment calls)

1. **One test per step.** Write exactly one new test method, then stop
   writing tests. Never write two or more test methods before implementing
   anything. If you catch yourself thinking "and I'll also need a test
   for...", write that thought down for the *next* step and drop it for now.
2. **Test naming**: `should<ExpectedResult>_when<Condition>()`, e.g.
   `shouldReturnFullName_whenFirstAndLastNameProvided()`,
   `shouldThrowIllegalArgumentException_whenIdIsNull()`.
3. **No implementation dependency in the test.** A test's expected value
   must never be sourced from the implementation (e.g. importing and
   reusing a constant declared in the production class). Write the
   expected value independently in the test, even if that means
   duplicating a literal — otherwise the test can never fail on a wrong
   value, only on a compile error. This applies to any value the test
   asserts on, not just constants.
4. **Test-first is not up for debate.** No production code is written or
   modified until the one test for this step exists and has been run and
   has been shown to fail — and it must fail for the expected reason (a
   compile error because the API doesn't exist yet is not a valid red; get
   it compiling against a stub, then see it fail on the assertion).
5. **Minimal implementation only.** Write only the code required to make
   that single test pass. Do not implement behavior no current test
   requires, even if you know a later step will need it. A hardcoded or
   degenerate return value is an acceptable, even expected, way to pass a
   test — the next test is what should force generalization.
6. **Refactor is mandatory, every cycle, not "if warranted."** After green,
   always run this checklist against the code you just touched:
   - Did this step introduce duplication with existing code?
   - Is there a name (variable, method) that doesn't say what it means?
   - Did this step leave a magic literal that should be a constant?
   - Is there now a guard clause / early return that would remove nesting?
   - Does the current structure fight the next behavior you already know
     is coming?
   - Could this test now be merged with an existing one into a
     `@ParameterizedTest`? If yes, do it — no confirmation needed — but
     **never silently**: it changes test code, not just production code,
     so it must be traced. See "Tracing test refactors" below.
   If one or more apply, fix them now, then re-run the scoped test and show
   it's still green. If genuinely none apply, say so explicitly ("refactor
   checklist: nothing applies") — do not silently skip the step.

   **Tracing test refactors.** Any time this step changes test code itself
   (merging tests into a `@ParameterizedTest` is the case that comes up
   most, but this covers any other restructuring of existing tests too —
   renames, splits, moved assertions), report it explicitly in that
   cycle's refactor summary: name the specific test method(s) before and
   the resulting method(s) after. Production-only refactors (extracting a
   method, renaming a variable, removing duplication in implementation
   code) don't need this — only changes to the tests themselves do.

   Independently of that checklist, also apply these syntax-level
   refactorings wherever they appear in code you touch — they're
   mechanical, not judgment calls, so no "if warranted" applies to them:
   - `.stream()...collect(Collectors.toList())` → `.stream()...toList()`
   - a lambda with `{ }` braces around a single expression → drop the
     braces (and the `return`, if any):
     `s -> { System.out.println(s); }` → `s -> System.out.println(s)`
   - a lambda that only calls one method on its argument → a method
     reference: `s -> System.out.println(s)` → `System.out::println`
   - a local variable whose type is already obvious from its initializer
     → `var`
   - a generic constructor call already inferable from a `var` or field
     declaration → the diamond operator: `new Foo<Bar>()` → `new Foo<>()`
   - `instanceof` followed by a manual cast → pattern-matching
     `instanceof`: `if (o instanceof String) { String s = (String) o; }`
     → `if (o instanceof String s) { ... }`
7. **Build scope is never negotiable.** During the cycle (steps 1-4), build
   and run **only the single test class** you're working on — never the
   whole project. The full project build runs **exactly once, at the very
   end**, after the last cycle of the task. See commands below.
8. **Never claim green (or red) without having actually run it.** Show the
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
  `@Mock`, for collaborators you don't own — services, gateways, clients.
  Repositories are the one exception: prefer the in-memory fake above
  instead of mocking them. `lenient()` may be used freely — no need to
  justify each use.
- **Build the class under test in `@BeforeEach`, always — never as a
  field initializer, and never inline as `new Foo(...)` repeated inside
  each `@Test` method.** This holds even when the class has zero
  collaborators (a plain calculator kata, say): don't read the
  `@Mock`-null danger below as the *only* reason for this rule, or a
  mock-free class will quietly slide back to a fresh instance per test
  method. Two independent reasons it's the default regardless of mocks:
  - **Single source of truth.** One `@BeforeEach` wiring means a later
    constructor-signature change touches one place, not every test
    method.
  - **The `@Mock`-null trap**, whenever the class *does* have
    collaborators: `@Mock` fields are only populated by
    `MockitoExtension` *after* the test instance is constructed — a
    field initializer that passes a `@Mock` field into the constructor
    (e.g. `private final Foo foo = new Foo(myMock, ...);`) silently
    captures `null` instead, since it runs before that injection
    happens. It won't fail loudly: if nothing calls the null
    collaborator yet, tests keep passing until some later step does, at
    which point every test using that field breaks at once with a
    `NullPointerException` that looks unrelated to whatever you just
    changed.

  With collaborators:
  ```java
  @Mock
  private Foo foo;

  private Bar bar;

  @BeforeEach
  void setUp() {
      bar = new Bar(foo, ...);
  }
  ```
  With none — the rule still applies:
  ```java
  private StringCalculator calculator;

  @BeforeEach
  void setUp() {
      calculator = new StringCalculator();
  }
  ```
  `@InjectMocks` is Mockito's own way to sidestep the mock-null case (it
  builds the instance itself, after its mocks exist), but only use it
  when *every* constructor dependency is a genuine `@Mock`/`@Spy` — it
  silently resolves any dependency it can't match to `null` rather than
  erroring, and it has no sane way to wire in a plain in-memory
  implementation like the repository preference below. Prefer explicit
  `@BeforeEach` wiring whenever a mix of mocked and real (e.g. in-memory)
  collaborators is involved.

<!-- Add further testing preferences here as they come up. -->

## Code style

- **Vavr** in implementation code: prefer `Option`, `Either`, `Try`, and
  Vavr's persistent collections over nulls, thrown exceptions for control
  flow, and mutable Java collections, where they fit the problem.
- **Avoid side effects.** Prefer pure functions and immutable data in the
  implementation — a function's output should depend only on its inputs,
  with no mutation of shared state and no hidden I/O buried inside logic
  that doesn't need it. Push unavoidable side effects (I/O, mutation) to
  the edges rather than scattering them through the logic being tested.

<!-- Add further code style preferences here as they come up. -->

## When this skill doesn't cover the case

If you hit a situation these rules don't clearly address — an edge case,
an ambiguous rule, a step that doesn't produce the right behavior — don't
silently improvise a one-off judgment call and move on. Make the best call
you can for the situation at hand, then flag the gap explicitly, in this
format, so it can be reviewed and folded back into this file later:

```
## Skill improvement proposal
- Skill: java-tdd-baby-steps
- Situation: <what you were doing>
- Gap: <what these rules don't cover, or got wrong>
- Proposed rule: <the addition, worded as a rule, ready to paste in>
- Suggested location: <the section of this file it belongs in>
```

This is for gaps in the rules themselves, not violations of them — a rule
you understood but chose to break is not a gap.
