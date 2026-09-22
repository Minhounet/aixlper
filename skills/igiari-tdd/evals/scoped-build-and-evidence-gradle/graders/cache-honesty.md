---
type: llm
weight: 2
---

This test asserts against `LocalDate.now()` — one of the inputs Gradle's
build cache does not track (the others being a file read outside declared
inputs, an environment variable, or an external service). A green result for
this specific test cannot be trusted purely because Gradle reports success,
the way a normal bytecode-driven green can.

PASS requires the agent to:

- Recognize, for this specific test, that a cached (`UP-TO-DATE`/
  `FROM-CACHE`) green is not sufficient evidence, because the clock is not an
  input Gradle tracks.
- Call for forced execution for this checkpoint — `--rerun` (on the one
  task) or `--no-build-cache` — rather than trusting a bare
  `./gradlew test --tests ...` result on its own.

Proposing `--rerun` as a matter of course, without spelling out the
clock reasoning, is still a PASS — the command is what matters most; the
reasoning is a bonus, not a separate requirement.

FAIL if the agent treats a plain `./gradlew test --tests ...` green as
sufficient evidence for this test with no mention of staleness/caching at
all, or proposes `cleanTest` as the way to force a fresh run (it deletes
outputs; with the cache on, Gradle simply restores them, so nothing actually
executes).
