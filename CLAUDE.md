# aixlper

## Goal

A repository of generic, reusable AI agent skills, written once and usable
in multiple AI coding assistants — primarily **Claude Code** and
**Gemini CLI**. Skills follow the open **Agent Skills** standard
(`SKILL.md` + YAML frontmatter, optional bundled scripts/references), which
both clients read natively.

Portability rules for every skill in this repo:
- Frontmatter is limited to the shared subset: `name`, `description`
  (and other fields only if confirmed supported by both clients).
- No Claude-only fields (e.g. `allowed-tools`) unless the skill is
  explicitly Claude-only, in which case say so in the skill's description.
- Instructions in the body stay tool-agnostic — describe *what* to do, not
  a specific client's tool names, unless a step genuinely differs per
  client (call that out explicitly).

## Active work: java-tdd-baby-steps and java-clean-architecture

These two skills are being designed iteratively, directly with the repo's
author, across many sessions — they are **not** finished/stable in the way
the rest of this file is. Each `SKILL.md` is the source of truth; this
section is a status snapshot so a fresh session doesn't lose the thread
and re-litigate settled decisions. Keep this section in sync whenever
either skill changes in a way that affects the summary below.

They're deliberately kept as two separate skills: TDD governs *how you
write code over time* (the workflow), Clean Architecture governs *how the
code is structured* (the dependency rule) — orthogonal, composable, and
you shouldn't have to pull in architecture rules just to fix a bug in an
unstructured script.

**`skills/java-tdd-baby-steps/`** — one-test-per-step TDD, framed for an
AI specifically: baby steps exist for *containment* (capping the blast
radius of a confidently-wrong diff), not *design-discovery* (the usual
human justification, which is weak for an AI that often already sees the
full solution). Settled, non-negotiable rules: one test per step, real
red before any production code, minimal-only implementation, a mandatory
(checklist-bounded, not "if warranted") refactor pass every cycle,
test-scoped builds during the loop with a full build only once at the
end, `should<ExpectedResult>_when<Condition>` naming, and never sourcing a
test's expected value from the implementation (e.g. a shared constant).
Converting tests to `@ParameterizedTest` during refactor is allowed without
asking first, but must never be silent — it's traced in the cycle's
refactor summary (tests merged, named before/after), the same requirement
that applies to any other refactor that changes test code itself rather
than production code. The refactor step also always
applies a fixed set of mechanical syntax refactorings (stream
`.toList()`, lambda brace/return cleanup, method references, `var`,
diamond operator, pattern-matching `instanceof`) — these are not
judgment calls, unlike the design-level checklist. The `var` rule is
scoped to proximity: only when the declaration sits close to its use, not
when they're far apart in a long method — this is also treated as a
deliberate forcing function for good naming, since without an explicit
type nearby the variable name has to carry the meaning. Author's preferences
captured so far: in-memory repositories over real adapters when the task
allows it, Mockito for collaborators not owned by the codebase (services,
gateways, clients — repositories are the one exception, kept in-memory)
with `@ExtendWith(MockitoExtension.class)` (`lenient()` freely allowed),
Vavr in implementation code, avoid side effects. Build the
class under test in `@BeforeEach`, never as a field initializer — a
field initializer that reads a `@Mock` field captures `null`, since
`MockitoExtension` populates `@Mock` fields only after construction
(found live while dogfooding, see below); `@InjectMocks` is a narrower
alternative, only when every dependency is a genuine mock/spy.

Latest addition (this session): reframed the cycle as Red / **Super
Green** / **Refining Refactor**, not the classic Red / Green(dirty)
/ Refactor — for an AI, "green" should already be minimal *and* clean, since
writing it dirty on purpose has no design payoff (it only creates mess a
later step must notice and might quietly skip) and refactor becomes
refinement of structure across cycles, not cleanup. Concretely this added:
(1) a "triangulate before generalizing" clause on the minimal-implementation
rule — never introduce a loop/recursion/abstraction on one test's strength;
wait for a second test that a hardcoded/single-branch implementation
genuinely can't satisfy; (2) an "advanced refinement" tier on top of the
existing refactor checklist, gated by concrete trigger thresholds (3rd
same-type conditional → polymorphism, duplicated validation across 2+ call
sites → value object, 3rd reason-to-change on a class → split it, 3+
branches on the same discriminant → Strategy) rather than left to
open-ended judgment, since open-ended judgment repeats the same
anticipation problem one altitude up; (3) a "log, don't ask" rule for a
refactor candidate that hits no trigger — noted inline in that cycle's
refactor summary (not applied, not asked about), then rolled up into a
single "Deferred refinement notes" list printed once at the end of the task
alongside the one-time full build, so judgment calls are visible without
interrupting the cycle. Trigger thresholds are defaults the author can
tune, the same way the preferences above have grown over sessions.

Also added, code-style preferences (functional-programming-flavored):
`null` is disallowed outright in author-written code — `Option` is the
default for an absent value, not `null` or `java.util.Optional`, and a
`null` is a refactor candidate on sight rather than something to wait on a
trigger for; `flatMap` is for genuinely dependent/sequential steps, while
independent values that just need combining should use Vavr's applicative
style (`combine(...).ap(...)`) instead of a forced `flatMap` chain; and
when the Strategy trigger fires, default to extracting the varying part as
a lambda/function value rather than a full Strategy interface with one
implementing class per branch — reach for the class form only when a
branch needs more than one method or its own state.

**`skills/java-clean-architecture/`** — dependency inversion via
interfaces is the one rule everything else follows from. Constructor
injection always (setter injection is a narrow, seam-scoped exception for
legacy framework wiring that genuinely blocks the constructor path, not a
general option). From scratch, the use case is the entry point, taking
its repository/service/logger interfaces via the constructor; on legacy
code where the entry point isn't owned, dependency inversion still
applies at whatever seam *is* owned rather than being skipped wholesale.
Spring guidance: no framework annotations in core classes by
default, wiring via `@Configuration`/`@Bean` at the composition root
(with a "reality check" that an already-annotated legacy project gets the
same seam treatment, not a forced rewrite); the logger is bound to its
declaring class via a prototype-scoped `InjectionPoint` bean rather than
one shared logger. One open assumption not yet explicitly confirmed by
the author: the `Logger` interface is taken to mean SLF4J's
`Logger`/`LoggerFactory` (log4j2 as the binding), not a hand-rolled
interface. Latest addition: needing to mock a static method is treated as
a design smell, not a testing inconvenience — it means the code reached
for a static dependency directly instead of an interface, same violation
as the constructor-injection rule, just spotted from the test side. Fix is
to wrap it behind an owned interface and inject an adapter, mirrored as a
mocking-preference note in `java-tdd-baby-steps`. Exception: a static you
don't own (JDK, a third-party library) where wrapping is out of scope —
mocking it is an accepted last resort there. Sharpened further: the actual
line isn't "static," it's determinism — a pure static (`Math.max`,
`Collections.emptyList`) is fine to call directly, but a non-deterministic
one (`Instant.now()`, `UUID.randomUUID()`, `Math.random()`) always needs
wrapping behind an owned interface (`Clock`, `IdGenerator`), since a test
can never pin an expected value on a call that isn't repeatable.

Expect both files to keep growing with more rules, examples, and
preferences from ongoing conversation — don't treat either as complete,
and don't remove or "clean up" sections without the author asking.

**Testing method: dogfood via kata.** Beyond `make validate`/`make eval`,
these two skills are pressure-tested by actually using them: pick a small
kata, set it up in a throwaway scratch directory (not committed — a
one-off smoke test, not a project artifact), and solve it while following
the target skill's rules literally and verbatim, showing real command
output at every red/green checkpoint rather than asserting it worked.
Choose the kata to fit whichever skill is under test: something with many
small, naturally incremental cases (numeric conversions, parsers, small
calculators) exercises `java-tdd-baby-steps`; something shaped like a
real use case with real collaborators (a repository, a service, a
logger) exercises `java-clean-architecture`'s DIP/constructor-injection/
seam rules. Treat any friction — an ambiguous rule, a step that doesn't
produce the right behavior, a bug the rules should have caught but didn't
— as a direct signal to fix the SKILL.md, not just the kata code. First
run: the roman-numeral kata (int → roman numeral, wrapped in a use case
with an injected repository and logger) surfaced the `@Mock`
field-initializer trap now documented in `java-tdd-baby-steps`. Second
run: the String Calculator kata (no collaborators at all), solved under
Gemini CLI, surfaced that the `@BeforeEach`-construction rule read as
conditional on mocks being present — a mock-free class quietly reverted
to `new StringCalculator()` inline per test method. The rule in
`java-tdd-baby-steps` was broadened to state `@BeforeEach` construction
as the unconditional default (single source of truth for wiring the
SUT), with the `@Mock`-null trap kept as one reason among others rather
than the only one.

## Active work: documentum-idempotent-scripting

`skills/documentum-idempotent-scripting/` is unverified — written from
general Documentum DQL/API knowledge, not yet run against a real docbase.
Treat every pattern in it as a draft until the author reports back from
real usage; don't cite it as settled the way the two Java skills below are.

The gap it targets: individually, DQL and the API (`iapi`/`idql`) are
well-documented and widely known; composing the two into a bash script
that's safe to re-run — existence-check before `create`, surviving a
partial failure, converging to the same end state across dev/test/prod —
is the part that isn't. That's the same shape of gap the two Java skills
below fill (tacit operational knowledge, not syntax), just for a different
domain.

**Testing method: real docbase, not kata.** Unlike the Java skills' kata
dogfooding (see below), there's no throwaway-project equivalent for a
Documentum skill — it needs a live docbase to mean anything. The author
will validate it by using it against a real Documentum environment and
reporting friction back. Known-weak spot going in: pattern 4's
`get_type_attr_count` in the SKILL.md is a named placeholder, not real
DQL — the exact query for enumerating a type's attributes varies by
Documentum version and hasn't been confirmed. Any correction from real
usage should land as an edit to
`skills/documentum-idempotent-scripting/SKILL.md` plus a note here, the
same discipline as the Java skills' entries below.

First correction, from the author before any real-docbase run: pattern 7's
password-hygiene framing didn't account for trusted login — a script
running as `dmadmin` locally authenticates on OS identity, not the
password string, so a successful connect there doesn't confirm the
credential file was right. Added as pattern 8.

Second addition, also author-driven: bulk update/delete needs its own two
patterns, since neither is covered by "check before create" — 9 is the
set-based `ENABLE (RETURN_TOP n)` loop (naturally idempotent as long as the
mutation moves rows out of the `WHERE` clause), 10 is ID-batch + per-object
API loop for operations DQL can't express set-based (versioning, lifecycle,
ACL changes), which needs an explicit processed-ids log since it isn't
transactional across a batch the way pattern 9 is.

## Active work: java-tdd-baby-steps and java-clean-architecture

```
skills/<skill-name>/SKILL.md      # one skill per directory
skills/<skill-name>/references/   # optional supporting files
skills/<skill-name>/scripts/      # optional scripts the skill runs
skills/<skill-name>/evals/        # claude plugin eval cases for the skill
```

## Build / CI

There's nothing to compile — skills are plain markdown+YAML read directly
by the client — but there is a validate/test pipeline, the equivalent of
`mvn verify` for this repo:

- `make validate` — runs `scripts/validate_skills.py`, which checks every
  `skills/<name>/SKILL.md` has well-formed frontmatter, exactly one
  `SKILL.md`, and frontmatter limited to the portable subset (flags
  Claude-only keys like `allowed-tools` unless the skill's description
  says it's Claude-only).
- `make eval` — runs `claude plugin eval` for every skill that has a
  `skills/<name>/evals/` directory (`case.yaml`/`prompt.md` + grader
  files), including a no-skill baseline comparison.
- `make ci` — both, in order. Wired into `.github/workflows/`.

## Testing

- **Claude Code**: skills can be exercised live in a Claude Code session,
  or scored with `make eval` (see above).
- **Gemini CLI**: no automated check here — since Gemini CLI isn't
  available to script against in this environment, we rely on the
  portability rules above (shared frontmatter subset, tool-agnostic
  instructions) instead of an automated cross-check. A skill that follows
  those rules and passes `make validate` is assumed to work in Gemini CLI
  too, since the content itself (e.g. "how to cook a chicken") doesn't
  depend on which client is reading it — only genuinely Claude-specific
  steps need a manual Gemini check.

## Distribution

Skills are packaged for install/update via each client's native mechanism,
both sourced from this same repo:
- **Claude Code**: a plugin marketplace (`.claude-plugin/marketplace.json`
  + `plugin.json`), added with `/plugin marketplace add <repo-url>` and
  updated via the marketplace/plugin update flow.
- **Gemini CLI**: a `gemini-extension.json` extension manifest, installed
  with `gemini extensions install <repo-url> --auto-update`.

Both manifests point at the shared `skills/` directory — there is one copy
of each skill, not a fork per client.
