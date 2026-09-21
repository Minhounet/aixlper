# Nuxeo

## Listener event filtering

Always declare which events a listener handles in the OSGI-INF XML (`<event>` elements), not in Java.

```xml
<listener name="myListener" class="..." async="true" postCommit="true">
  <event>documentCreated</event>
</listener>
```

For `PostCommitFilteringEventListener`, `acceptEvent()` must return `true` — the XML is the single source of truth. Never re-check the event name in `acceptEvent()` or `handleEvent()` when the XML already restricts it.

## Component documentation

Always add a `<documentation>` tag inside every OSGI-INF component definition. It appears in the Nuxeo Admin Center when browsing components and makes the addon self-documenting.

```xml
<component name="com.example.myaddon.MyComponent" version="1.0">

  <documentation>
    One or two sentences describing what this component registers and why.
  </documentation>

  <extension target="..." point="...">
    ...
  </extension>

</component>
```

## Audit events: contributing the name is not enough

Declaring an event under `org.nuxeo.audit.service.AuditComponent` / `event`
makes it persist. It does **not** make it reachable from the UI, and the two
registries are unrelated — nothing warns you about the gap.

The Web UI **History tab and `/admin/audit` are the same element**
(`nuxeo-audit-search`; the `DOCUMENT_VIEWS_PAGES` slot renders it with a
`document` bound). Its two filters are `nuxeo-directory-suggestion` widgets
over the `eventTypes` and `eventCategories` vocabularies, with no free-text
fallback — so an event missing from those vocabularies **cannot be selected
at all**, however well it persists. Adding the rows is a separate piece of
work from contributing the event; see chottomatte-archi's *Nuxeo
platform-seeded vocabularies* for how to add them without destroying the
platform's own.

Labels are a third, separate thing, and there are two different key shapes:

| Where | Key | Fallback when missing |
|---|---|---|
| Filter dropdown | the row's own `label` field, resolved as an i18n key (platform rows set `label` == `id`, e.g. `eventDocumentCategory=Document`) | the raw id |
| History "Performed action" column | `eventType.<eventId>` | the literal key |
| History "Category" column | `eventCategory.<category>` | the literal key |

The column keys fall back to the **key itself**, not the id, so an untranslated
custom event reads as `eventType.myCustomEvent` on screen. Contribute all
three in the Studio project's `data/i18n`, which is where a Studio-based
project normally owns its translations.

One thing no filter can fix: a purged document's audit entries are
unreachable from any document-scoped screen — `GET /api/v1/id/{docId}` and
`/@audit` both return 404 once the document is gone, even though the entries
survive with that `docUUID`. A destruction event is therefore never visible
in the History tab, and needs its own screen.

## Gradle for dev speed, Maven mandatory for release

A Nuxeo addon can never fully drop Maven: the marketplace package and the OSGi
bundle format are Maven-plugin-driven, so Maven stays the tool of record. But
a Gradle build can be added *underneath* it, scoped to compile+test only,
purely to speed up the local dev loop. Treat it as strictly additive — every
Maven-only developer's workflow must keep working unchanged.

Two things break silently if you do this without care, both worth knowing
before attempting it:

- **The bundle manifest.** Nuxeo reads its component registration list
  (`Bundle-SymbolicName`, `Nuxeo-Component`, ...) from `META-INF/MANIFEST.MF`.
  A hand-written manifest in `src/main/resources` is not picked up by
  Gradle's `jar` task automatically — without explicitly merging it in
  (`manifest.from(...)`), the Gradle-built jar loads into Nuxeo with no error
  and registers *nothing*: no listeners, no services, no operations.
- **`FeaturesRunner` tests under a warm, non-forking JVM.** Any flag that
  runs tests inside the build's own daemon JVM instead of a fresh fork
  (Maven's `-DforkCount=0`; the same hazard applies to any comparable Gradle
  setting) boots the Nuxeo test runtime in-process. The first run in a fresh
  daemon passes; the runtime is then still alive in that daemon on every
  subsequent run, so the *next* run in the same daemon fails with something
  like `Error while invoking start on features: [...]`, reporting far fewer
  tests than exist. It looks exactly like a code regression, not a build
  config issue. Keep in-JVM test execution for plain unit tests only, never
  for a `FeaturesRunner` (or any other in-process-runtime) test class.

Given those two guarded, the useful combined workflow is three-tier, one
tool per concern:

1. **Inner loop** — Gradle in continuous/watch mode, scoped to the one test
   class you're working on. It re-runs on save with no command to retype.
   Don't add a "clean" step to force re-execution — it only clears output
   files, which the build cache then silently restores (`FROM-CACHE`), so it
   adds time without adding safety. To force genuine re-execution, use
   Gradle's own rerun/no-cache flag instead.
2. **Checkpoint** — a full Gradle test run at the end of a task or before a
   refactor step. This is where Gradle's speed actually matters: parallel
   module execution across a multi-module addon reliably beats Maven's more
   sequential reactor by several times on the full suite, even though a
   single scoped test class is roughly a wash between the two tools.
3. **Gate** — Maven (a warm-daemon Maven runner if available) as the last
   check before commit/push, and the only tool for actual packaging. Its
   value here is exactly that it does *not* cache anything — it's the
   trustworthy arbiter precisely because every run is a real one, and it's
   the same toolchain CI and the marketplace build will use.

The one thing no automation catches: a dependency **added or removed**
(not just version-bumped) must be applied to both the Maven POM and the
Gradle build file in the same change. A version-drift guard can be scripted
per-project; a wholly new dependency declared in only one build file is not
something either tool will warn you about.
