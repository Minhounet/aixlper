---
name: chottomatte-archi
description: Enforces dependency inversion via interfaces and constructor injection for Java — use cases as the entry point depending only on repository/service interfaces, with guidance for legacy code where the entry point isn't yours to control. Use when building or extending a real feature or use case — anything with collaborators, dependencies, or configuration to wire together — not for a standalone algorithm or self-contained utility with no external dependencies.
---

# Java Clean Architecture

**Related skills:** `igiari-tdd` covers how you *write code over
time* (test-first, one behavior per step) — this skill only covers how the
code should be *structured* (dependency inversion, constructor injection).
Orthogonal and composable, not a dependency: load the other one too when
writing new code, not just restructuring existing code. `gyakuten-ddd`
covers the boundary *between* models/teams/systems (Bounded Context, Context
Map) — language-agnostic, one level up from this skill's single-model
dependency rules. Load it too once a second model, team, or external system
enters the picture. `kanpeki-fp` covers how logic should be *expressed*
(pure guards, Either/Option, sealed types, no mutation) — load it too when
implementing with functional style, which is the default for this codebase.

## The one principle that matters most

**Dependency inversion, via interfaces.** High-level policy (the use case,
the domain logic) must never depend on a concrete, low-level detail
(a specific database client, an HTTP framework, a logging library). It
depends only on an interface. Concrete implementations of that interface —
adapters — live outside the core and are plugged in from the outside.

Everything else in this skill (constructor injection, the use-case shape,
the legacy guidance) is a consequence of this one rule, not a separate rule.

## Plan the structure before implementing

Before writing any implementation code for a new or extended feature, show
a structural plan — no method bodies, no wiring code, just the shape:

```
Structural plan — RegisterUserUseCase:
- RegisterUserUseCase (use case)
    constructor(UserRepository, EmailSender, Logger)
    + execute(RegisterUserCommand cmd): RegisterUserResponse
- UserRepository (interface, port)
    + findByEmail(String email): Option<User>
    + save(User user): User
- EmailSender (interface, port)
    + sendWelcomeEmail(String email): void
- UserMapper
    + toResponse(User user): RegisterUserResponse
- Composition root: UseCaseConfig.registerUserUseCase(UserRepository, EmailSender, Logger)
    → wires an in-memory/JPA UserRepository + concrete EmailSender + Logger
```

List every class/interface to be created or changed, each one's
constructor dependencies (typed as interfaces per the rule below), and the
signature of each public method — name, parameters, return type, never a
body. Include composition-root wiring (what gets bound to what) when the
plan introduces a new interface or bean. Present this and wait for one
go-ahead — approve as-is, or the author edits the shape — before writing
any implementation.

This is the single pause for the structural shape of the task. Once
approved, implement straight through without re-presenting the plan,
unless implementation forces a real deviation (a signature that doesn't
work once you're in the code, a dependency that turns out unnecessary, a
port that needs an extra method) — then stop, show the deviation and why,
get a quick go-ahead, and resume.

This plan covers *structure*, not *test order*: if `igiari-tdd` is
also loaded, its own upfront test-plan step comes next, listing the tests
that will drive each class/method above into existence — write that plan
against this already-approved structure rather than re-deriving it. A
change that touches no new class/interface/method signature (a bug fix
inside an existing method body, say) doesn't need this plan at all — it's
for structural work, per "Verifying a structural change" below.

## Constructor injection, always

- Every dependency a class needs arrives as a constructor parameter,
  typed as an interface — never a concrete class.
- No field injection, no service-locator or static lookup
  (`SomeStaticFactory.get()`) reached for from inside business logic, no
  `new ConcreteThing()` of an infrastructure dependency buried inside a
  use case or domain class.
- Injected fields are `private final`.
- The only accepted exception is setter injection in a legacy codebase
  where the constructor path is genuinely blocked by existing framework
  wiring — see *Framework examples* below. It's a narrow exception for
  that seam, not a reopening of this rule.

## From scratch: the use case is the entry point

When you control the whole shape:

- One use case **interface** per business operation (e.g. `RegisterUserUseCase`,
  `CancelOrderUseCase`). This *is* the entry point — nothing else sits in
  front of it as far as the core is concerned. The concrete implementation
  (`RegisterUserUseCaseImpl`) is wired at the composition root; callers
  never reference the impl class directly.
- The impl constructor takes exactly the interfaces it needs: repository
  interfaces (e.g. `UserRepository`), service interfaces (e.g.
  `EmailSender`, `PaymentGateway`), and cross-cutting ones like `Logger`.
- The use case orchestrates domain logic. It has no knowledge of
  persistence technology, transport (HTTP/CLI/messaging), or which
  concrete class implements any of its collaborators.
- Concrete adapters (a JPA-backed repository, an HTTP client, an
  in-memory repository for tests, the log4j2 binding) are wired together
  at the composition root (`main`, a framework config class, a test's
  setup) — never inside the use case impl itself.

### Use cases are interfaces, not concrete classes

Apply dependency inversion to use cases themselves, not just to their
collaborators. Callers (a Kafka computation, a REST controller, an
orchestrator use case) depend on the use case *interface* — the impl is
invisible to them.

**Why this matters:** it makes every caller independently testable. A test
for `GemHydroSyncComputation` mocks `CreerDocumentUseCase` (interface) with
Mockito, exactly the way it mocks `GemHydroGateway`. Without the interface,
the caller's test must construct the real impl and its transitive
dependencies — the gateway, the SOAP config, the HTTP client — turning a
caller test into an integration test.

```java
// interface — in the domain/usecase package
public interface CreerDocumentUseCase {
    CreerDocumentResponse execute(CreerDocumentCommand cmd);
}

// impl — constructor-injected, wired at composition root
public class CreerDocumentUseCaseImpl implements CreerDocumentUseCase {
    private final GemHydroGateway gateway;

    public CreerDocumentUseCaseImpl(GemHydroGateway gateway) {
        this.gateway = gateway;
    }

    @Override
    public CreerDocumentResponse execute(CreerDocumentCommand cmd) {
        return gateway.creerDocument(cmd);
    }
}
```

Tests for the impl declare the field as the interface type and construct
the impl directly in `@BeforeEach`:

```java
private CreerDocumentUseCase useCase;

@BeforeEach
void setUp() {
    useCase = new CreerDocumentUseCaseImpl(gateway);
}
```

This keeps the test honest: if a constructor-signature change breaks a
caller, the test catches it.

### Orchestrator use case for discriminated entry points

When a single infrastructure entry point (a Kafka message, an HTTP endpoint
with a type field, a file-based event) handles multiple **distinct** business
operations discriminated by a type field, do not collapse them into one fat use
case. Instead:

- **One specific use case per business operation** — each gets its own typed
  `Command` carrying only the fields that operation needs (no nullable fields
  for "not applicable to this variant").
- **An orchestrator use case** sits in front of them. Its sole jobs are:
  (1) map the raw input to the right typed `Command`, and (2) delegate to the
  matching specific use case. Cross-cutting concerns that apply regardless of
  operation (retry, audit, metrics, status store) live here, not in the specific
  use cases.
- **The infrastructure entry point** (the Kafka `AbstractComputation`, the
  servlet, the event listener) only ever knows about the orchestrator — the
  routing stays in domain code, not in infrastructure.

```
// Orchestrator: maps raw event → typed command → delegates
class ProcessSyncMessageUseCase {
    ProcessSyncMessageUseCase(CreerDocumentUseCase creerDoc,
                              CreerRevisionUseCase creerRev,
                              ChangerStatutUseCase changerStatut,
                              SyncRequestStore store, ...) { ... }

    void execute(GemHydroSyncMessage msg) {
        SoapCallResult result = switch (msg.flowType()) {
            case CREATION    -> creerDoc.execute(toCreerDocumentCommand(msg));
            case REVISION    -> creerRev.execute(toCreerRevisionCommand(msg));
            case DESTRUCTION -> changerStatut.execute(toChangerStatutCommand(msg));
        };
        // ... audit / metrics / store
    }
}

// Specific use case: one operation, one Command, no nullable fields
class ChangerStatutUseCase {
    ChangerStatutUseCase(GemHydroSoapClient soapClient) { ... }
    SoapCallResult execute(ChangerStatutCommand cmd) { ... }
}
```

**When to split vs. keep one use case:** if all variants share the same
pre-conditions, post-conditions, and business rules — and differ only in
which fields are sent — a single use case routing to gateway methods is
acceptable. Split into specific use cases once any variant develops its own
validation logic, its own error handling, or distinct pre/post-conditions.

## Working on legacy code: the entry point isn't always yours

Not every task starts from a clean slate. Sometimes the entry point — a
servlet, a framework-managed controller, an existing legacy class — isn't
something you control or are being asked to restructure right now.

In that case:

- Dependency inversion still applies at whatever boundary you *do* own.
  Don't force the pre-existing entry-point class into the use-case shape
  just to satisfy this skill.
- Any new collaborator class you introduce still depends on interfaces
  and is constructor-injected, even if the class that instantiates it
  (the legacy entry point) still does `new SomeService(...)` itself
  because touching that is out of scope for the current task.
- Find the seam: the boundary between what you're adding/changing and
  what you're not touching. Apply the rule fully on your side of that
  seam; don't let "the entry point is legacy" become an excuse to skip
  it for code you *are* writing.

## Logger

The logger is a dependency like any other: injected via the constructor,
typed as an interface (SLF4J's `Logger`/`LoggerFactory` unless told
otherwise) — never reached for statically from inside business logic.
log4j2 is just the concrete binding behind that interface; the use case
and domain code never know it's there. The instance must still be bound
to the class it logs for, same as a hand-written
`LoggerFactory.getLogger(ThisClass.class)` would be — see the Spring
injection-point example below for how to get that with constructor
injection instead of a single shared logger bean.

## Gateway stand-ins: Logging and No-Op implementations

When a gateway/service you don't yet have access to (an external API not
provisioned yet, a partner integration pending credentials) sits behind an
interface per the dependency rule above, that same interface accepts more
than one throwaway implementation before the real adapter exists — no
different from swapping an in-memory repository in for a JPA one, just for
a service port instead of a repository:

- **`LoggingXGateway`** — logs the call and all parameters instead of
  making the real call. Lets the use case, the composition root, and every
  caller be built, wired, and exercised end-to-end before the real
  integration exists, and doubles as a cheap audit trail once it does.
- **`NoOpXGateway`** — does nothing at all. Useful where the call should be
  silently skipped rather than logged — a disabled environment, a feature
  not yet turned on, a case that genuinely doesn't care about this side
  effect.

Both are ordinary implementations of the gateway interface, bound at the
composition root exactly like the real one would be — which implementation
is wired is a one-line change there, never a change to the use case or its
constructor. Same payoff "the interface is the seam/liberty to substitute
later" already names for config objects: earned upfront by depending on
the interface, not something justified only once the real adapter exists.

```java
public interface PaymentGateway {
    PaymentResult charge(ChargeCommand command);
}

// stand-in while there's no access to the real payment provider yet
public class LoggingPaymentGateway implements PaymentGateway {
    private final Logger logger;

    public LoggingPaymentGateway(Logger logger) {
        this.logger = logger;
    }

    @Override
    public PaymentResult charge(ChargeCommand command) {
        logger.info("charge() called with {}", command);
        return PaymentResult.simulated();
    }
}

// stand-in where the call should be silently skipped
public class NoOpPaymentGateway implements PaymentGateway {
    @Override
    public PaymentResult charge(ChargeCommand command) {
        return PaymentResult.skipped();
    }
}
```

Treat a Logging/No-Op stand-in as a placeholder, not a permanent option:
once the real adapter exists, swap the composition-root binding to it —
don't leave a stand-in wired past the point it was covering for. This is
also a different case from `igiari-tdd`'s Mockito-for-gateways
preference: a mock exists only for the duration of one test, while a
Logging/No-Op gateway is wired at the composition root for a real
environment or code path (e.g. local dev, a not-yet-enabled feature) where
no test is running at all.

## Why interfaces at these seams also pays for testing

Repository, service, and logger all being interfaces is what makes the
TDD skill's preferences possible: an in-memory repository and a Mockito
mock are both just another implementation of the same interface the use
case already depends on — no test-only wiring hacks needed.

## Verifying a structural change: full build, not just the scoped test

A structural change here — introducing an interface, changing a
constructor signature, moving a static method to an instance method,
adding or editing `@Configuration`/`@Bean` wiring — has a wider blast
radius than a typical TDD baby step. `igiari-tdd` runs
scoped/single-test builds during a cycle and only does one full build at
the end; that's correct for a change confined to one class. It isn't
enough on its own here: a scoped build only compiles the test's own
compile unit, so it can't catch a composition root that no longer
compiles, or another caller still doing `new ConcreteThing(...)` against
the constructor you just changed.

Run a full build — compile everything, run the full test suite — after
any structural change of this kind, even if the work leading up to it was
done in TDD-scoped steps. The scoped build answers "does this test
pass"; the full build answers "did this change break a caller or wiring
point outside this test's compile unit," which is the actual risk a
structural change carries.

Adding a new constructor dependency (a new repository/service/collaborator
an existing class now needs) is exactly this kind of change, even when no
behavior changes — the constructor signature is different, so the full
build will fail every existing test that constructs the class directly.
Fix those tests as part of the same change: add the new dependency to
each affected test's setup (typically a new `@Mock` field and constructor
argument). This is a mechanical fix to keep the code compiling, not new
test coverage to justify — "no behavior changed" is not a reason to leave
a test broken, since a broken build is exactly what the rule above exists
to catch.

## Repository return types

- A repository method returns the domain object itself — an
  `Option<Entity>` for a possible-absent lookup, an `Entity` or
  `List<Entity>` otherwise — never a primitive, a boolean, or a partial
  projection.
- Reasoning: the use case almost always needs the full object to build its
  response (see below). A repository that only returns an id or a boolean
  forces the use case into a second fetch, or forces extra data to be
  threaded through method parameters that don't belong there. Return the
  whole object once; let the use case decide what to keep.

## Use case input and output: Request/Command and Response

### Naming the input: Request, Command, or Query

- **`Command`** — the use case's job is to mutate state. The response
  stays thin (an id, an acknowledgement, a version) — the point of a
  command isn't to hand data back, since the caller already has what it
  sent.
- **`Query`** — the use case only reads, no side effects. The response
  *is* the requested data.
- **`Request`** — the generic fallback name, for a use case that doesn't
  cleanly split into one or the other (e.g. read-then-write in a single
  operation).

This is naming-only: it signals intent at the boundary, it does not imply
full CQRS (separate read/write models or separate persistence stores).
Don't reach for a split read/write architecture unless that's a deliberate,
separately-justified decision — the naming convention alone doesn't ask
for it.

### The output is a Response object, not the domain entity

The use case never returns a domain entity directly. It returns its own
`Response` object, built by an explicit mapping step from whatever domain
object(s) the repository/service calls returned. Returning the entity
directly couples every caller to the persistence/domain shape — a field
rename on the entity then breaks the use case's contract for no reason
related to the use case itself.

### Mappers: one per domain type, both directions as needed

- **Outbound** (domain object → `Response`): the normal case, since a
  domain object almost always needs transforming before it can leave the
  use case.
- **Inbound** (`Command`/`Request` → domain object): only when the use
  case has to construct or hydrate a domain object before handing it to a
  repository or service. If primitives pass straight through to a
  repository method's parameters, there's nothing to map — don't add a
  mapper for its own sake.
- **One mapper per domain type, not one per use case.** When a `Response`
  is assembled from more than one repository (e.g. `User` +
  `Order`), don't write a single mapper that takes both as parameters.
  Give each entity its own mapper (`UserMapper`, `OrderMapper`) and let
  the use case — or a small assembly step — combine their outputs into the
  final `Response`. A combined mapper can't be reused by any other use
  case that also needs to map a `User`, and it grows a new reason to
  change every time either source entity changes.

## Relationship to DDD

Clean Architecture and DDD answer different questions and aren't the same
commitment — same relationship as this skill has to `igiari-tdd`:
orthogonal, composable, neither implies the other.

- **Clean Architecture** governs *dependency direction*: what's allowed to
  depend on what, and what sits behind an interface at the boundary.
- **DDD's tactical patterns** govern *what lives inside* the domain layer
  that rule protects: rich Entities, Value Objects, and Aggregates with
  enforced invariants and real behavior, instead of anemic data holders a
  service class pushes around from the outside.

Clean Architecture doesn't require DDD — a project can respect the
dependency rule with a thin, anemic domain model. But they compose
naturally: the "domain object" a repository returns (see above) is exactly
DDD's Entity/Aggregate, and the outbound mapper is precisely the boundary
where that rich object is deliberately flattened into a dumb `Response`
DTO before it leaves the use case — a DDD rule in its own right (never let
an aggregate leak past its boundary), not only a Clean Architecture one.

## Framework examples

Framework-specific material lives in `references/` and is **not** loaded
with this skill — read the file only when the case at hand calls for it.

| Read this | When |
|---|---|
| `references/spring.md` | The project uses Spring, or config values must be resolved at the composition root (`@Configuration`/`@Bean`, binding a logger's injection point, environment-driven config objects, and the no-Spring resolver equivalent). |
| `references/ecm-ports.md` | Wrapping a heavy concrete SDK (Nuxeo `DocumentModel`, Documentum `IDfSysObject`) behind a narrow port — including the two-port rule for syncing to an external system, and pulling deterministic computation out of the seam. |
| `references/nuxeo-addon.md` | Packaging a Nuxeo addon: enforcing dependency direction with Maven modules, composite log4j2, platform-seeded vocabularies. |
| `references/testing-across-the-seam.md` | Proving an **adapter or listener** translates correctly at the seam — Nuxeo `FeaturesRunner`/`@Deploy` integration tests (including the per-branch checklist for listener changes), and the unresolved Documentum/DFC case. Not needed for ordinary use case tests: those are covered by the two-tier rule just below. |

The dependency rule itself never lives in those files — it is stated above
and applies whatever the framework. A reference only shows how to satisfy
it in one specific environment.

### Testing across the seam: two tiers

- **Use case tests** stay pure unit tests — no framework runtime, an
  in-memory repository and Mockito per `igiari-tdd`'s preferences. This is
  where most tests live, and it needs no reference.
- **Adapter/listener integration tests** exist only to prove the seam's
  translation is correct (event → `Command`, SDK type ↔ domain object, a
  static lookup actually resolving) — never to re-test business rules the
  use case's unit tests already cover. How to write one is
  framework-specific: see `references/testing-across-the-seam.md`.

### Setter injection: narrow legacy exception

Constructor injection stays the default. Switching one specific
dependency to setter injection is an accepted exception only when a
legacy framework wiring genuinely blocks the constructor path (e.g. a
circular bean dependency, a base class the framework instantiates without
arguments). Scope the exception to that one seam — it doesn't reopen
constructor injection as a general choice elsewhere in the same class or
codebase.


## Author's preferences

- **Needing to mock a static method is a design smell, not a testing
  problem.** It means the code reached for a static dependency directly
  (`SomeStaticFactory.get()`, a static utility with real behavior to fake)
  instead of depending on an interface — the same violation "Constructor
  injection, always" already names, just discovered from the test side
  instead of the code side. The fix is to wrap the static behind an
  interface you own and inject an adapter implementing it, same as any
  other infrastructure dependency — not to reach for a static-mocking tool
  to work around it.
- **Exception: a static you don't own and can't wrap out of scope.** A
  JDK or third-party static (`Math`, a library's static factory) can't be
  redesigned, and wrapping it is sometimes a bigger change than the task
  at hand. There, mocking the static is an accepted last resort — but
  still prefer introducing a thin owned interface around it when it's
  practical, rather than defaulting to static mocking every time the
  dependency recurs.
- **The line isn't "static," it's determinism.** A pure static call — same
  input always gives the same output, no hidden state, no side effect
  (`Math.max(a, b)`, `Collections.emptyList()`, `String.valueOf(x)`) — is
  fine to call directly. Nothing to inject: a test can assert on it like
  any other expression. The static calls that actually need wrapping are
  the ones that can return a different result for the same input —
  `Instant.now()`, `System.currentTimeMillis()`, `UUID.randomUUID()`,
  `Math.random()`, an env-var read. Those are the always-applicable case
  of the rule above: wrap each behind an owned interface (`Clock`,
  `IdGenerator`) and inject it, the same as any other collaborator — not
  because it's static, but because a test can never pin down an expected
  value for a call that isn't deterministic.

- **Threading shared configuration through a call chain: Parameter Object
  over a loose primitive, even for one value.** When several methods down a
  call chain all need the same configuration, don't add a raw primitive or
  collection parameter (`Set<String>`, a `boolean`, a `String` path) to
  every method on that chain. Bundle it into one named value object (e.g.
  `PeppaConfig`) starting from the very first config value, not only once a
  second one shows up. The payoff is asymmetric: with a loose `Set<String>`,
  adding a second, differently-typed config value means touching every
  method signature on the chain again; with a config object, every method
  in between still just says `PeppaConfig config` — only the object's
  fields and the leaf methods that read them change.
- **That pattern is manual/"poor man's" Reader, not the Reader monad itself
  — know the difference before reaching for one.** `Reader<Env, A>`
  represents "a function that needs an `Env` to produce an `A`"; its
  monadic `map`/`flatMap` compose several such functions so the environment
  is threaded automatically by the monad's own bind, and the caller
  supplies `Env` only once, at the outermost `run(env)`. Manually adding a
  `PeppaConfig` parameter to every method and passing it down by hand gets
  the same *intent* — defer/centralize where the environment is supplied —
  without the monadic machinery. That's a legitimate, simpler choice for a
  shallow call chain. Vavr doesn't ship a `Reader` type, so reaching for one
  here means hand-rolling monadic infrastructure to solve a problem
  constructor injection already solves for free in OOP — don't build a
  Reader for this.
- **If the class can stop being a bag of static methods, constructor
  injection removes the threading problem entirely, not just improves it.**
  A static method taking a config parameter is exactly the shape Reader
  targets: a function needing an environment it has no instance to hold. If
  callers can hold an instance, give the class a constructor that takes
  `PeppaConfig` once, store it `private final`, and turn the static methods
  into instance methods reading `this.config` — no parameter to thread
  through any call chain at all, consistent with "Constructor injection,
  always" above. Reach for the static-plus-parameter-object form only when
  the class is genuinely forced to stay static (called from many places
  that can't hold or obtain an instance — a legacy static-utility seam) —
  there, the parameter object is the right compromise, not a consolation
  prize.
- **A config/parameter object is a constructor dependency like any
  other — type it as an interface, not a bare `record`/concrete class,
  same as repository/service/logger under "Constructor injection,
  always."** No special-casing it as "just data": the point of that rule
  is the seam itself, not something earned only once a second
  implementation is already needed. `ProcessingConfig` behind a
  `DefaultProcessingConfig` costs one extra type and buys the same
  liberty every other injected interface does — swap in an
  environment-driven implementation later (see *Environment-driven config
  objects* under *Framework examples* below), a test-specific one, or a
  second concrete shape, without touching the constructor signature of
  anything that depends on it.

<!-- Add further architecture preferences here as they come up. -->

## When this skill doesn't cover the case

If you hit a situation these rules don't clearly address — an ambiguous
seam, a framework pattern not covered above, a structure where dependency
inversion isn't obviously applicable — don't silently improvise a one-off
judgment call and move on. Make the best call you can for the situation at
hand, then flag the gap explicitly, in this format, so it can be reviewed
and folded back into this file later:

```
## Skill improvement proposal
- Skill: chottomatte-archi
- Situation: <what you were doing>
- Gap: <what these rules don't cover, or got wrong>
- Proposed rule: <the addition, worded as a rule, ready to paste in>
- Suggested location: <the section of this file it belongs in>
```

This is for gaps in the rules themselves, not violations of them — a rule
you understood but chose to break is not a gap.
