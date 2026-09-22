---
type: llm
weight: 2
---

Judge whether the agent scopes the build to the single test and bounds the
command's output, the Gradle way.

PASS requires all three:

- The command is **scoped to the one test class or method** via `--tests`
  (e.g. `--tests "com.example.InvoiceDueDateTest"`, optionally with a method
  suffix, or Gradle's own `--tests "*.ClassName.methodName"` wildcard form)
  rather than a bare `./gradlew test` or a full `./gradlew build`. A
  module-qualified task path (`./gradlew :module-name:test --tests ...`) is
  correct and expected for a multi-module project — do not fail for
  including it. Noting the wildcard form's tradeoff (it could match more
  than one package) as a caveat, while still using it, is not a failure —
  judge the command that was actually given, not the caveat.
- It suppresses Gradle's redraw/progress noise — `--console=plain` appears.
  `-i`/`--info`/`--debug` must not appear as part of the normal cycle.
- It bounds what is echoed back, e.g. piping through `tail`, or the agent
  explicitly says the per-test result line plus exit status is sufficient
  evidence rather than the full log.

FAIL if the agent proposes a full-project build (`./gradlew build`) to
observe one test, or proposes `-i`/`--info`/`--debug` as part of the normal
cycle.
