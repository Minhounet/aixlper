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
