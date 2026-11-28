---
name: java-testing
description: How the billing teams write and run Java tests - JUnit 5, AssertJ, Mockito only at the edges, and mutation testing with PIT. Use when writing or reviewing Java tests.
---

# Java testing

## Unit tests
- JUnit 5 and AssertJ. One behavior per test, named `should_<result>_when_<condition>`.
- Mock only what crosses a process boundary (HTTP, database, queue).

## Mutation testing (PIT)
- Run PIT on the classes changed by the merge request only, never on the
  whole codebase: `mvn -Pmutation -DtargetClasses=<changed classes>`.
- The `mutation` profile fails the build below a 60% mutation score.
