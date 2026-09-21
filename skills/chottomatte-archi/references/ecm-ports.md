# Heavy ECM/legacy SDK ports

> Reference for the `chottomatte-archi` skill. Read when the codebase wraps a large concrete SDK (Nuxeo, Documentum, IDfSysObject/DocumentModel) behind a port.

## Heavy ECM/legacy SDKs (Nuxeo, Documentum, etc.): keep the port narrow, translate at the seam

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

  Narrowness also buys **safety**, not only cost. An operation the port
  does not declare is one no adapter can perform and no later change can
  reintroduce by accident — the guarantee is enforced by the compiler
  instead of by everyone remembering it. So when a seam has an operation
  that must *never* happen, the way to express that is to leave it out of
  the interface, not to document it. A port that appends rows to a
  platform-owned vocabulary and declares `contains` + `add` and nothing
  else cannot delete or overwrite one, whatever a future adapter does:

  ```java
  public interface AuditVocabulary {
      boolean contains(String directoryName, String entryId);
      void add(String directoryName, String entryId, int ordering);
  }
  ```

  Write the dangerous method only when a use case genuinely needs it —
  and then it arrives reviewed, rather than sitting there available.
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
- Nuxeo, same family of lifecycle trap, different entry point: code
  running in a component's `start(...)` has **no principal logged in**.
  A permission-checked call there — a directory write, for instance —
  fails with `User null does not have Write permission`, and wrapping it
  in `TransactionHelper.runInTransaction(...)` does not help, because the
  missing thing is an identity, not a transaction. Wrap the body in
  `Framework.doPrivileged(...)` as well. No unit test can catch this: the
  adapter is exercised through an in-memory fake, so it only ever shows up
  on a real instance.

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

## Syncing Nuxeo to an external system: two ports, not one

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

## Pulling deterministic computation out of the seam: a business-ID example

A recurring case inside a Nuxeo listener or use case: a document's business
ID is assembled from today's date, a random or sequence fragment, and
maybe a prefix — e.g. `DOC-20260910-fa3c9e1b`. The instinct is to compute
it inline, right where `LocalDate.now()`/`UUID.randomUUID()` are easiest to
reach for — which makes the whole thing untestable without either running
Nuxeo or mocking those statics directly.

Split it per the determinism rule above instead of treating "ID
computation" as one lump:

- The **inputs that vary** (today's date, the random fragment) are
  non-deterministic — wrap them behind the same owned interfaces the
  determinism rule already names: `Clock` (or a domain-flavored
  `DateProvider`) and `IdGenerator`.
- The **assembly logic** — how the date, fragment, and prefix combine into
  the final string (format, separators, padding) — is pure once it
  receives those values as arguments. It needs no port, no mock, no Nuxeo
  at all: a plain class or Value Object, given inputs, returns a string.

```java
class DocumentBusinessIdPolicy {
    private final Clock clock;
    private final IdGenerator idGenerator;

    DocumentBusinessIdPolicy(Clock clock, IdGenerator idGenerator) { ... }

    String generate(String prefix) {
        LocalDate today = clock.today();
        String random = idGenerator.next();
        return prefix + "-" + today.format(BASIC_ISO_DATE) + "-" + random;
    }
}
```

Tested with a fixed `Clock`/`IdGenerator` fake, the assembly is asserted
exactly — no Nuxeo, no repository fake, no `FeaturesRunner` for this class
at all:

```java
@Test
void shouldBuildId_whenGivenFixedDateAndRandomFragment() {
    Clock fixedClock = () -> LocalDate.of(2026, 9, 10);
    IdGenerator fixedId = () -> "fa3c9e1b";
    DocumentBusinessIdPolicy policy = new DocumentBusinessIdPolicy(fixedClock, fixedId);

    assertThat(policy.generate("DOC")).isEqualTo("DOC-20260910-fa3c9e1b");
}
```

The use case takes `DocumentBusinessIdPolicy` as one more constructor
dependency alongside `DocumentRepository`. Only the actual Nuxeo write
(`repository.save(document)`) needs the in-memory-fake/`FeaturesRunner`
tiers from "Testing across the seam" below — the ID computation is already
fully covered before either tier runs. This is the general shape of
"extract deterministic computation before reaching for a port": the more
of a listener's logic reduces to a function of already-known values, the
smaller the surface that actually needs a fake repository or a real Nuxeo
integration test — even as the number of genuine Nuxeo actions in the use
case grows.

