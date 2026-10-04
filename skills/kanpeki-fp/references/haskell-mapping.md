# Haskell effects → their Java equivalent here

Read this when reasoning in Haskell/FP terms (Reader, Writer, IO,
`Debug.Trace`) and you need the Java equivalent this codebase uses. The
rules are in `SKILL.md` ("Logging", "Functional core, imperative shell",
"Laziness"); this table only translates.

| Need | Haskell | This codebase |
|---|---|---|
| Access to dependencies (config, repositories, reporter) | `Reader Env a` | Constructor injection (`chottomatte-archi`): the environment is given once, when the object is built, and every method reads it. |
| Produce a log or events without performing them | `Writer [Entry] a` | The returned value — `Either<SkipReason, T>`, a sealed `Action` — logged or executed by the shell. A full `record Logged<A>(A value, List<Entry> log)` only when the log *is* the output. |
| Perform effects | `IO a` | The shell, in plain imperative Java. No `IO` type: purity comes from where effects are placed, not from a type. |
| Diagnostic trace that doesn't change the result | `Debug.Trace` | `private static final Logger`, called from the shell only. |
| Defer a pure computation | Lazy evaluation (default) | A lambda / `Supplier` for one use; Vavr `Lazy` to compute once and cache. |
| Concurrent effect | `async` / `IO` + fibers | `Future` / `CompletableFuture` in the shell (`references/concurrency.md`). |

Vavr has no `Reader`, `Writer` or `IO`. Don't build them: `Function<Env, A>`
chains or `Logged<A>` wrappers everywhere cost readability, and the
equivalents above already give the benefit — a core you can test with
plain values.
