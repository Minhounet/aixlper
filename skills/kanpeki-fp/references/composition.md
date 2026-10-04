# Composition patterns — combining results, exceptions, updates, behavior

Read this when a method combines several fallible results, wraps a throwing
call, updates an immutable value, or passes behavior around. The rules (pure
decisions, Either for known failures, Try only at a throwing boundary, the
signature rule) are in `SKILL.md`; this file shows how to satisfy them in
these situations.

## Many results into one: `sequence` / `traverse`  **[keeps signature]** if the method already returned Either

A loop that calls a fallible operation per element and returns early on the
first failure is `traverse`:

```java
// before
List<Invoice> invoices = new ArrayList<>();
for (Order o : orders) {
    Either<BillingError, Invoice> r = bill(o);
    if (r.isLeft()) {
        return Either.left(r.getLeft());
    }
    invoices.add(r.get());
}
return Either.right(invoices);

// after
return Either.traverseRight(orders, this::bill)
    .map(Seq::toJavaList);
```

`Either.sequenceRight(listOfEithers)` does the same when the `Either`s
already exist. Both stop at the first `Left`. `Option.traverse` /
`Option.sequence` are the `Option` equivalents.

## Collect every error: `Validation`  **[changes signature]**

`Either` stops at the first failure. When the caller needs *all* of them —
validating a command or a form, reporting every bad field at once — use
Vavr's `Validation` and combine the independent checks:

```java
Validation<Seq<String>, Customer> validate(CustomerForm f) {
    return Validation.combine(
            validateName(f.name()),
            validateEmail(f.email()),
            validateAge(f.age()))
        .ap(Customer::new);
}
```

Each `validateX` returns `Validation<String, X>`. Convert at the edge with
`.toEither()` when the rest of the pipeline speaks `Either`. Use this only
when collecting matters: for "stop at the first problem", `Either` with
`flatMap` is simpler.

## Leaving a throwing call: `Try` → `Either`  **[changes signature]** of the wrapper only

`Try` belongs exactly at the call that throws, and turns into a domain
`Either` on the next line so the exception type does not travel inward:

```java
Either<ImportFailure, Payload> parse(String raw) {
    return Try.of(() -> mapper.readValue(raw, Payload.class))
        .toEither()
        .mapLeft(e -> new ImportFailure.Unreadable(e.getMessage()));
}
```

Keep the `Try` lambda to the single throwing call; any logic before or after
it goes in the `Either` pipeline.

### Every `try/catch` part has a `Try` equivalent

| `try/catch` | `Try` |
|---|---|
| `catch (SpecificException e) { return fallback; }` | `.recover(SpecificException.class, e -> fallback)` |
| `catch` that tries another call | `.recoverWith(SpecificException.class, e -> Try.of(...))` |
| `finally` | `.andFinally(() -> ...)` |
| try-with-resources | `Try.withResources(() -> openStream()).of(in -> read(in))` |
| a `void` call that throws | `Try.run(() -> ...)` |
| logging in the `catch` | `.onFailure(e -> log.warn(...))` — in the shell, like `peekLeft` |
| rethrowing for a framework that expects an exception | `.getOrElseThrow(e -> new IllegalStateException(e))` |

### Traps

- **`Try` catches everything, bugs included.** An NPE becomes an ordinary
  "failure". Keep the lambda to the single throwing call, and recover only
  **specific** exception types — a blanket `.getOrElse(default)` hides bugs.
- **It runs immediately.** `Try.of` executes on the spot; it is not `Lazy`.
- **Fatal errors pass through.** Vavr rethrows fatal ones (e.g.
  `VirtualMachineError`, `InterruptedException`) instead of wrapping them.
- **No `Try` in an interface signature.** `Try<T>` says only "something can
  fail", with no reason. In a private helper it's fine; at a port convert
  to `Either<DomainError, T>`, and in a public API to a sealed result (see
  "Known failures" in `SKILL.md`).
- **Catching undoes nothing.** Work already done (a write, a transaction
  marked for rollback) stays done, exactly as with `catch`.

## Immutable update: record withers  **[keeps signature]**

"Never mutate, return a new value" for a record means a `withX` method that
copies the record with one component changed — instead of a setter sequence:

```java
record Ticket(String id, Status status, Option<String> assignee) {
    Ticket withStatus(Status s)   { return new Ticket(id, s, assignee); }
    Ticket assignTo(String user)  { return new Ticket(id, status, Option.some(user)); }
}

Ticket next = ticket.assignTo("alice").withStatus(Status.IN_PROGRESS);
```

Prefer a domain verb (`assignTo`, `close`) over `withX` when one exists.
Add a wither only when a caller needs it, not for every component.

## Behavior as a parameter  **[keeps signature]** at the call sites

When two methods differ only by one step, pass that step as a function
instead of writing a template-method base class or a one-method Strategy
class:

```java
private List<Row> export(List<Doc> docs, Function<Doc, Row> toRow) {
    return docs.stream().filter(Doc::isExportable).map(toRow).toList();
}

List<Row> exportSummary(List<Doc> docs) { return export(docs, this::summaryRow); }
List<Row> exportFull(List<Doc> docs)    { return export(docs, this::fullRow); }
```

This is the lambda default `igiari-tdd`'s Strategy trigger already names. A
full Strategy class is still right when the varying part needs more than
one method or its own state.
