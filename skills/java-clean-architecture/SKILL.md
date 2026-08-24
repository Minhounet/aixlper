---
name: java-clean-architecture
description: Enforces dependency inversion via interfaces and constructor injection for Java — use cases as the entry point depending only on repository/service interfaces, with guidance for legacy code where the entry point isn't yours to control. Use when designing, structuring, or reviewing Java production code.
---

# Java Clean Architecture

## The one principle that matters most

**Dependency inversion, via interfaces.** High-level policy (the use case,
the domain logic) must never depend on a concrete, low-level detail
(a specific database client, an HTTP framework, a logging library). It
depends only on an interface. Concrete implementations of that interface —
adapters — live outside the core and are plugged in from the outside.

Everything else in this skill (constructor injection, the use-case shape,
the legacy guidance) is a consequence of this one rule, not a separate rule.

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
- Skill: java-clean-architecture
- Situation: <what you were doing>
- Gap: <what these rules don't cover, or got wrong>
- Proposed rule: <the addition, worded as a rule, ready to paste in>
- Suggested location: <the section of this file it belongs in>
```

This is for gaps in the rules themselves, not violations of them — a rule
you understood but chose to break is not a gap.
