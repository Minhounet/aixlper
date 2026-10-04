# Concurrency — Future, parallel calls, thread-bound sessions

Read this when you're about to use `Future` / `CompletableFuture`, run calls
in parallel, or touch a Nuxeo or Documentum session from another thread. The
rule itself is in `SKILL.md` ("What NOT to use Vavr for"): a `Future` is an
effect, it lives in the shell, and a session never crosses threads.

## What a Vavr `Future` is

- **Eager.** `Future.of(...)` submits the work immediately. Unlike `Lazy`,
  nothing waits for a `get()`; unlike `IO`, it is not a description you run
  later. Creating one *is* the side effect.
- **Its result is a `Try`.** `future.getValue()` gives
  `Option<Try<T>>` — empty while running, then success or the exception.
  Convert to a domain `Either` at the boundary, as with any `Try`.
- **It runs on an executor.** Pass one explicitly
  (`Future.of(executor, () -> ...)`) instead of relying on the default shared
  pool: you control the pool size, and tests can pass a same-thread executor
  so they stay deterministic.

`CompletableFuture` is the JDK equivalent. Pick one per codebase; don't mix
them in one pipeline.

## When it's worth it

Only when **all** of these hold:

1. Two or more calls are **independent** — neither needs the other's result.
2. Each one is **slow I/O** (a remote call, a query) — see "Is it costly?"
   in `SKILL.md`. Pure in-memory work on small data gets slower in parallel,
   not faster.
3. The wait actually matters to someone (a user request, a batch window).

Otherwise call them one after the other: the sequential version is shorter
and has no thread to reason about.

## Shape: start in the shell, wait in the shell, decide in the core

```java
Result handle(Request req) {                                         // shell
    Future<Customer> customer = Future.of(executor, () -> crm.load(req.customerId()));
    Future<Seq<Order>> orders = Future.of(executor, () -> erp.orders(req.customerId()));

    return customer.zip(orders)
        .await(5, TimeUnit.SECONDS)                                  // bounded wait
        .toTry()
        .toEither()
        .mapLeft(LoadFailure::from)
        .map(both -> pricing.quote(both._1, both._2));               // pure core
}
```

- Start the futures, then wait **once**, with a timeout. An unbounded wait
  turns a slow dependency into a hung thread.
- `Future.sequence(listOfFutures)` combines a list, like
  `Either.sequenceRight` does for `Either` (`references/composition.md`).
- The core still receives plain values. It never sees a `Future`.
- Java 21: on virtual threads, plain blocking calls are cheap, so an
  executor of virtual threads plus ordinary sequential-looking code is often
  clearer than a `Future` chain. Prefer it when available.

## Thread-bound sessions: Nuxeo and Documentum

Both platforms tie a session to the thread (and transaction) that opened it.
Passing one into a `Future` compiles and then fails at runtime — or worse,
works in a test and corrupts state under load.

- **Nuxeo:** a `CoreSession` belongs to its thread and its transaction. A
  task running on another thread must open **its own** session and
  transaction, and close them when done. Pass document *ids* across
  threads, never `DocumentModel`s or the session.
- **Documentum (DFC):** an `IDfSession` must not be shared across threads.
  **Author's recollection, not yet verified:** futures only worked when each
  task used a **distinct `IDfSessionManager`**, not just a separate session
  from a shared one. Treat that as the safe default until it's confirmed,
  and report back what holds. Each parallel task also takes a session from
  the docbase's concurrent-session limit, so bound the pool size.

If a task needs a session, ask first whether parallelism is worth a second
session and transaction per task. Usually it isn't.
