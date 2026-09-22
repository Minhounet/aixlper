# Nuxeo addon packaging, logging and vocabularies

> Reference for the `chottomatte-archi` skill. Read when packaging a Nuxeo addon: Maven module layout, composite log4j2, platform-seeded vocabularies.

## Nuxeo addon packaging: enforcing dependency direction with Maven modules

Nuxeo deploys addons as a collection of OSGi bundles — not an uber-JAR. The addon
marketplace package (ZIP) contains:

- `bundles/` — OSGi JARs with `Bundle-SymbolicName` in `MANIFEST.MF`; Nuxeo-aware components
- `lib/` — plain library JARs; visible to all bundles via Nuxeo's classloader

This is an opportunity to enforce the dependency direction at the **Maven compiler
level**, not just by convention. Split the addon into two Maven modules:

- **Core/adapter module** (e.g. `my-addon-core`, `my-addon-soap`): model classes, use
  case interfaces, gateway interfaces, and pure infrastructure adapters (HTTP clients,
  SOAP clients). **Zero Nuxeo dependency.** Ends up in `lib/`.
- **Nuxeo bundle module** (e.g. `my-addon-nuxeo`): `EventListener`,
  `AbstractComputation`, `DefaultComponent` services, OSGI-INF XML, `MANIFEST.MF`.
  Depends on the core module. Ends up in `bundles/`.

The compiler enforces that the core module cannot import a single Nuxeo class — the
Maven dependency simply doesn't exist in that module. Tests for the core module need
no `nuxeo-runtime-test` infrastructure: WireMock or Mockito is sufficient.

The bundle module's `pom.xml` declares the core as a `compile`-scope dependency. The
packaging module (e.g. `hydro-package`) collects both JARs into their respective
directories.

Default to this split for any Nuxeo addon whose external adapter (REST, SOAP, Kafka
producer) has no inherent Nuxeo dependency. The overhead is one extra `pom.xml`, one
`<modules>` entry in the parent, and one `<dependency>` in the bundle module — a
small cost for a compiler-enforced boundary.

## Nuxeo addon logging: composite log4j2, never editing the shipped config

An addon needing its own appenders/categories should never edit Nuxeo's
shipped `log4j2.xml` directly — that fix would have to be reapplied on
every environment and every Nuxeo upgrade. The actual mechanism is
Log4j2's own **Composite Configuration** feature (not Nuxeo-specific):
merge multiple config sources into one `LoggerContext`, later sources
overriding matching Appenders/Loggers by name, the original file
untouched on disk.

Two ways to trigger the merge — which one fits depends on what you
actually control:

- **You own the deployment** (build your own Docker image, control
  `nuxeo.conf`): pass
  `-Dlog4j2.configurationFile=<default-path>,<your-fragment-path>` via a
  `JAVA_OPTS` line appended in `nuxeo.conf` (or a file dropped under
  `docker-entrypoint-initnuxeo.d/` for the official image). Simple, but
  ties the addon's logging setup to how a specific image/environment is
  built — every deployment target has to remember to wire it.
- **You only own the addon bundle** (the usual case): ship the fragment as
  a plain classpath resource inside the addon jar — never named
  `log4j2.xml`, which would collide with Nuxeo's own file — and merge it
  programmatically when your component starts:

```java
public class MyAddonComponent extends DefaultComponent {

    private static final String FRAGMENT = "/log4j2-myaddon.xml";

    private static final Logger log = LogManager.getLogger(MyAddonComponent.class);

    @Override
    public void start(ComponentContext context) {
        LoggerContext ctx = (LoggerContext) LogManager.getContext(false);

        if (ctx.getConfiguration() instanceof CompositeConfiguration) {
            log.warn("Log4j2 config is already composite; not merging {}", FRAGMENT);
            return;
        }

        ConfigurationSource base = ctx.getConfiguration().getConfigurationSource().resetInputStream();
        InputStream fragment = getClass().getResourceAsStream(FRAGMENT);
        if (base == null || fragment == null) {
            log.warn("Not merging {}: base re-readable={}, fragment present={}",
                    FRAGMENT, base != null, fragment != null);
            return;
        }

        ConfigurationFactory factory = ConfigurationFactory.getInstance();
        List<AbstractConfiguration> configs = List.of(
                (AbstractConfiguration) factory.getConfiguration(ctx, base),
                (AbstractConfiguration) factory.getConfiguration(ctx, new ConfigurationSource(fragment)));

        Configurator.reconfigure(new CompositeConfiguration(configs));
    }
}
```

Three details in there are load-bearing, and each one fails **silently** if
dropped — the merge replaces Nuxeo's real configuration with an empty one,
so CONSOLE and FILE both vanish with no error logged anywhere:

- **`start`, not `applicationStarted`.** The latter no longer exists on
  `DefaultComponent` in current LTS; only `start(ComponentContext)` remains.
- **`resetInputStream()`, never the live `ConfigurationSource`.**
  `XmlConfiguration`'s constructor drains the source via `toByteArray` and
  then closes it, and never calls `setData` — so handing that same source
  back to the factory re-reads a *closed* stream. `resetInputStream()`
  reopens it from the underlying file or URL, and returns `null` when it can
  do neither.
- **The `CompositeConfiguration` guard.** If the deployment already passes a
  *multi-path* `-Dlog4j2.configurationFile`, the live configuration is
  itself a composite, and `getConfigurationSource()` then answers
  `ConfigurationSource.COMPOSITE_SOURCE` — an empty byte array. The two
  forms above are therefore mutually exclusive: adopting this one means
  cutting that flag back to a single path.

**Scale the choice to how often the fragment actually changes.** The
self-contained form is genuinely env-independent, but what buys that is a
merge against global mutable state carrying the three silent failure modes
above — spent to avoid editing a deployment descriptor. It earns its keep
when appenders or layout change often, or when the deployment is truly not
yours. It does not earn it when the recurring need is "give me DEBUG right
now": that is a level bump, which the Automation operation below delivers on
its own, with no merge, no guard, and nothing to change outside the addon.
Reach for the operation first, and add the merge only once a concrete need
to reshape the fragment outlives it.

**Tradeoff that comes with the self-contained form: the jar-embedded
fragment is not hot-editable.** Log4j2's `monitorInterval` file-watcher
needs a real filesystem `File` with a checkable mtime to detect changes;
a classpath resource packed inside a jar can't provide that. Editing the
fragment's content means rebuilding and redeploying the addon — a direct
consequence of the choice above, not a separate limitation to work
around.

**A runtime debug bump is a different concern from the baseline config —
don't reach for file-editing to solve it.** The baseline (what logs
during normal operation) and a temporary incident-response bump (DEBUG
for twenty minutes) have opposite lifetimes: the baseline should survive
restarts unchanged, the bump specifically shouldn't. Give whoever
operates the addon both live-change mechanisms, built once, and let them
pick per their own environment's constraints rather than picking one for
them:

- **JMX** (Log4j2's built-in MBeans, `Configurator` underneath) — zero
  extra code, since Log4j2 exposes this by default. Needs a JMX port
  reachable from wherever the change is being made, which is often
  blocked in a containerized/production Nuxeo deployment.
- **An Automation operation wrapping `Configurator.setLevel(...)`** —
  a small addition, but only needs network access to Nuxeo's own REST
  API (already available to on-call), is trivially securable to
  Administrators, and reverts with the same call. The more practical
  default for "need DEBUG right now" in most Nuxeo production setups —
  no exec/file access into the running container needed, and nothing
  left behind to forget about afterward the way a hand-edited file can be.

```java
@Operation(id = SetLogLevel.ID, category = Constants.CAT_SERVICES,
        label = "Set Logger Level", description = "Change a logger's level at runtime, no restart.")
public class SetLogLevel {
    public static final String ID = "MyAddon.SetLogLevel";

    @Param(name = "logger") protected String loggerName;
    @Param(name = "level") protected String level;

    @OperationMethod
    public String run() {
        return Option.of(Level.getLevel(level))
                     .toEither(() -> new InvalidLevel(level))
                     .peek(parsed -> Configurator.setLevel(loggerName, parsed))
                     .fold(invalid -> {
                         throw new NuxeoException("Unknown log level: " + invalid.levelName());
                     }, applied -> loggerName + " -> " + applied);
    }
}
```

**`Level.getLevel`, never `Level.toLevel`.** The single-argument
`toLevel(String)` answers `DEBUG` for any name it doesn't recognise, so an
operator's typo — `"WARNING"`, or a trailing space — silently switches
production to DEBUG instead of being rejected. `getLevel(String)` returns
`null` for an unknown name, which is what lets the operation fail loudly.
Keeping the parse in a small owned class (here, whatever produces
`InvalidLevel`) rather than inline in the operation is what makes that
rejection unit-testable without a Nuxeo runtime — the operation stays a thin
adapter, per "the entry point isn't always yours" above.

Reach for an external override path instead only when the actual need is
structural — a new appender or filter added live — not a level bump.
That's the one case where `monitorInterval`'s file-watching genuinely
earns back the env-dependency the jar-embedded form was chosen to avoid.

**This route must be seeded at boot, not created on demand, if the
environment can't tolerate a restart.** An ephemeral/immutable container
(ops has exec access into the running instance, but restarting means the
orchestrator destroys and recreates it from the image, wiping anything
placed by hand) can't use "drop the file in later" — Log4j2 only watches
a `ConfigurationSource` it already loaded into the composite at
component `start`; a file that didn't exist at boot was never handed
to it, so creating one afterward inside the still-running container is
invisible, restart or not. The fix is to always include the override
path in the composite from boot — even as an empty/minimal stub config —
with `monitorInterval` set on that source. Then a later exec-in-and-edit
is picked up by Log4j2's own watcher with zero restart of the app or the
container, which is the actual requirement in that kind of environment.
"Checked at startup, falls back to the jar-embedded default if absent" is
the wrong shape here — it silently drops this capability exactly where
it's needed most.

## Nuxeo platform-seeded vocabularies: append at runtime, never take over the dataFile

Same principle as the log4j2 case above, on a different platform-owned
resource. Some Nuxeo vocabularies are the platform's, not yours —
`eventTypes` and `eventCategories` are seeded from CSVs shipped inside
`nuxeo-platform-audit-core`. An addon that contributes its own audit events
has to get them into those vocabularies or they are invisible to anything
reading the vocabulary, but it must not take ownership of them.

The obvious declarative move is the destructive one:

```xml
<!-- WRONG: replaces the platform CSV, does not add to it -->
<directory name="eventTypes" extends="template-vocabulary">
  <dataFile>directories/my-event-types.csv</dataFile>
</directory>
```

`BaseDirectoryDescriptor` holds a **single `dataFileName`** field, so a
second contribution for the same directory overrides the platform's rather
than merging with it. What makes this genuinely dangerous is *when* it
fails: `createTablePolicy` is `on_missing_columns`, so on an existing
database the table is already populated and nothing appears to happen —
the override looks harmless. The built-in rows vanish only when the table
is next created, i.e. on a fresh environment or a rebuilt one, long after
the change was reviewed and merged.

Append at runtime instead, from a `DefaultComponent` whose
`getApplicationStartedOrder()` puts it after the directory service, behind
a narrow port that cannot do anything but add (see *keep the port narrow*
above — this is the safety argument, not the cost one):

```java
@Override
public void start(ComponentContext context) {
    super.start(context);
    // doPrivileged as well as runInTransaction: component start has no principal.
    TransactionHelper.runInTransaction(() -> Framework.doPrivileged(this::seed));
}
```

Make the seeding **idempotent by construction** — read the entry, add only
what is absent — because it runs on every start, and a blind
`createEntry` throws a duplicate-key `DirectoryException` the second time.
Verify it on a real instance rather than by reasoning: diff the full set of
row ids before and after, not the row count, then restart once to prove
idempotence, then delete one seeded row and restart to prove the component
actually still runs and re-adds only that one. Unchanged counts alone
cannot distinguish "correctly did nothing" from "never executed".

One thing this does *not* buy: the vocabulary row makes the value
selectable, not readable. Nuxeo resolves a row's `label` field as an i18n
key, and platform rows set `label` equal to `id` — so an unseeded
translation shows the raw id. That part is a translation contribution, not
an architecture concern.

