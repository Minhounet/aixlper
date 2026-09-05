---
name: chottomatte-archi
description: Enforces dependency inversion via interfaces and constructor injection for Java — use cases as the entry point depending only on repository/service interfaces, with guidance for legacy code where the entry point isn't yours to control. Use when building or extending a real feature or use case — anything with collaborators, dependencies, or configuration to wire together — not for a standalone algorithm or self-contained utility with no external dependencies.
---

# Java Clean Architecture

**Related skills:** `igiari-tdd` covers how you *write code over
time* (test-first, one behavior per step) — this skill only covers how the
code should be *structured* (dependency inversion, constructor injection).
Orthogonal and composable, not a dependency: load the other one too when
writing new code, not just restructuring existing code. `ddd-strategic-design`
covers the boundary *between* models/teams/systems (Bounded Context, Context
Map) — language-agnostic, one level up from this skill's single-model
dependency rules. Load it too once a second model, team, or external system
enters the picture.

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

- One use case class per business operation (e.g. `RegisterUserUseCase`,
  `CancelOrderUseCase`). This *is* the entry point — nothing else sits in
  front of it as far as the core is concerned.
- Its constructor takes exactly the interfaces it needs: repository
  interfaces (e.g. `UserRepository`), service interfaces (e.g.
  `EmailSender`, `PaymentGateway`), and cross-cutting ones like `Logger`.
- The use case orchestrates domain logic. It has no knowledge of
  persistence technology, transport (HTTP/CLI/messaging), or which
  concrete class implements any of its collaborators.
- Concrete adapters (a JPA-backed repository, an HTTP client, an
  in-memory repository for tests, the log4j2 binding) are wired together
  at the composition root (`main`, a framework config class, a test's
  setup) — never inside the use case itself.

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

### Spring: keep it out of the core, prefer bean configuration

Default preference: use case / domain / service classes carry **no Spring
annotations** — no `@Component`, `@Service`, `@Autowired`. They stay the
plain, constructor-injected classes described above. Wiring happens in
explicit `@Configuration` classes with `@Bean` methods at the composition
root, so the dependency graph is visible in one place you can read like a
plan, and the core stays runnable/testable outside a Spring context.

```java
// core — no Spring
public class RegisterUserUseCase {
    private final UserRepository userRepository;
    private final Logger logger;

    public RegisterUserUseCase(UserRepository userRepository, Logger logger) {
        this.userRepository = userRepository;
        this.logger = logger;
    }
}

// composition root — Spring lives here, not in the core
@Configuration
public class UseCaseConfig {

    @Bean
    public RegisterUserUseCase registerUserUseCase(UserRepository userRepository, Logger logger) {
        return new RegisterUserUseCase(userRepository, logger);
    }
}
```

**Reality check:** you'll sometimes land in a project that already
annotates domain/use-case classes directly (`@Service` + `@Autowired`
constructor). That's not the preferred shape, but ripping it out
project-wide is a different task from whatever you were asked to do.
Same seam rule as legacy entry points: don't fight the codebase's
existing convention in the middle of an unrelated task; prefer bean
configuration going forward when you're adding something genuinely new
and it's practical to do so.

### Logger: bind the injection point to the right class

A single shared `Logger` bean can't be scoped to the class using it. Use
Spring's `InjectionPoint` to hand each constructor the logger for its own
declaring class:

```java
@Configuration
public class LoggerConfig {

    @Bean
    @Scope("prototype")
    public Logger logger(InjectionPoint injectionPoint) {
        return LoggerFactory.getLogger(injectionPoint.getMember().getDeclaringClass());
    }
}
```

Every class with a `Logger` constructor parameter gets a logger bound to
itself, without hand-writing `LoggerFactory.getLogger(ThisClass.class)`
in every constructor. Outside Spring (or without bean config), the
hand-written form is the equivalent and is perfectly fine.

### Environment-driven config objects: resolve properties at the composition root

When a parameter object (see *Threading shared configuration* under
*Author's preferences* below) needs its values from environment/properties
rather than a literal in code, the core class still never sees `@Value`
or `@Component` — only the `@Configuration` class touches Spring's
`Environment`:

```java
// core — a plain POJO, still no Spring
public interface ProcessingConfig {
    Set<String> attributesToKeepEmpty();
}

public class DefaultProcessingConfig implements ProcessingConfig {
    private final Set<String> attributesToKeepEmpty;

    public DefaultProcessingConfig(Set<String> attributesToKeepEmpty) {
        this.attributesToKeepEmpty = attributesToKeepEmpty;
    }

    @Override
    public Set<String> attributesToKeepEmpty() {
        return attributesToKeepEmpty;
    }
}

// composition root — the Environment lookup lives here, not in the core
@Configuration
public class ProcessingConfiguration {

    @Bean
    public ProcessingConfig processingConfig(Environment environment) {
        String raw = environment.getProperty("app.processing.keep-empty-attributes", "");
        Set<String> attributes = Arrays.stream(raw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toSet());
        return new DefaultProcessingConfig(attributes);
    }
}
```

The interface here is the same one the config object always has, per
"Constructor injection, always" — this pattern is just one concrete
implementation of it. The composition root turns a raw property string
into `DefaultProcessingConfig`; a test can turn a literal `Set.of(...)`
into a different `ProcessingConfig` implementation just as easily,
without either one touching the use case's constructor.

### Setter injection: narrow legacy exception

Constructor injection stays the default. Switching one specific
dependency to setter injection is an accepted exception only when a
legacy framework wiring genuinely blocks the constructor path (e.g. a
circular bean dependency, a base class the framework instantiates without
arguments). Scope the exception to that one seam — it doesn't reopen
constructor injection as a general choice elsewhere in the same class or
codebase.

### Heavy ECM/legacy SDKs (Nuxeo, Documentum, etc.): keep the port narrow, translate at the seam

Frameworks like Nuxeo or Documentum expose large, concrete SDK types
(`DocumentModel`, `IDfSysObject`) that are genuinely expensive to fully
wrap. The dependency rule doesn't relax because the SDK is big — the fix
for the cost is to scope the port down, not to let the SDK type into the
core:

- Define the repository interface with only the methods the current use
  case(s) actually call (`findContractById`, `save`) — not a
  general-purpose repository mirroring the whole SDK API. A narrow port is
  cheap to adapt; a wide, speculative one is the expensive one people run
  into.
- One adapter class maps the SDK type ↔ your domain object, touching only
  the fields the use case needs — the same per-entity mapper pattern as
  the `Response` mapping above, reused here on the inbound side.
- A framework-instantiated entry point (a Nuxeo `EventListener`, a
  Documentum event handler) is the legacy-entry-point seam already
  described above: it stays framework-flavored at its outer edge, but the
  first thing it does is translate the framework event into a
  `Command`/`Request` and hand off to a real use case that has never heard
  of the framework.
- Where the SDK forces a static lookup (`Framework.getService(...)`)
  because the framework — not you — instantiates the class, confine that
  lookup to the listener's translation code. Never let it reach into the
  use case; the use case still only sees interfaces via its constructor.
- Nuxeo specifically: never call `Framework.getService(...)` in the
  listener's constructor, and never build a `CoreSession`-backed adapter
  there either. Listener instances are created during component/bundle
  registration, before the runtime guarantees every service has started,
  so a service resolved in the constructor can come back `null` or
  half-initialized; `CoreSession` is scoped to the current
  request/transaction and doesn't exist yet at construction time either.
  Both are resolved inside `handleEvent`, at the same point the
  translation happens — which means the repository/gateway adapters and
  the use case itself are constructed per-invocation in `handleEvent`,
  not once in the listener's constructor.

```java
public class ContractStatusListener implements EventListener {
    @Override
    public void handleEvent(Event event) {
        DocumentModel doc = ((DocumentEventContext) event.getContext()).getSourceDocument();

        ContractRepository repository = Framework.getService(ContractRepository.class);
        Logger logger = LoggerFactory.getLogger(ChangeContractStatusUseCase.class);

        new ChangeContractStatusUseCase(repository, logger).execute(toCommand(doc));
    }

    private ChangeContractStatusCommand toCommand(DocumentModel doc) { /* mapping */ }
}
```

**Exception, judgment call:** when a step has no independent domain concept
beyond the ECM's own model — e.g. a workflow transition that's genuinely
just `documentModel.followTransition(...)` with no rule layered on top —
forcing a full domain wrapper is ceremony with no payoff, same spirit as
the pure-static-call exception under *Author's preferences* below. Don't
decide this silently every time it comes up: log it with the "Skill
improvement proposal" format further down, so the threshold gets reviewed
rather than reinvented per use case.

### Syncing Nuxeo to an external system: two ports, not one

A common real case: an `EventListener` needs to push a changed document to
another system over REST. Unlike the trivial-transition exception above,
this is a genuine clean-architecture candidate — there's real logic to
isolate (what to sync, how to map it, how to handle failure) — but it
needs two separate ports, not one repository stretched to cover both
directions:

- **`DocumentRepository`** (or similarly named) — reads the domain object
  out of Nuxeo. This is the repository: it reconstructs *your* domain
  entity from the system of record, same as any other repository in this
  skill.
- **A gateway/service port** (`SyncGateway`, `ExternalSystemService`) —
  pushes to the external system. Name and treat this as a gateway, not a
  repository, even though the instinct is to call it "the other
  repository": it's a one-way call to a system you don't own, not a
  reconstruction of your domain entity. The distinction also drives
  testing — the Nuxeo repository gets `igiari-tdd`'s
  in-memory-fake treatment, the external-system gateway gets Mockito, same
  as any other service/gateway/client collaborator.

The use case takes both through its constructor, with an outbound mapper
(the same per-domain-type mapper convention as the `Response` mapping
elsewhere in this skill) turning the domain object into the external
system's shape:

```java
class SyncDocumentUseCase {
    SyncDocumentUseCase(DocumentRepository repository, SyncGateway gateway) { ... }

    void execute(SyncDocumentCommand command) {
        Document doc = repository.findById(command.documentId());
        ExternalDto dto = mapper.toExternal(doc);
        gateway.push(dto);
    }
}
```

The Nuxeo `EventListener` stays the thin translation entry point from the
pattern above, wired inside `handleEvent`. The REST client adapter behind
`SyncGateway` is a plain Java HTTP client needing no Nuxeo test harness at
all — Mockito or a wiremock-style test is enough for it.

### Testing across the seam

Two tiers, not one:

- **Use case tests** stay pure unit tests — no framework runtime, an
  in-memory repository and Mockito per `igiari-tdd`'s existing
  preferences. This is where most tests live.
- **Adapter/listener integration tests** exist only to prove the seam's
  translation is correct (event → `Command`, SDK type ↔ domain object, the
  static lookup actually resolves) — not to re-test business rules already
  covered by the use case's unit tests. Nuxeo provides this via
  `nuxeo-runtime-test`'s `FeaturesRunner` + `@Features(CoreFeature.class)`:
  an embedded runtime where `Framework.getService(...)` resolves for real,
  scoped down with `@Deploy` to just the components under test.
- **Documentum: unresolved, flag rather than assume.** There's no known
  embedded-runtime equivalent for DFC. `IDfSysObject`/`IDfSession` are
  interfaces, so they're directly Mockito-mockable, but the fidelity of
  that mock against real Documentum behavior is an open concern, not a
  settled pattern — the same unverified status as
  `documentum-idempotent-scripting`. Don't present a mocked-DFC adapter
  test as equivalent proof to a Nuxeo `FeaturesRunner` test; treat it as a
  weaker substitute until real usage says otherwise, and prefer validating
  the adapter against a real docbase where practical.

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
