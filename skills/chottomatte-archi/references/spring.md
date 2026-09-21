# Spring wiring

> Reference for the `chottomatte-archi` skill. Read when the project uses Spring, or when resolving environment-driven config objects at the composition root.

## Spring: keep it out of the core, prefer bean configuration

Default preference: use case / domain / service classes carry **no Spring
annotations** — no `@Component`, `@Service`, `@Autowired`. They stay the
plain, constructor-injected classes described above. Wiring happens in
explicit `@Configuration` classes with `@Bean` methods at the composition
root, so the dependency graph is visible in one place you can read like a
plan, and the core stays runnable/testable outside a Spring context.

```java
// core — no Spring
public class RegisterUserUseCase {
    private final UserRepository userRepository;
    private final Logger logger;

    public RegisterUserUseCase(UserRepository userRepository, Logger logger) {
        this.userRepository = userRepository;
        this.logger = logger;
    }
}

// composition root — Spring lives here, not in the core
@Configuration
public class UseCaseConfig {

    @Bean
    public RegisterUserUseCase registerUserUseCase(UserRepository userRepository, Logger logger) {
        return new RegisterUserUseCase(userRepository, logger);
    }
}
```

**Reality check:** you'll sometimes land in a project that already
annotates domain/use-case classes directly (`@Service` + `@Autowired`
constructor). That's not the preferred shape, but ripping it out
project-wide is a different task from whatever you were asked to do.
Same seam rule as legacy entry points: don't fight the codebase's
existing convention in the middle of an unrelated task; prefer bean
configuration going forward when you're adding something genuinely new
and it's practical to do so.

## Logger: bind the injection point to the right class

A single shared `Logger` bean can't be scoped to the class using it. Use
Spring's `InjectionPoint` to hand each constructor the logger for its own
declaring class:

```java
@Configuration
public class LoggerConfig {

    @Bean
    @Scope("prototype")
    public Logger logger(InjectionPoint injectionPoint) {
        return LoggerFactory.getLogger(injectionPoint.getMember().getDeclaringClass());
    }
}
```

Every class with a `Logger` constructor parameter gets a logger bound to
itself, without hand-writing `LoggerFactory.getLogger(ThisClass.class)`
in every constructor. Outside Spring (or without bean config), the
hand-written form is the equivalent and is perfectly fine.

## Environment-driven config objects: resolve properties at the composition root

When a parameter object (see *Threading shared configuration* under
*Author's preferences* below) needs its values from environment/properties
rather than a literal in code, the core class still never sees `@Value`
or `@Component` — only the `@Configuration` class touches Spring's
`Environment`:

```java
// core — a plain POJO, still no Spring
public interface ProcessingConfig {
    Set<String> attributesToKeepEmpty();
}

public class DefaultProcessingConfig implements ProcessingConfig {
    private final Set<String> attributesToKeepEmpty;

    public DefaultProcessingConfig(Set<String> attributesToKeepEmpty) {
        this.attributesToKeepEmpty = attributesToKeepEmpty;
    }

    @Override
    public Set<String> attributesToKeepEmpty() {
        return attributesToKeepEmpty;
    }
}

// composition root — the Environment lookup lives here, not in the core
@Configuration
public class ProcessingConfiguration {

    @Bean
    public ProcessingConfig processingConfig(Environment environment) {
        String raw = environment.getProperty("app.processing.keep-empty-attributes", "");
        Set<String> attributes = Arrays.stream(raw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toSet());
        return new DefaultProcessingConfig(attributes);
    }
}
```

The interface here is the same one the config object always has, per
"Constructor injection, always" — this pattern is just one concrete
implementation of it. The composition root turns a raw property string
into `DefaultProcessingConfig`; a test can turn a literal `Set.of(...)`
into a different `ProcessingConfig` implementation just as easily,
without either one touching the use case's constructor.

## Without Spring (e.g. Nuxeo): a plain resolver instead of `@Profile`

Spring's `@Profile` picks which `@Bean` method runs based on an active
profile — the same job as an `if (useLegacy)` scattered through business
code, done once, outside the core. Without Spring, the fix is the same
shape, just without the annotation: put the branch in exactly one
resolver function at the composition point, reading whatever config
mechanism the framework offers instead of Spring's `Environment`. In
Nuxeo, that's `Framework.getProperty(...)` (backed by `nuxeo.conf`), read
at the same seam the "Heavy ECM/legacy SDKs" section above already uses
for `Framework.getService(...)` — inside `handleEvent`, never the
listener's constructor:

```java
// composition code, inside handleEvent — the only place the flag is read
private PaymentGateway resolvePaymentGateway() {
    boolean useLegacy = Boolean.parseBoolean(
            Framework.getProperty("myaddon.payment.legacy", "false"));
    return useLegacy
            ? new LegacyPaymentGateway(Framework.getService(LegacySoapClient.class))
            : new RealPaymentGateway(Framework.getService(PaymentHttpClient.class));
}
```

`PaymentGateway`'s consumers — the use case, its tests — never see the
flag; the constructor only ever takes the interface. If more than one
gateway flips on the same flag, pull the read into its own small resolver
class instead of repeating `Framework.getProperty` per call site, same
reasoning as the Parameter Object rule under *Author's preferences*: one
read, one place, reused. This is the general-purpose version of "Gateway
stand-ins" above — there the two implementations are a stopgap for a
not-yet-available integration; here they're two permanently-maintained
variants selected by config — but the fix is identical either way: the
`if` belongs at the composition point, never inside the use case.

