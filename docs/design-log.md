# Design log

Session-by-session history for the repo's actively-evolving skills: every
rule addition, correction, and worked example, with the reasoning behind
it, in the order it happened. `CLAUDE.md` keeps a condensed, current
settled-state summary for each of these skills (so a fresh session isn't
paying to load all of this every time); this file is where the *why*
behind a given rule lives, and where the running history keeps growing so
sessions don't re-litigate settled decisions. Each `SKILL.md` remains the
source of truth for the exact current rules — this file explains how they
got there.

Don't remove or "clean up" entries without the author asking, same as the
rule that applied to this content when it lived in `CLAUDE.md`.

## igiari-tdd and chottomatte-archi

These two skills are being designed iteratively, directly with the repo's
author, across many sessions — they are **not** finished/stable the way
most of the rest of this repo is. Keep this section in sync whenever
either skill changes in a way that affects it.

They're deliberately kept as two separate skills: TDD governs *how you
write code over time* (the workflow), Clean Architecture governs *how the
code is structured* (the dependency rule) — orthogonal, composable, and
you shouldn't have to pull in architecture rules just to fix a bug in an
unstructured script.

**`skills/igiari-tdd/`** — one-test-per-step TDD, framed for an AI
specifically: baby steps exist for *containment* (capping the blast
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

Reframed the cycle as Red / **Super Green** / **Refining Refactor**, not
the classic Red / Green(dirty) / Refactor — for an AI, "green" should
already be minimal *and* clean, since writing it dirty on purpose has no
design payoff (it only creates mess a later step must notice and might
quietly skip) and refactor becomes refinement of structure across cycles,
not cleanup. Concretely this added: (1) a "triangulate before
generalizing" clause on the minimal-implementation rule — never introduce
a loop/recursion/abstraction on one test's strength; wait for a second
test that a hardcoded/single-branch implementation genuinely can't
satisfy; (2) an "advanced refinement" tier on top of the existing
refactor checklist, gated by concrete trigger thresholds (3rd same-type
conditional → polymorphism, duplicated validation across 2+ call sites →
value object, 3rd reason-to-change on a class → split it, 3+ branches on
the same discriminant → Strategy) rather than left to open-ended
judgment, since open-ended judgment repeats the same anticipation problem
one altitude up; (3) a "log, don't ask" rule for a refactor candidate
that hits no trigger — noted inline in that cycle's refactor summary (not
applied, not asked about), then rolled up into a single "Deferred
refinement notes" list printed once at the end of the task alongside the
one-time full build, so judgment calls are visible without interrupting
the cycle. Trigger thresholds are defaults the author can tune, the same
way the preferences above have grown over sessions.

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

**`skills/chottomatte-archi/`** — dependency inversion via
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
interface. Needing to mock a static method is treated as
a design smell, not a testing inconvenience — it means the code reached
for a static dependency directly instead of an interface, same violation
as the constructor-injection rule, just spotted from the test side. Fix is
to wrap it behind an owned interface and inject an adapter, mirrored as a
mocking-preference note in `igiari-tdd`. Exception: a static you
don't own (JDK, a third-party library) where wrapping is out of scope —
mocking it is an accepted last resort there. Sharpened further: the actual
line isn't "static," it's determinism — a pure static (`Math.max`,
`Collections.emptyList`) is fine to call directly, but a non-deterministic
one (`Instant.now()`, `UUID.randomUUID()`, `Math.random()`) always needs
wrapping behind an owned interface (`Clock`, `IdGenerator`), since a test
can never pin an expected value on a call that isn't repeatable.

Repositories return the domain object
itself (`Option<Entity>`/`Entity`/`List<Entity>`), never a primitive or
partial projection, since the use case almost always needs the whole
object to build its response. The use case's output is its own `Response`
object, built via an explicit mapping step, never the domain entity
returned directly. Input naming is CQRS-flavored but naming-only (no
separate read/write models implied): `Command` for a mutating use case
(thin response — id/ack, not data back), `Query` for a read-only one
(response is the data), `Request` as the generic fallback. Mappers are
scoped one-per-domain-type (not one-per-use-case/response) and reused
across both directions — outbound (domain object → `Response`, the normal
case) and inbound (`Command`/`Request` → domain object, only when the use
case must hydrate one before calling a repository/service); a `Response`
assembled from multiple repositories composes each entity's own mapper
output rather than one combined multi-arg mapper. Added a "Relationship to
DDD" framing: Clean Architecture governs dependency direction, DDD's
tactical patterns (Entities/Value Objects/Aggregates with real invariants)
govern what lives inside the domain layer that direction protects — the
two are orthogonal and composable, same as this skill's relationship to
`igiari-tdd`, and the outbound mapper doubles as the DDD rule of
never letting an aggregate leak past its boundary. Added a "Heavy ECM/
legacy SDKs (Nuxeo, Documentum, etc.)" framework example: the fix for an
expensive-to-wrap SDK type (`DocumentModel`, `IDfSysObject`) is a
narrowly-scoped port (only the methods actually called), not relaxing the
dependency rule; a framework-instantiated entry point (a Nuxeo
`EventListener`) is the existing legacy-entry-point seam — stays
framework-flavored at its outer edge but immediately translates into a
`Command` and hands off to a use case that never sees the framework, and
any framework-forced static lookup (`Framework.getService(...)`) stays
confined to that translation code, never reaching the use case. Carved out
one explicit judgment-call exception (logged via the skill's existing
improvement-proposal format, not decided silently): a step with no
domain concept beyond the ECM's own model doesn't need a full wrapper.
Added a paired "Testing across the seam" note: use case tests stay pure
unit tests (no framework runtime), adapter/listener tests exist only to
prove the translation and use the framework's own embedded test harness
where one exists (Nuxeo's `FeaturesRunner`/`@Features(CoreFeature.class)`);
flagged Documentum as unresolved — no known embedded-runtime equivalent,
DFC's `IDfSysObject`/`IDfSession` are mockable as interfaces but mock
fidelity against real behavior is unverified, consistent with
`mujitsu-documentum`'s own unverified status.

A case of a static-only utility class
(`PeppaService`) needing configuration values passed into its methods
surfaced a Parameter Object rule — bundle shared config into one named
value object (e.g. `PeppaConfig`) from the first config value, not a loose
primitive/collection (a raw `Set<String>`), since a config object keeps
every method signature on the call chain stable as fields are added later,
while a loose collection forces every signature to change again. Framed
its relationship to the Reader monad explicitly: passing a config object
down a call chain by hand is manual/"poor man's" Reader (same intent —
defer/centralize where an environment is supplied — without monadic
`map`/`flatMap` plumbing), not the Reader monad itself; Vavr has no
`Reader` type, so building one is solving a problem constructor injection
already solves for free in OOP. Added the sharper fix where available: if
the class can stop being static-only, inject `PeppaConfig` via constructor
once and read `this.config` from instance methods — this removes the
threading problem rather than just improving it, and is the default;
static-plus-parameter-object stays the fallback only when the class is
genuinely forced to stay static (called from places that can't hold an
instance).

From a Gemini CLI dogfooding report:
sharpened the skill's frontmatter description to trigger on "building or
extending a real feature/use case with collaborators, dependencies, or
configuration to wire" rather than a generic "designing/structuring Java
production code" line, to distinguish it from `igiari-tdd`
(which also covers a bare algorithm/kata with no architecture concerns).
A config/parameter object is a constructor dependency like any other, so
it follows the same "typed as an interface, never a concrete class" rule
as repository/service/logger — no bare-`record`-by-default special case;
the author's own framing is that the interface is the seam/liberty to
substitute later, earned upfront rather than only once a second
implementation is already needed. Added a paired "Environment-driven
config objects" pattern under the Spring framework examples: the core
parameter object stays a plain POJO behind that same interface, and only
the `@Configuration` class reads Spring's `Environment` to build the
concrete implementation from a property string — one instance of the
general rule, not a special case that justifies it. Also added a
"Verifying a structural change: full build, not just the scoped test"
rule: a structural change (new interface, constructor signature change,
static→instance conversion, `@Configuration`/`@Bean` rewiring) has a
wider blast radius than an `igiari-tdd` cycle's scoped build can
catch (a broken composition root or another caller aren't in that test's
compile unit), so a full build is warranted after this kind of change
even when the work itself was done in TDD-scoped steps. Extended that
rule: adding a new constructor dependency with no behavior change still
breaks every existing test that constructs the class directly, and
fixing those call sites (adding the new dependency, typically a new
`@Mock`, to each test's setup) is a mandatory mechanical fix, not
optional just because "no behavior changed."

The two skills stayed cross-reference-free
until now — the author explicitly asked for a pointer between them, since
they're a real, known relationship (TDD governs *how you write code over
time*, Clean Architecture governs *how it's structured*) even though
they're deliberately kept decoupled (see the intro above). Added a short
"Related skill" note right under each `SKILL.md`'s title heading, before
any rules — one line naming the other skill, its orthogonal concern, and
when to load it too. Deliberately kept to that one line each, not a shared
"how they relate" section duplicated in both files, so the pointer aids
discovery without making either skill require or auto-load the other.

A single Kafka computation that dispatches
to three distinct SOAP operations (`creerDocument`, `creerRevision`,
`changerStatut`) prompted the question of whether this should be one use
case or three. Settled: when a single infrastructure entry point handles
multiple **distinct** business operations discriminated by a type field,
use an **orchestrator use case** that routes to specific use cases — not
one fat use case routing inside it. Each specific use case gets its own
typed `Command` with no nullable fields (only the fields that operation
actually needs). The orchestrator's jobs are: (1) map the raw input to the
right typed `Command`, (2) delegate to the right specific use case,
(3) own the cross-cutting concerns (retry, audit, metrics, status store)
that apply regardless of which operation ran. The infrastructure entry point
only ever knows about the orchestrator — routing stays in domain code, not
infrastructure. Added as a subsection "Orchestrator use case for
discriminated entry points" under "From scratch: the use case is the
entry point", with a code example and a "when to split vs. keep one use
case" heuristic: split when any variant develops its own validation,
error handling, or pre/post-conditions; stay merged when all variants
differ only in which fields are sent.

A question about coping with a Nuxeo use
case that performs many Nuxeo actions — with real integration tests being
slow, and mocking Nuxeo/`CoreSession` being unreliable — settled that the
existing hybrid (in-memory-faked `DocumentRepository` for use-case tests,
`FeaturesRunner` only at the adapter/listener seam, per the already-
documented "Testing across the seam" section) is the right approach, and
sharpened it further: pull every piece of *deterministic* computation a
Nuxeo action needs out of the Nuxeo-touching code entirely, so it needs no
port, no fake, and no Nuxeo runtime at all — only genuine reads/writes
against Nuxeo stay behind `DocumentRepository`. Added a worked example,
"Pulling deterministic computation out of the seam," under the Nuxeo
section: a document business ID assembled from today's date and a random
fragment (a case the author has seen repeatedly) splits into the
non-deterministic inputs (wrapped behind `Clock`/`IdGenerator`, per the
skill's existing determinism rule) and the pure assembly logic (a plain
`DocumentBusinessIdPolicy` class/Value Object, unit-tested directly with
fixed fakes for the two inputs, asserting the exact output string — no
repository fake or `FeaturesRunner` needed for that class at all). Net
effect: as a listener's Nuxeo-action count grows, the pure-computation
share of its logic should grow with it, keeping the `FeaturesRunner`
integration-test surface flat rather than growing with every business rule.

The author's experience using a gateway
interface before the real integration existed prompted a new "Gateway
stand-ins: Logging and No-Op implementations" section in
`chottomatte-archi`. A `LoggingXGateway` (logs the call and all
parameters instead of making the real call) and a `NoOpXGateway` (does
nothing) are both ordinary implementations of the same gateway interface,
swappable at the composition root exactly like an in-memory repository
stands in for a JPA one — with a note to treat either as a placeholder,
swapped out for the real adapter once it exists rather than left wired
permanently, and a distinction from `igiari-tdd`'s
Mockito-for-gateways preference (a mock lives for one test; a
Logging/No-Op gateway is wired for a real environment or code path with
no test running).

A follow-up question — switching
implementation via a Nuxeo property produces an ugly `if`, and there's no
Spring `@Profile` to reach for — added a "Without Spring (e.g. Nuxeo): a
plain resolver instead of `@Profile`" subsection right after
"Environment-driven config objects." Same fix as that section, minus the
annotation: the branch lives in exactly one resolver function at the
composition point (`Framework.getProperty(...)` inside `handleEvent`, the
same seam already used for `Framework.getService(...)`), returning
whichever gateway implementation applies; the use case's constructor only
ever sees the interface. Framed as the general-purpose sibling of "Gateway
stand-ins": there the two implementations are
a stopgap for a not-yet-available integration, here they're two
permanently-maintained variants selected by config, but the fix — the `if`
belongs at the composition point, never inside the use case — is the same
either way.

A real question from Nuxeo addon work —
how to activate a custom log4j2 config without ever touching Nuxeo's
shipped `log4j2.xml` — settled as a new "Nuxeo addon logging" subsection
under *Framework examples*. The mechanism is Log4j2's own Composite
Configuration (not Nuxeo-specific), triggered one of two ways depending
on what you control: `-Dlog4j2.configurationFile=file1,file2` via
`JAVA_OPTS` in `nuxeo.conf`/the Docker image if you own the deployment,
or — the addon-native, env-independent default — a fragment shipped as a
classpath resource inside the addon jar, merged programmatically at
`applicationStarted` via `Configurator.reconfigure(new
CompositeConfiguration(...))`. Follow-up surfaced a real tradeoff: the
jar-embedded form isn't hot-editable, since Log4j2's `monitorInterval`
file-watcher needs a real filesystem `File` a jar resource can't provide
— rebuilding/redeploying is the only way to change its content. That
prompted separating two concerns with opposite lifetimes: the baseline
config (survives restarts, defined programmatically) versus a temporary
production debug bump (should *not* survive, reached for only during an
incident). Per the author's explicit call, the skill documents both live
level-change mechanisms — JMX (free, needs a reachable JMX port) and a
small Automation operation wrapping `Configurator.setLevel(...)` (needs
only Nuxeo's REST API, securable to Administrators, no exec/file access
into the container) — as options with named tradeoffs for whoever
operates the addon to pick between, rather than the skill prescribing one.
An external-override-file variant is named as the escape hatch for the
narrower case of needing live *structural* changes (new
appenders/filters), not just a level bump.

Immediate follow-up correction, from a real integration-environment
constraint the author raised: that override-file variant, as first
worded ("checked at `applicationStarted`, falling back to the
jar-embedded default"), silently breaks in an ephemeral/immutable
container — ops has exec access into the running instance, but
restarting means the orchestrator destroys and recreates it from the
image, so anything placed by hand has to survive with *zero* restart of
anything, ever. Log4j2 only watches a `ConfigurationSource` already
loaded into the composite at boot; a file that didn't exist yet at
`applicationStarted` was never handed to it, so creating one afterward
inside the still-running container is invisible regardless of restarts.
Fixed by flipping the rule: the override path must always be seeded into
the composite at boot (even as an empty stub) with `monitorInterval` set
on it, never created on demand — that's what makes "exec in, edit the
file, no restart of app or container" actually true rather than only
true when a restart happens to be available.

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
calculators) exercises `igiari-tdd`; something shaped like a
real use case with real collaborators (a repository, a service, a
logger) exercises `chottomatte-archi`'s DIP/constructor-injection/
seam rules. Treat any friction — an ambiguous rule, a step that doesn't
produce the right behavior, a bug the rules should have caught but didn't
— as a direct signal to fix the SKILL.md, not just the kata code. First
run: the roman-numeral kata (int → roman numeral, wrapped in a use case
with an injected repository and logger) surfaced the `@Mock`
field-initializer trap now documented in `igiari-tdd`. Second
run: the String Calculator kata (no collaborators at all), solved under
Gemini CLI, surfaced that the `@BeforeEach`-construction rule read as
conditional on mocks being present — a mock-free class quietly reverted
to `new StringCalculator()` inline per test method. The rule in
`igiari-tdd` was broadened to state `@BeforeEach` construction
as the unconditional default (single source of truth for wiring the
SUT), with the `@Mock`-null trap kept as one reason among others rather
than the only one.

Third run: a Gradle-based Java project, solved under Gemini CLI, surfaced
that scoped-test evidence (rule 7/8) can become unobtainable through no
fault of the agent — Gradle reported "no tests ran" even after
`--rerun-tasks`, and the test report files under `build/` were unreadable
because `build/` was gitignored and the client respects `.gitignore` for
file reads. Root-caused as structural rather than a one-off: build output
dirs (`build/`, `target/`) are gitignored by near-universal convention, so
report-file reads will keep failing on any Java project, on any client that
honors `.gitignore` — not specific to Gemini CLI. Added a "Getting evidence
when the build tool fights you" section to `igiari-tdd`: read
console output instead of report files first (`--console=plain -i` for
Gradle; Maven already does this by default), check the test filter pattern
before suspecting caching if zero tests ran, and only fall back to
"full build once, trust console's per-test line or, failing that, the exit
code" as a logged last resort — never a silent one, and never a first
reach. The author's framing that shaped this: a rule should never be broken
silently, but a workflow with zero fallback for a genuine environment
failure just forces the agent to freeze or lie, so the fix is an escalation
ladder with real remedies tried first, not removing the fallback.

A runtime-transparency/control gap the
author raised directly — during an actual TDD or clean-architecture
session, decisions were happening (which tests, what structure) without a
review point before code got written, and stopping mid-session (the
session's own interrupt control) only catches a bad direction *after* it's
underway. Fixed per-skill rather than as a meta CLAUDE.md rule, since the
right checkpoint shape differs by skill: `igiari-tdd` got a new
"Plan the tests before the first cycle" section — list every planned test
as name + one-line intent (no code) before RED on test 1, one approval
gate, then run every cycle straight through with no further per-test
check-ins (the author explicitly chose this over per-test confirmation or
dictating tests themselves — approve the list once, then let the cycles
run). `chottomatte-archi` got a "Plan the structure before
implementing" section — classes/interfaces/ports, constructor
dependencies, composition-root wiring, **and public method signatures**
(the author's pick over structure-only), no bodies, one approval gate
before implementation starts. Both plans allow exactly one further pause
each: a genuine deviation from the approved plan discovered during
implementation, shown and re-approved before resuming — never silent
substitution. Cross-referenced: when both skills are loaded, the
clean-architecture structural plan comes first and the TDD test plan is
written against it rather than re-derived, so a task doesn't produce two
overlapping upfront plans.

A worked example was added right after
the "Plan the tests before the first cycle" section, prompted by the
author asking to make explicit that seeing the whole plan doesn't license
building ahead of the current test. It reuses the plan's own
StringCalculator example — implementing test 1 while tests 3/4 (visible on
the approved plan) already imply a split-and-sum loop — and shows a bad
version that jumps to the general implementation early versus the minimal
one rule 5 requires, closing the same "plan is visibility, not permission"
point rule 5's triangulation clause already made in the abstract.

Two Nuxeo-specific operational rules
surfaced while the author started real Nuxeo work, added to the "Heavy
ECM/legacy SDKs" example. (1) Sharpened the existing static-lookup bullet
with the *why*: `Framework.getService(...)` (and building a
`CoreSession`-backed adapter) must never happen in an `EventListener`'s
constructor, since listener instances are created during
component/bundle registration before the runtime guarantees every
service has started, and `CoreSession` is request/transaction-scoped and
doesn't exist yet at construction time — both are resolved inside
`handleEvent` instead, meaning the repository/gateway adapters and the
use case are constructed per-invocation there, not once in the
constructor. (2) A new "Syncing Nuxeo to an external system" pattern:
pushing a changed document to another system over REST is a genuine
clean-architecture candidate (real logic to isolate: what to sync, how
to map it, how to handle failure) unlike the trivial-transition overkill
exception, but needs two separate ports rather than one repository
stretched both ways — `DocumentRepository` (reads the domain object from
Nuxeo, the system of record) and a distinctly-named gateway/service port
(`SyncGateway`, pushes to the external system, Mockito-mocked like any
other gateway/client, not in-memory-faked like a repository) — composed
in the use case via an outbound mapper, same per-domain-type mapper
convention as elsewhere in the skill.

## mujitsu-documentum

`skills/mujitsu-documentum/` is unverified — written from
general Documentum DQL/API knowledge, not yet run against a real docbase.
Treat every pattern in it as a draft until the author reports back from
real usage; don't cite it as settled the way the two Java skills above are.

The gap it targets: individually, DQL and the API (`iapi`/`idql`) are
well-documented and widely known; composing the two into a bash script
that's safe to re-run — existence-check before `create`, surviving a
partial failure, converging to the same end state across dev/test/prod —
is the part that isn't. That's the same shape of gap the two Java skills
above fill (tacit operational knowledge, not syntax), just for a different
domain.

**Testing method: real docbase, not kata.** Unlike the Java skills' kata
dogfooding, there's no throwaway-project equivalent for a
Documentum skill — it needs a live docbase to mean anything. The author
will validate it by using it against a real Documentum environment and
reporting friction back. Known-weak spot going in: pattern 4's
`get_type_attr_count` in the SKILL.md is a named placeholder, not real
DQL — the exact query for enumerating a type's attributes varies by
Documentum version and hasn't been confirmed. Any correction from real
usage should land as an edit to
`skills/mujitsu-documentum/SKILL.md` plus a note here, the
same discipline as the Java skills' entries above.

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

## gyakuten-ddd

`skills/gyakuten-ddd/` is new (created from a request
to fold Eric Evans' *Domain-Driven Design* strategic-design chapter —
summarized in Avram & Marinescu's *DDD Quickly*, which the author shared —
into a skill). Not yet dogfooded; treat it the same as
`mujitsu-documentum`'s unverified status until it's been
exercised on a real multi-context design.

**Scope decision:** DDD splits into tactical patterns (Entity, Value
Object, Aggregate, Repository, Factory — structuring *one* model) and
strategic patterns (Bounded Context, Context Map, Shared Kernel,
Customer-Supplier, Conformist, Anticorruption Layer, Open Host Service,
Separate Ways, Core Domain distillation — structuring the *boundaries
between* models/teams/systems). Tactical patterns already live in
`chottomatte-archi`'s "Relationship to DDD" section (Java-specific,
folded in rather than split out, since a repository/aggregate/entity is
inseparable from that skill's dependency-direction rules). Strategic
design got its own skill instead of also folding into
`chottomatte-archi`, for two reasons the author confirmed: (1) it's
a genuinely different altitude of concern — "where does one model end and
another begin" is not a single-model dependency-direction question — and
(2) unlike the two Java skills, it's language-agnostic (Bounded Context,
Ubiquitous Language, Context Map apply to any stack), which fits this
repo's portability goal better as a standalone skill than as a section
bolted onto a Java-flavored one.

**Trigger design:** the author also wants this skill to work as a learning
aid (they're learning DDD themselves), not just enforcement — so the
frontmatter description and a "Learning mode" section both trigger on
explaining a term on request ("what's a bounded context"), not only on
applying the patterns during real design work. Cross-referenced from
`chottomatte-archi`'s "Related skills" note (one line, matching the
existing `igiari-tdd` cross-reference style — not a shared
section duplicated in both files).

Expect this to grow the same way the two Java skills did: from real usage,
not from re-reading the source book. No testing method decided yet beyond
`make validate`; a kata-equivalent for strategic design would need a
multi-context scenario (e.g. designing the boundary for a legacy/
third-party integration) rather than a single-class kata.

## kaizen-refactor

`skills/kaizen-refactor/` is new. The author
described a phase distinct from both existing Java skills: refactoring
code that already *exists*, surfaced by inspecting it in IntelliJ IDEA
rather than by a failing test — sometimes the safe next step is an FP-style
change, sometimes it isn't, so it couldn't just be folded into
`kanpeki-fp`. It also isn't `igiari-tdd`'s refactor step, since that step
only fires on code just written this cycle inside a red/green loop, not on
a standalone pass over existing code with no new test being added.

**Two-tier split:** Tier 1 (IDE-verified mechanical
refactorings — rename, extract, inline, move, plus the fixed syntax-level
set: stream `.toList()`, lambda cleanup, method references, `var`, diamond
operator, pattern-matching `instanceof`) applies directly, no gate, since
the IDE's own transformation guarantees the behavior is preserved. Tier 2
(judgment-call refactors — polymorphism, value object, split class,
Strategy, or any `kanpeki-fp`-governed style move) stays gated by the same
trigger-threshold discipline as `igiari-tdd`'s "Advanced refinement"
section, plus a test-coverage safety net (confirm a green baseline, one
change at a time, re-verify green after each) — since unlike Tier 1, the
IDE alone can't prove these preserve behavior.

**The mechanical-syntax checklist moved here from `igiari-tdd`**,
by the author's explicit call, since the same list applies
whether you're mid-TDD-cycle or refactoring existing code outside one —
`igiari-tdd` now references this skill's "Tier 1" section instead of
carrying its own copy, so there's one source of truth instead of two
lists that could drift apart.

Not yet dogfooded; treat it the same as `mujitsu-documentum` and
`gyakuten-ddd`'s unverified status until it's been exercised on a real
refactoring pass (a class or module with an IntelliJ inspection report
run against it, both tiers exercised, a Tier 2 change actually caught by
the test-coverage safety net).

The workflow's step 1 originally said
"Analyze → Inspect Code," a GUI menu path with no scriptable output —
the author asked whether a command-line equivalent exists. Confirmed and
added: `qodana scan` (JetBrains' CI-oriented headless inspector, same
engine, one consolidated report — preferred when available) and
`idea inspect`/`inspect.sh` (bundled with the IDE itself, one XML file
per inspection, needs a configured SDK and no other running instance of
the same IDE) as the two real headless options, in that preference
order, replacing the GUI-only phrasing.

The author asked whether igiari-tdd's
refactor step also needs to launch the IDE/scan tooling now that its
mechanical checklist lives in `kaizen-refactor`. Answer: no — that
checklist is a fixed, read-and-apply list, not something a scan needs to
surface; only `kaizen-refactor`'s own workflow (triaging a fresh
inspection report over *existing* code) uses `qodana scan`/`idea inspect`.
The wording in igiari-tdd rule 6 was ambiguous on this point ("load that
skill for the list" read as "run its scan") — tightened to say explicitly
that this step never triggers a scan.

A concrete Tier 1 addition: `list.get(list.size() - 1)` /
`list.get(0)` → `.getLast()`/`.getFirst()` on a `List`/`Deque`/any
`SequencedCollection` (Java 21+), spotted during real refactoring work.
Used it to add a "Recognizing new Tier 1 candidates" section — the
skill's own mechanism for growing its fixed mechanical list — gated by
three checks (fixed input → fixed output, JDK/library-guaranteed
equivalence, recurs across classes rather than a one-off); a candidate
that passes all three is added to the list and logged via the skill's
existing "Skill improvement proposal" format rather than applied and
forgotten. The `getFirst()`/`getLast()` entry itself is the worked
example showing the mechanism in use.

Refined immediately after, by the author's call: that entry was carrying
an equivalence claim it doesn't actually meet — on an empty collection
`get(0)` throws `IndexOutOfBoundsException` while `getFirst()` throws
`NoSuchElementException`, which is the exact case the "Guaranteed
equivalence" check names as disqualifying. The entry now states the
non-empty precondition explicitly (and that offsets like `get(size() - 2)`
have no accessor), and the worked example no longer claims a clean pass on
all three checks — it routes through the same section's "say so explicitly"
clause instead. Settled rule: a Tier 1 entry may carry a precondition the
reader can check at the call site, never an unstated one.

## Token cost: progressive disclosure and output discipline

Cross-cutting session, triggered by the author reporting roughly **$100/day**
on Claude while doing genuinely heavy work. The brief was to analyse all
skills and cut token cost drastically. Unlike the sections above this one
touches every skill plus `global/`, so it lives on its own.

**Where the tokens actually were.** An audit found ~28,500 tokens resident
before a single line of the author's code was read: ~4,100 always-on
(`global/CLAUDE.md` plus the `java.md` and `nuxeo.md` it `@`-imported, and
the eight skill descriptions, which are permanently resident by design),
and ~24,400 more the moment a Java session triggered `chottomatte-archi` +
`igiari-tdd` + `kanpeki-fp` together. All of it re-sent every turn.

**Root cause: `references/` was documented but unused.** `CLAUDE.md` listed
`skills/<name>/references/` in the repository layout, and
`validate_skills.py` only ever checks `SKILL.md`, so the directory was
available and validated — but not one skill had one. Every skill loaded
whole. The clearest case was `chottomatte-archi`: of 59KB, ~23KB was
Nuxeo-specific (composite log4j2, platform-seeded vocabularies, addon Maven
packaging) loading on *every* Java session, including plain-Java and Spring
work where it is dead weight.

**Decision: relocate, never delete.** The standing rule that active-work
skills don't get "cleaned up" without the author asking stays in force under
a token brief. Nothing was removed — content moved to `references/` behind a
pointer, and the totals show it: 157.5KB of `SKILL.md` became 130KB resident
plus 47KB of references, i.e. the corpus *grew* by the pointer tables while
what loads shrank.

### The correction: a reference is only cheaper if it's read *sometimes*

The first pass split `igiari-tdd`'s Maven/Gradle build commands into
`references/build-commands.md`. The author asked the right question — *"do
you think that reading gradle or maven costs?"* — and the answer exposed a
real error.

Settled rule, now in every skill's self-audit: **content read on
essentially every trigger costs more split out than inline.** Inline, it
sits in the cached prefix and is charged at the cache-read rate on every
later turn. Split, the same tokens arrive via the tool result anyway, *plus*
an extra assistant turn to decide to read it (output tokens, the most
expensive kind), plus the tool-call overhead, plus they land after the
prefix instead of inside it. `igiari-tdd`'s cycle runs a scoped build every
step, so that reference would have opened in ~100% of sessions. The ~15
lines of actual invocations came back inline; the reference kept only what
is genuinely occasional — the evidence escalation ladder, mvnd daemon
timings, Gradle cache-honesty analysis, the Maven crossover math.

A second instance of the same mistake, found by applying the new rule to
the other five references: `testing-across-the-seam.md` is ~90% Nuxeo
`FeaturesRunner` and Documentum/DFC detail and *is* correctly conditional,
but its pointer read "writing tests that cross the interface boundary" —
broad enough to open it on every seam test. Corollary rule: **the split can
be right and the pointer still wrong.** A pointer must name the condition
narrowly enough to decide from without opening the file. The universal
two-tier rule (use case tests stay pure unit tests; adapter tests only prove
translation) moved inline, and the pointer now names the framework case.

Read-rate estimates for the remaining references are just that — estimates.
`ecm-ports.md` and `spring.md` are the ones to watch: if the author is
nearly always on Nuxeo/Documentum, `ecm-ports.md` will open most sessions
and belongs back inline by the rule above. With no `evals/` directory on any
skill there is no automated way to measure this; a real session opening a
reference you expected it to skip is the signal.

### Command output is tokens too — and it repeats

The author's follow-up — *"gradle command display lots of log, is it
considered as token?"* — turned out to be the larger lever, and reframed the
whole exercise.

It is, and it is worse than skill text in three ways: skill text is a stable
cached prefix (paid once, ~10% thereafter) while build output lands in the
growing suffix at full rate; it repeats **every cycle**, and `igiari-tdd`
builds on every red and every green; and it scales with the size of the
author's project rather than the size of the skill. Ten cycles of a chatty
Gradle run can plausibly out-cost the entire trimmed skill set. Sharpest
detail: `igiari-tdd`'s own evidence escalation ladder recommended
`./gradlew ... -i` as its *first* rung — INFO logs every task and every
dependency resolution, a token bomb sitting inside a loop. Now gated behind
plain console genuinely showing nothing, for one diagnostic run, then
dropped.

Standing rules added: Maven always `-B --no-transfer-progress`, Gradle
always `--console=plain`, both bounded with `tail`; and **on green, the
summary line plus exit 0 is sufficient evidence for rule 8** — don't echo
the run. Unfiltered output only while diagnosing an actual failure, and only
for that run. (Accepted trade: `2>&1 | tail -30` can truncate a startup or
dependency-resolution failure, which needs one unfiltered rerun. Fine for an
assertion failure, where the message is at the end.)

An audit of all eight skills for commands whose output reaches context then
found three more, and the three recurring *shapes* are the useful outcome:

1. **A verbosity flag inside a loop** — Gradle `-i`, `idea inspect -v2`.
   Cost multiplies by iteration count.
2. **A machine-readable report read raw** — `kaizen-refactor` pointed at
   `qodana.sarif.json` as "a report you can read and triage". SARIF nests
   every finding and repeats full rule metadata, so a whole-project report
   reaches megabytes and can cost more than the refactor it is guiding. Now:
   scope the scan, `uniq -c` by `ruleId` first to see the shape, then one
   line per finding via `jq`.
3. **Per-item success logging** — `kurae-bash`'s `expect_eq` printed a line
   per *passing* assertion (200 lines of nothing for a 200-test suite); a
   Documentum bulk loop echoing per object over 100k objects is 100k lines.
   Report failures plus a one-line total; let exit status carry the verdict;
   echo once per packet, never once per object.

`chottomatte-archi` was the miss worth recording: it mandates a full build
after any structural change, gave no command, and — by its own rules — that
build's *expected* first result is mass failure, since every test
constructing the changed class breaks at once. The default path was
therefore "run unbounded, read hundreds of stack traces, learn what you
already knew". It now greps the broken call sites out, works that list, and
reads a full trace only for a failure that is not a mechanical constructor
mismatch. `mujitsu-documentum` was already disciplined by habit (`COUNT(*)`,
`grep` at the source, `head -1`) — made deliberate rather than changed.
`gyakuten-ddd`, `kanpeki-fp` and `objection-conception` run no commands.

### The self-audit section, and its honest cost

Every skill gained a **"Token self-audit"** section at the author's request:
is anything here needed only *sometimes* (→ `references/`); is any reference
opened on almost every trigger (→ back inline); does any step run a command
(→ its output owes the same discipline). Plus the two invariants: never
split a rule from its own statement, and relocate rather than delete, since
dropping guidance to save tokens is a regression, not a saving.

This is self-referentially expensive and was accepted knowingly: ~1,100
chars per skill, so a three-skill Java session gives back ~830 tokens
against ~10,000 saved, about 8%. Justified as the mechanism that stops the
files regrowing — but it is a real cost, and trimming it to two bullets is a
legitimate future call.

### Global config

`global/CLAUDE.md` `@`-imported `java.md` and `nuxeo.md` unconditionally, so
8.5KB of Java and Nuxeo platform rules loaded into every session regardless
of subject — including bash, markdown and Python work, and including
sessions in this markdown-only repo. Both are now pointed at, to be read on
demand when a session turns out to match. They still install verbatim;
`install-global.sh` keeps copying them, since a missing file would leave the
pointers dangling.

`CLAUDE.md`'s four "Active work" blocks, which restated rules each
`SKILL.md` already owns and this log already explains, were condensed to a
state table plus the cross-skill rules that live nowhere else (19.5KB →
12.7KB). The progressive-disclosure convention itself was written into
`CLAUDE.md`'s layout section so new skills keep `SKILL.md` small instead of
regrowing.

**Net:** a Java session went from ~97.7KB to ~65.9KB of resident
instructions (~24,400 → ~16,500 tokens), after deliberately spending some of
the saving back on inlined hot-path commands and the self-audit blocks.

**Flagged, not done.** The skill descriptions (~4,645 chars, permanently
resident across all eight) are a real target but trimming them is a rewrite
that risks mis-triggering, so it was left under the session's relocate-only
brief. Beyond the repo, the two larger levers on a $100/day habit are
session hygiene (the global "warn when context is heavy" rule is advisory;
making it a concrete threshold would likely beat everything done here) and
model routing (`settings.template.json` pins one model, but validation,
commit messages and log edits don't need the largest one).

### Running the inner loop through the IDE instead of the build tool

Author's idea, from the same session: TDD is normally done in the IDE — could
`igiari-tdd`'s cycle use it, and would it save tokens? Yes on both, and it is
probably the largest saving still available in this skill, because it applies
*per cycle* rather than once.

What you pay per cycle is whatever the test run returns. A bounded build run
(`mvn -B --no-transfer-progress test -Dtest=X | tail -30`) still costs ~20-30
lines of surefire banner, reactor summary, BUILD SUCCESS and timing — roughly
300-600 tokens. An IDE runner reached over MCP returns a structured result —
test name, status, and on failure the assertion message and line — for perhaps
30-80 tokens green. Call it 5-10× per cycle, multiplied by cycle count, and it
recurs on every task, unlike the one-time file trimming. A build tool spends
most of its output describing the build; the IDE already compiled and indexed,
so it only describes the test.

A cost already sunk in this author's case, worth stating because it is not
obvious: connecting an MCP server puts its tool schemas in the system prompt of
*every* session, a fixed resident cost. Adding the JetBrains server purely for
this could fail to pay off. `kaizen-refactor` already uses it for inspections,
so the overhead is paid and the per-cycle saving is pure gain.

Written into the skill as **unverified**, the same status as
`mujitsu-documentum`, gated on two one-time checks per project:

1. **Does the server expose a test runner at all?** `kaizen-refactor` only
   documents `mcp__idea__lint_files` and `mcp__idea__get_file_problems` —
   inspection, not execution. Unconfirmed from this session, which had no IDE
   MCP reachable.
2. **Does the IDE runner agree with the build?** The one that actually
   matters. An IDE run may not apply surefire's `argLine` (JaCoCo,
   `--add-opens`), system properties, active profiles or resource filtering.
   If the IDE passes where `mvn test` fails, every red and green in the cycle
   is unreliable and the skill's core guarantee is gone. Settled rule:
   **correctness of the red is not negotiable for a token saving** — where
   they diverge, the build tool wins.

Scope limit recorded with it: this replaces the *scoped* run only. Rule 7's
terminal full build and `chottomatte-archi`'s post-structural-change build stay
build-tool jobs, since an IDE run proves a test passes, not that the reactor,
packaging and composition root still build. The bounded commands stay as the
fallback for no-IDE, CI and fresh-machine cases — framed portably ("if your
client exposes an IDE integration") per the repo's tool-agnostic rule, with
`kaizen-refactor`'s naming of `mcp__idea__*` as the precedent.

**Separate finding, larger than the skills.** `global/settings.template.json`
pins `"model": "opus[1m]"`. The cached pricing table puts Opus 5 at $5/$25 per
MTok with 1M context standard, and no long-context premium was confirmed — so
the cost issue is not the rate but the *ceiling*: a 200K window forces a fresh
session, while 1M lets one balloon five times larger, with every turn
re-sending all of it. Flagged to the author as plausibly outweighing everything
done in this repo, and left as their decision.

### Eval suites for the two Java skills, and the model question

`make eval` had been wired up since the start with no skill ever having an
`evals/` directory — the infrastructure existed, unused. Written now because
the session's open question ("should I move to Sonnet?") is a measurable one
and guessing at it is exactly what that infrastructure was built to avoid.

Six cases, three per skill, chosen so each targets a rule the skill uniquely
causes — which is what makes the with/without ablation delta mean anything. A
case testing "writes a test first" would score well without the skill too and
tell us nothing.

**`igiari-tdd`** — `plan-then-one-test` (the test-plan approval gate, exactly
one failing test first, `should<X>_when<Y>` naming; the grader explicitly
states that stopping at the plan is a PASS, not an incomplete answer, and that
delivering the whole feature is the failure being detected);
`triangulate-before-generalizing` (one red test for `RomanNumeral.of(1)` — a
loop or lookup table fails the case even though it is correct code, since
solving ahead of the current test is the defect); `scoped-build-and-evidence`
(scoped to one test, `-B`/`--no-transfer-progress`, bounded output, and a real
observed red rather than a non-zero exit code).

**`chottomatte-archi`** — `plan-structure-first` (the structural approval gate,
plus Spring kept out of core and the existing `MailSender` bean reached through
an owned interface); `invert-nondeterministic-dependency` (the skill's precise
line: `Instant.now()` and `UUID.randomUUID()` go behind owned ports while
`Math.max` is deliberately left alone — the case fails an answer that wraps
`Math.max`, or that justifies wrapping on "static" rather than
non-determinism); `repository-returns-domain` (a `String
findCustomerNameById` that must become a `Customer`, with the use case
mapping to its own `Response` rather than returning the entity).

Validated rather than handed over untested: one case run end to end scored 1.00
at **$0.27 for a single run**. That price is the thing to note — the default is
3 runs per case and the ablation adds a second arm, so a full `make eval` over
six cases is roughly **36 runs, on the order of $10**. Not a per-commit CI
check at that cost; `--case`, `--runs 1` and `--ablation none` are the cheap
smoke-test path, and `--max-cost-usd` bounds any run. `skills/*/evals/results/`
is gitignored — transcripts and the HTML report are regenerated output.

The model question these exist to settle: `claude plugin eval --model <model>`
runs the same suite against a different model, so "does Sonnet follow these
skills as well as Opus?" becomes a score comparison rather than a judgment
call.

**Asked and answered: should the skills detect the model and adapt?** No, and
they should not try. A skill is markdown with no runtime — it cannot query the
serving model, and self-reported identity is unreliable in exactly the way that
matters (a session's configured model and the model actually serving a turn can
differ, through fallback or a mid-session switch). Even given a reliable
answer, branching a skill on model identity doubles its behavioral surface and
leaves the branch that runs on the cheaper model the less-tested one — the
opposite of what these skills are for, which is removing judgment from the
model by writing the rule down once. The routing decision belongs outside the
skill, with the person choosing the model, informed by eval scores. What a
skill may legitimately carry is a statement of what it *assumes* — and both
already do, in their non-negotiable rules.

### First eval run: Sonnet vs Opus, and what it actually measured

Ran both suites against both models, `--ablation none --runs 3`. Total spend
about $10. Headline: **the Sonnet-vs-Opus question is not settled by this run**,
because grader wording moved the scores more than model choice did.

Raw numbers (igiari-tdd on its original graders; chottomatte-archi's
`invert` case on its third grader revision):

| case | Sonnet | Opus |
|---|---|---|
| `triangulate-before-generalizing` | 1.00 | 1.00 |
| `plan-then-one-test` | 0.75 | 0.50 |
| `scoped-build-and-evidence` | 0.89 | 0.89 |
| `repository-returns-domain` | 1.00 | 1.00 |
| `plan-structure-first` | 0.67 | 0.87 |
| `invert-nondeterministic-dependency` | 0.67 | 1.00 |

Cost per suite run: igiari-tdd $1.46 Sonnet / $2.95 Opus; chottomatte-archi
$1.03 / $2.76. Consistently ~2x, as list pricing predicts.

**Two grader bugs, both of which penalised the *better* answer.** This is the
run's real finding and it generalises beyond this repo.

`invert-nondeterministic-dependency` went 0.00 → 1.00 → 0.67 for Sonnet and
0.33 → 0.33 → 1.00 for Opus across three grader revisions, with no change to
the skill or the prompt:

1. The first grader said `Math.max` must be "left alone", and the judge read
   *any* discussion of it as a violation. Both models had correctly declined to
   wrap it while separately arguing the clamp is a correctness bug —
   `nextNumber(c, 0)` and `nextNumber(c, -5)` both mint invoice `00001`, so a
   caller bug is laundered into a duplicate invoice number. A real catch, and
   the grader failed it. Narrowed to judge dependency direction only.
2. The second grader required `UUID.randomUUID()` to be "moved behind a port".
   Opus argued instead that the suffix should be **deleted** — 4 hex chars is
   ~50% collision probability at roughly 300 invoices sharing a
   `(customer, year, sequence)` tuple, so it earns nothing and uniqueness
   belongs in the sequence plus a database constraint. That is a better answer
   than wrapping, and the skill's own logic agrees: a dependency you do not
   need beats a port around one. The grader now accepts removal.

Settled rule for writing graders here: **encode the rule, not the expected
answer.** The failure mode is systematic rather than random — a stronger model
is more likely to produce the better-but-unexpected answer, so a
narrowly-specified grader under-scores it. An eval written this way will
quietly argue for the cheaper model on the strength of its own defects.

**What survived and looks real:** `triangulate-before-generalizing` at 1.00 on
both — Sonnet holds the hardest and most distinctive TDD rule (no loop, no
lookup table, no generalising on one test's strength) as reliably as Opus.
`repository-returns-domain` 1.00 on both. Those two are stable signal for the
hypothesis that `igiari-tdd`'s rule-following survives a cheaper model, while
`chottomatte-archi`'s judgment cases (`plan-structure-first`,
`invert-nondeterministic-dependency`) favour Opus.

**Known-suspect, not yet fixed:** `scoped-build-and-evidence` scores 0.89 on
*both* models with the `real-red` grader failing identically in both. Two
models failing a grader the same way is the signature of the bug above, not of
a shared model weakness — treat that grader as unverified until it is read
again.

Three runs per case is too few to separate a real gap from variance. Before
this decides anything, the graders need the "encode the rule" pass and the runs
need raising.
