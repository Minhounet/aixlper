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
- No field injection, no setter injection, no service-locator or static
  lookup (`SomeStaticFactory.get()`) reached for from inside business
  logic, no `new ConcreteThing()` of an infrastructure dependency buried
  inside a use case or domain class.
- Injected fields are `private final`.

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
and domain code never know it's there.

## Why interfaces at these seams also pays for testing

Repository, service, and logger all being interfaces is what makes the
TDD skill's preferences possible: an in-memory repository and a Mockito
mock are both just another implementation of the same interface the use
case already depends on — no test-only wiring hacks needed.

## Author's preferences

<!-- Add further architecture preferences here as they come up. -->
