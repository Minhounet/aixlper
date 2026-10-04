# Is it costly? Classify before you defer

Read this when deciding whether a value is costly enough to defer (a lambda,
`Supplier`, `Lazy`) or to build once as a field. The rule — defer only what
is costly, compute everything else eagerly — is in `SKILL.md` under
"Laziness".

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

## Memoizing: one cached result per argument

`Lazy` caches one value with no argument. Memoizing caches one result **per
distinct argument**. Vavr's `Function0`…`Function8` all have `.memoized()`;
a method reference must first become a Vavr function:

```java
private final Function1<String, Rule> ruleFunction =
    Function1.of(this::parseRule).memoized();
private final Function2<String, Integer, Schema> schemaFunction =
    Function2.of(this::loadSchema).memoized();
```

No argument → `Lazy`, not `Function0.memoized()`: same behavior, but `Lazy`
says "computed later, once", has `isEvaluated()` and a non-forcing `map`,
and is the idiom a reader recognizes. A `Map<Key, Lazy<V>>`, or a `Lazy`
rebuilt per argument, is a memoized function in disguise.

### Memoize only when all four hold

1. **Pure** — the same argument always gives the same result.
2. **Costly** — per the checklist above.
3. **Called again with the same arguments** — otherwise the cache never hits.
4. **A small, bounded set of arguments** — a few dozen rule codes or
   document types, not ids that grow with the data. Vavr's memoized cache
   has no maximum size and never evicts.

### Pick the tool by how long the cache lives

| Scope | Tool |
|---|---|
| One call or one request (repeated lookups inside a batch) | A local `Map` + `computeIfAbsent`, discarded at the end: bounded by the input, never stale |
| One instance, small fixed argument set | A memoized `FunctionN` field, or `Lazy` with no argument |
| Application-wide, growing arguments, or data that changes | Not memoization — a cache with a maximum size and an expiry (e.g. Caffeine), in the shell or behind a port |

### Traps

- **Memoizing a remote call** (a Nuxeo `getDocument`, a docbase query, a
  gateway call): the data changes, so it needs expiry and invalidation —
  a cache with explicit rules, not `.memoized()`.
- **Caching session-bound objects** (`DocumentModel`,
  `IDfPersistentObject`): stale or broken after their session or
  transaction ends. Cache ids or plain values.
- **`null`:** Vavr's memoized functions reject `null` as a single argument
  or as a return value. Return `Option` instead.
- **Recursion through `HashMap.computeIfAbsent`:** a function that calls
  itself through the same map while computing throws
  `ConcurrentModificationException` (Java 9+).
- **A memoized function in a `static` field:** its cache lives as long as
  the JVM. Use an instance field, or keep it local.
