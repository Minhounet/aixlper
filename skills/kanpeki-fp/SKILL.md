---
name: kanpeki-fp
description: Enforces functional programming style with Vavr for Java, aimed at clearer code and shorter, simpler methods — pure guards, Either/Option for error paths, sealed types for discriminated results, loops turned into named pipelines, expressions over reassigned locals, no mutation, no side effects inside decision methods. Use whenever implementing or refactoring logic that involves filtering, branching, looping or error handling in Java with Vavr on the classpath, including the refactor step of a TDD cycle.
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

## Purpose: clearer code, shorter methods

Every pattern here exists to make the code easier to read: short methods,
shallow nesting, no clever constructs. FP is the means, not the goal. If
applying a pattern makes a method harder to read, don't apply it (see "When
FP hurts clarity" below). Unit tests are what make these moves safe: with a
green test around the code, a rewrite into a pipeline is checked, not hoped.

The patterns can be applied in `igiari-tdd`'s refactor step and in a
`kaizen-refactor` pass, as long as tests stay green before and after.

### Changing a signature: internal is free, an interface is not

Some patterns change a return type (`String` → `Option<String>`, `T` →
`Either<E, T>`). Whether that is allowed depends on who sees the signature:

- **Internal** — a `private` or package-private method, or any method whose
  every caller is changed in the same step: change it freely. It is a
  refactor like any other.
- **An interface** — a port or other Java `interface`, a `public` API used
  outside the module, a method a unit test calls directly, a framework or
  wire contract: keep the signature. Change it only when the new type is a
  game changer (for example, it removes a whole class of null bugs or a
  helper every caller needs), and then not silently: show the before/after
  signature and why, and get it approved. Inside an `igiari-tdd` cycle that
  is a plan deviation, and the test that calls it changes in RED, not in
  REFACTOR.

Each pattern below is tagged **[keeps signature]** or **[changes
signature]** so this check is quick.

## Guards and filters: pure methods returning Either

**[changes signature]** when an existing guard returned `boolean` or threw.

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

**[changes signature]** — internal readers: just do it; a reader behind an
interface: see the signature rule above.

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

**[changes signature]** — a use case is usually behind a port, so this is
normally decided when the use case is designed, not in a refactor step.

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

## Clarity patterns: shortening long methods

### 1. Loop → pipeline  **[keeps signature]**

A `for` loop that fills a mutable list, map or counter becomes a pipeline.
The accumulator and its mutation disappear:

```java
// before
List<String> ids = new ArrayList<>();
for (Document d : docs) {
    if (d.isPublished()) {
        ids.add(d.getId());
    }
}
return ids;

// after
return docs.stream()
    .filter(Document::isPublished)
    .map(Document::getId)
    .toList();
```

Use `foldLeft` (Vavr) or `reduce` for a sum or a single combined value,
`groupBy` for a map of lists, `partition` for "two lists split by a
predicate". A loop with an early `return` on the first match is `find`
(`stream().filter(...).findFirst()` / Vavr `find`). Keep the loop when its
body has real side effects per element in a fixed order (I/O, Nuxeo calls)
— that is the imperative shell, not logic.

### 2. Name the steps  **[keeps signature]**

A lambda longer than one line becomes a private method, and the pipeline
uses its method reference. The top-level method then reads like a table of
contents:

```java
return candidates.stream()
    .filter(this::isEligible)
    .map(this::toInvitation)
    .toList();
```

This is the main tool against long methods: each step gets a name that says
what it means, and each named step can be read (and tested through its
caller) on its own.

### 3. Expressions, not reassigned locals  **[keeps signature]**

A local declared first and assigned in branches becomes a single expression
— a ternary for two cases, a `switch` expression for more:

```java
// before
String label;
if (status == Status.DRAFT) {
    label = "draft";
} else if (status == Status.PUBLISHED) {
    label = "live";
} else {
    label = "archived";
}

// after
String label = switch (status) {
    case DRAFT -> "draft";
    case PUBLISHED -> "live";
    case ARCHIVED -> "archived";
};
```

Every local is assigned once. Nested ternaries are not an expression win —
use a `switch` or a named method instead.

### 4. Switch on a sealed type to produce a value  **[keeps signature]**

The exhaustive `switch` shown above for logging also replaces
`if (x instanceof A) ... else if (x instanceof B) ...` chains that compute a
value. Use record pattern destructuring, and no `default` branch, so adding
a variant breaks compilation at every site that must handle it:

```java
BigDecimal fee(Shipment s) {
    return switch (s) {
        case Shipment.Standard(BigDecimal weight) -> weight.multiply(RATE);
        case Shipment.Express(BigDecimal weight, int hours) -> expressFee(weight, hours);
        case Shipment.Pickup() -> BigDecimal.ZERO;
    };
}
```

### 5. Functional core, imperative shell  **[keeps signature]** of the outer method

This is "the one principle" applied to a whole method. Split a method that
mixes reading, deciding and writing into three parts: the shell reads
(I/O, Nuxeo, gateway), passes plain values to a pure core that decides, then
acts on the decision. The core takes values and returns a value — no
session, no logger, no mocks needed to unit-test it:

```java
void onEvent(Event event) {                              // shell
    Option<Document> doc = loadDocument(event);
    doc.map(publicationPolicy::decide)                   // pure core
       .forEach(this::apply);                            // shell
}
```

The outer method keeps its signature. The extracted core is new, so its
signature is free to choose (usually `Either`/`Option`/a sealed result).

#### The decision as data: the shell carries out what the core returns

Java has no `IO` type to mark a function as effectful, and none is needed:
the core never performs an effect, it returns a value that **describes** it.
Model the possible effects as a sealed type; the shell runs them with one
exhaustive `switch`, and is the only place they happen:

```java
sealed interface Action {
    record Publish(String docId, String target) implements Action {}
    record Notify(String userId, String message) implements Action {}
    record Skip(SkipReason reason)              implements Action {}
}

Action decide(Document doc) { ... }                      // pure

void apply(Action action) {                              // shell
    switch (action) {
        case Action.Publish(String id, String target) -> publisher.publish(id, target);
        case Action.Notify(String user, String msg)   -> mailer.send(user, msg);
        case Action.Skip(SkipReason r)                -> logSkipReason(r);
    }
}
```

A unit test asserts on what *would* happen —
`assertEquals(new Action.Publish("42", "web"), decide(doc))` — with no mock
and nothing actually happening. Several effects → return `List<Action>`;
the shell runs them in order.

Use this when the core chooses *between* effects. When an effect sits
genuinely in the middle (save, then call a gateway with the saved id), put
it behind a port (`chottomatte-archi`) and fake it in tests instead. Don't
build an `IO` of your own out of `Supplier`/`Runnable` chains: in Java it
costs readability and buys no compiler guarantee.

## Laziness: don't compute what may not be needed

### The eager-fallback trap  **[keeps signature]**

A fallback passed as a value is computed **every time**, even when it isn't
used. Pass a lambda instead whenever the fallback costs anything:

```java
opt.getOrElse(buildDefault())          // buildDefault() always runs
opt.getOrElse(() -> buildDefault())    // runs only when opt is empty
```

Same trap: `Either.getOrElse` vs `getOrElseGet`, `Optional.orElse` vs
`orElseGet`, `Option.orElse(Option)` vs `orElse(Supplier)`, and a log
argument built by string concatenation instead of `{}` placeholders. A
constant or an already-computed local is fine eager — the lambda would only
add noise.

### Which tool

| Need | Use |
|---|---|
| A fallback, or a value used on one branch only, at most once | a lambda / `Supplier<T>` parameter |
| A costly **pure** value that may be needed zero or several times | `Lazy.of(this::compute)` — computed on first `get()`, then cached |
| A sequence where only the first few elements may be consumed | `stream()` / Vavr `Stream`/`Iterator` — `filter(...).findFirst()` stops at the first match |

`Lazy` is related to `IO` (both hold a computation without running it) but
it runs **once** and caches. So it holds pure computations only: a side
effect inside `Lazy` runs once, at whatever moment the first `get()`
happens, and never again.

### Is it costly? Classify before you defer

Don't make something lazy because it *might* be slow — the extra lambda or
`Lazy` costs clarity and saves nothing on a cheap value. It's costly when
any of these holds:

- **It leaves the process:** a query (docbase, database), a remote call, a
  file read, a Nuxeo `getDocument`/`query`. Always treat as costly.
- **It builds something heavy:** an `ObjectMapper`, a JAXB context, a
  compiled `Pattern`, a big lookup map — usually better as a field built
  once than as a lazy local.
- **It scales with the data:** a loop or stream over a collection of
  unknown size, especially inside another loop.
- **It was measured:** a profiler (IntelliJ's, async-profiler) or a timed
  log line on real data shows it. For anything that is only pure in-memory
  work on small inputs, measure before deferring — don't guess.

Otherwise it's cheap: compute it eagerly, the straightforward way.

## When FP hurts clarity

FP style that is harder to read than the imperative version it replaces is a
regression. Don't:

- **Nest a lambda inside a lambda.** Extract the inner one into a named
  method (pattern 2).
- **Chain more than about 5–6 steps** in one pipeline. Split it into named
  sub-pipelines that each return a value.
- **Put `Tuple2`/`Tuple3` in a signature.** A tuple's `_1`/`_2` say nothing;
  use a record with named components. A tuple local inside one pipeline is
  fine.
- **Curry or partially apply** (`Function3.curried()`) in business code.
  Pass a lambda or use a small record instead.
- **Wrap a value that is never null in `Option`** just to avoid an `if`.
  `Option` marks real absence; anywhere else it is noise.
- **Use `peek` to mutate** an outside variable. `peek` is for side effects
  at the end of a pipeline (logging), never for building a result.

When in doubt, write both versions and keep the one that reads more easily.

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
- **`Future` in the core** — `Future` starts running on another thread the
  moment it's created, so it is an effect, not a value. It belongs in the
  shell, for independent slow I/O calls run in parallel, and only when the
  gain is real. Never hand a session (Nuxeo `CoreSession`, Documentum
  `IDfSession`) to another thread. Details: `references/concurrency.md`.

## Where to look for more

| Read | When |
|---|---|
| `references/composition.md` | A loop or method combines **several** fallible results (a list of `Either`, errors to collect rather than stop at the first), wraps a throwing library call with `Try`, updates an immutable record, or passes behavior as a parameter instead of a template method/Strategy class. |
| `references/concurrency.md` | You're about to use `Future`/`CompletableFuture`, run calls in parallel, or touch a Nuxeo or Documentum session from another thread. |

## Token self-audit

This file loads **in full** whenever the skill triggers and stays resident
for the rest of the session; `references/` files load only if the body
points at one. When asked to reduce token cost — or before adding anything
here — audit in this order and report what you would move, and why:

- **Needed only sometimes?** Material for one framework, one tool's exact
  commands, or a section about extending the skill itself → move to
  `references/` behind a pointer that names the condition precisely.
- **A reference opened on almost every trigger?** Then it costs *more*
  there than inline — a tool call, an extra assistant turn, and a lost
  prefix cache. Bring it back inline.
- **Does a step here run a command?** Its output is tokens too, charged
  every run and kept for the session. Suppress progress/debug noise and
  bound what gets echoed.

Never split a rule from its own statement: a reference shows how to satisfy
a rule in one environment, it never holds the rule. **Relocate, never
delete** — removing guidance to save tokens is a regression, not a saving.
