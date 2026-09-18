# Java

## Injected fields

Injected dependencies are always `private final`. No field injection (`@Autowired` on a field), no setter injection unless a legacy framework genuinely blocks the constructor path.

## Line length — 121 chars max (IntelliJ project default)

Break long lines at natural boundaries.

**Stream chains** — one operation per line, dot leading:
```java
list.stream()
    .filter(x -> x.isActive())
    .map(x -> x.getName())
    .toList();
```

**Long method calls** — one argument per line when the call exceeds the limit:
```java
Framework.getService(MyDocumentService.class)
         .processDocLifecycle(
                 ctx.getCoreSession(),
                 doc,
                 (String) ctx.getProperty("transition"));
```

When the receiver itself is long, extract it into a named variable first:
```java
var service = Framework.getService(MyDocumentService.class);
service.processDocLifecycle(
        ctx.getCoreSession(),
        doc,
        (String) ctx.getProperty("transition"));
```

## Log levels

- `DEBUG` — internal diagnostic detail: what the code is doing, what it decided, what it skipped. Useful when debugging; invisible in production.
- `INFO` — business-relevant events that matter in production: a message was queued, a service started, a config switch is active.
- `WARN` — something unexpected but recoverable happened.
- `ERROR` — something failed and needs attention.

Never raise a diagnostic log to INFO just to make it visible during a debugging session. Put it at DEBUG and configure the logger level if you need to see it temporarily.

## TDD order — tests always before production code

This applies to every change: new features, bug fixes, and refactors alike.

1. **Red** — write or update the test first. If the change affects a constructor signature, update every affected test constructor call first. The code must not compile, or the test must fail.
2. **Green** — change only the production code needed to make the test pass. Nothing else.
3. **Refactor** — clean up with tests green.

**Never touch a production source file before the test is red.** For constructor signature changes specifically: update all test call sites first, confirm the build fails to compile, then fix the production constructor.
