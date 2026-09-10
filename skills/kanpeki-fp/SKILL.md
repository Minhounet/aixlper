---
name: kanpeki-fp
description: Enforces functional programming style with Vavr for Java — pure guards, Either/Option for error paths, sealed types for discriminated results, no mutation, no side effects inside decision methods. Use whenever implementing logic that involves filtering, branching, or error handling in Java with Vavr on the classpath.
---

# Functional Programming — Vavr Style

**Related skills:** `chottomatte-archi` covers how code should be *structured*
(dependency inversion, constructor injection) — this skill covers how logic
should be *expressed* (pure functions, immutable data, functional pipelines).
Orthogonal and composable: load both when implementing features.
`igiari-tdd` covers how you *write code over time* — load it too when
writing new code.

## The one principle that matters most

**Pure functions, no side effects inside decision methods.** A method that
filters, guards, or decides must do exactly one thing: return a value that
represents its decision. Logging, metrics, and other side effects are never
inside the decision method — they are composed *around* it at the call site.

## Guards and filters: pure methods returning Either

A guard method answers a yes/no question and carries its reason as a value.
Never log or throw inside a guard — return the outcome:

```java
private Either<SkipReason, DocumentEventContext> requireNotProxy(DocumentEventContext ctx) {
    DocumentModel doc = ctx.getSourceDocument();
    return doc.isProxy()
        ? Either.left(new SkipReason.IsProxy(doc.getId()))
        : Either.right(ctx);
}
```

Chain guards with `flatMap` — a Left short-circuits the rest:

```java
toDocumentContext(event)
    .flatMap(this::requireHydroDocument)
    .flatMap(this::requireNotProxy)
    .peek(this::processPublication)
    .peekLeft(this::logSkipReason);
```

Side effects (`peek` for success, `peekLeft` for skip) are composed at the
end of the pipeline, never inside the guards themselves.

## Discriminated skip reasons: sealed interfaces

When a pipeline can be short-circuited for multiple distinct reasons, model
them as a sealed interface — not a String, not an enum, not a boolean:

```java
sealed interface SkipReason {
    record NotDocumentEvent()               implements SkipReason {}
    record NotHydroDocument(String docId)   implements SkipReason {}
    record IsProxy(String docId)            implements SkipReason {}
}
```

Benefits:
- Each variant carries exactly the context it needs (no nullable fields)
- The compiler enforces exhaustiveness in switch expressions
- Adding a new variant forces every switch site to handle it

Log them with a single exhaustive switch. Use **record pattern destructuring**
to bind components directly — not a type pattern binding (`IsProxy r`) followed
by an accessor call (`r.docId()`). Sonar flags the accessor form; the
destructuring form is the Java 21 idiom:

```java
private void logSkipReason(SkipReason reason) {
    switch (reason) {
        case SkipReason.IsProxy(String docId) ->
            log.debug("skipping proxy: id={}", docId);
        case SkipReason.NotHydroDocument(String docId) ->
            log.debug("skipping non-HydroDocument: id={}", docId);
        case SkipReason.NotDocumentEvent() ->
            log.debug("skipping non-document event");
    }
}
```

The `()` in `NotDocumentEvent()` is already record pattern syntax (zero
components). Variants with components follow the same form: list the component
types inside the parentheses and bind them to local names.

## Option instead of null

Never return null to signal absence. Return `Option<T>`:

```java
private Option<DocumentEventContext> toDocumentContext(Event event) {
    return event.getContext() instanceof DocumentEventContext ctx
        ? Option.some(ctx)
        : Option.none();
}
```

Chain with `flatMap`/`map`; call `.peek()`/`.onEmpty()` for side effects.
`Option` composes with `Either` — `option.toEither(leftValue)` converts when
you need to carry a reason.

### A reader of external data returns Option, and kills its null-mopping helper

Anything that reads a value out of a system you don't control — a Nuxeo
property, a header, a config entry — is the classic place nulls leak inward.
Have it return `Option<T>` at the point of the read, not a nullable `T` that
every caller then has to remember to check.

The tell that this is needed: a companion helper whose whole job is to clean up
after the nullable one (`nullToEmpty`, `orDefault`, `safeGet`). That helper is
absence-handling smeared across call sites. Once the reader returns `Option`,
it has nothing left to do — delete it.

```java
// before — nullable read, plus a helper to mop up after it
protected String asString(DocumentModel doc, String xpath) {
    Serializable value = doc.getPropertyValue(xpath);
    return value == null ? null : String.valueOf(value);
}
protected String nullToEmpty(String value) {
    return value == null ? "" : value;
}

// after — absence is in the type; the mop-up helper is gone
protected Option<String> asString(DocumentModel doc, String xpath) {
    return Option.of(doc.getPropertyValue(xpath)).map(String::valueOf);
}
```

Each caller then states its own intent instead of inheriting one global
default: `.getOrElse("")` where empty is meaningful, `.filter(s ->
!s.isBlank())` where blank counts as absent, `.getOrElse(() -> buildIt())` for
a computed fallback.

### Option stops at a boundary you don't own

Do not push `Option` into a type whose shape is dictated by something else — a
DTO a codec serializes, a framework class, a wire contract. Jackson, JAXB and
friends expect a nullable field; an `Option` there either fails to serialize or
needs a module plus custom (de)serializers, which is a large change bought for
nothing.

Convert **explicitly, once, at that boundary**:

```java
message.setEdfPorteeSite(asString(doc, XP_SITE).getOrNull());
```

`.getOrNull()` in that one position is correct, not a defeat — it is the seam
where your model meets a contract you don't control, and spelling it out makes
the seam visible. What matters is that the null is confined to that line rather
than travelling inward.

## Either for error paths in use cases

When a use case can fail for a known business reason (not an exception),
return `Either<Failure, Success>` rather than throwing or returning a
nullable result:

```java
Either<SyncFailure, SyncResult> execute(CreerDocumentCommand cmd) {
    return gateway.creerDocument(cmd)
        .filterOrElse(SyncResult::isSuccess, r -> new SyncFailure.Rejected(r.errorMessage()));
}
```

Left = known failure (retryable or not), Right = success. The caller decides
what to do with each — no exception-based flow control.

## Immutability

- Prefer `final` fields everywhere (enforced by `chottomatte-archi` already)
- Use Vavr's immutable collections (`io.vavr.collection.List`, `Map`, `Set`)
  instead of `java.util` when building new data structures inside domain/use-case code
- Never mutate a parameter; return a new value instead

## What NOT to use Vavr for

- **`Try` for control flow** — `Try` wraps exceptions; use it only at the
  boundary of code that genuinely throws (third-party libraries, I/O). Never
  use `Try` as a substitute for `Either` when the failure is a known business
  outcome, not an unexpected exception.
- **Nuxeo API calls** — Nuxeo's `CoreSession`, `DocumentModel`, etc. are
  inherently imperative and stateful. Wrap them at the seam (per
  `chottomatte-archi`); don't try to make them functional inside the listener.
  The functional pipeline starts *after* the Nuxeo call returns a value.
