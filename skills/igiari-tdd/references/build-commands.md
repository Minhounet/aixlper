# Build commands and test evidence

> Reference for the `igiari-tdd` skill. Read when you need the actual
> scoped/full build invocation for Maven, mvnd or Gradle, or when a scoped
> run will not yield readable evidence.

## Build commands — scoped during the cycle, full only at the end

**Prefer `mvnd` whenever it is installed.** Check once, at the start of a task:

```bash
command -v mvnd
```

If that resolves, substitute `mvnd` for `mvn` in every command below — it is a
drop-in replacement with identical flags and output, but it keeps the JVM and the
resolved project model warm between invocations, which is most of what a scoped run
costs. Measured on one multi-module Nuxeo project: the same scoped test class went
from 21.9s under `mvn` to 10.8s under `mvnd`, against 0.2s of actual test time.

The first run of a session starts the daemon and is slow (~17s in that same
project); every run after it is the fast one, so never judge `mvnd` on its cold run
or conclude from it that the daemon is not helping. If it ever appears to serve
stale state, `mvnd --stop` clears it. Do not install it unprompted — just use it
when it is already there.

**Maven**
```bash
# scoped (during the cycle) — one test class, or one method
mvn test -Dtest=ClassNameTest
mvn test -Dtest=ClassNameTest#methodName

# full (end of task only, once)
mvn test
```

Surefire already fails when `-Dtest=` matches nothing: `failIfNoSpecifiedTests`
defaults to `true`. You do not need a flag to make a filter typo loud.

**Multi-module Maven.** The command above fails at dependency resolution when the
test class's module depends on a sibling module that is not installed in the local
repository. Build the sibling in the same reactor:

```bash
mvn -o test -pl <module> -am -Dtest=ClassNameTest \
    -Dsurefire.failIfNoSpecifiedTests=false
```

`-Dsurefire.failIfNoSpecifiedTests=false` is **required with `-am` and only there**:
the upstream modules legitimately contain no test matching the filter, and without
the override each of them fails the build. Do not carry this flag into a
single-module run — there it would hide a real filter typo.

Pass `-o` (offline) once dependencies are cached: without it, a project with
SNAPSHOT dependencies re-checks every configured repository on every cycle. If `-o`
fails on a genuinely missing artifact, run that one cycle online rather than dropping
the flag for the rest of the task.

**Measure before tuning the build.** If cycles feel slow, run once and compare the
per-test time Surefire reports against wall clock. When the tests are a small
fraction of the total, the cost is Maven startup and dependency resolution, and no
plugin flag will touch it — chasing `-Denforcer.skip` and friends wastes the very
time you are trying to save. The two levers that do work are `mvnd` (above) and
`-DforkCount=0`, which runs the tests in the build JVM instead of forking a fresh
one. On that same project the two together took the cycle from 21.9s to 6.5s.

`-DforkCount=0` is a cycle-only flag, and only once you have checked its two
conditions: no `argLine` and no jacoco anywhere in the build. Surefire discards both
without warning when it does not fork, so you would keep green tests and silently
lose coverage. Never use it for the end-of-task full build.

**Never use it for a test that boots an application runtime in-JVM** — a Nuxeo
`FeaturesRunner` test, an embedded container, anything that stands a framework up
inside the test JVM. With no fork that runtime boots inside the `mvnd` daemon, and the
daemon outlives the cycle, so the *second* run in the same daemon fails where the first
passed. Measured on one such class: 5 tests green in 4.8s on a cold daemon, then
`Error while invoking start on features: [...]` with 1 test reported on every run after,
until `mvnd --stop`. It does not degrade gracefully and it does not look like a
build-tool problem — it looks like the code under test broke, which in a TDD loop is the
most expensive possible lie. Plain unit tests are unaffected; keep the flag for those.

More generally, with no fork JVM-global state (static registries, counters, caches)
persists across runs — `mvnd --stop` clears it when results look impossible.

**Do not buy the last second by dropping `-am`.** It is measurably faster, but the
module then compiles against the sibling's jar in the local repository, which goes
stale the moment you edit that sibling — and because the old API is still present
there, you get silently outdated behaviour instead of a compile error. It is the one
speedup that can make a green cycle lie to you.

**Gradle**
```bash
# scoped (during the cycle) — one test class, or one method
./gradlew test --tests "com.example.ClassNameTest"
./gradlew test --tests "com.example.ClassNameTest.methodName"

# continuous — re-runs that scoped test on every save; the closest fit to this loop
./gradlew test --tests "com.example.ClassNameTest" --continuous

# full (end of task only, once)
./gradlew build
```

`--continuous` (short `-t`) is the nearest thing either tool has to a TDD mode: it
watches the task's inputs and re-runs on save, so red and green cost no command at all.
Rule 8 is unchanged — quote the output of each re-run.

**A green Gradle run does not always mean the test ran — but it is usually still honest.**
An edit that changes bytecode always re-runs the test, so the normal red/green cycle is
safe. What Gradle skips is the cases where skipping is correct: a comment-only edit leaves
the task `UP-TO-DATE`, and reverting to a state it already tested comes back `FROM-CACHE`
in a fraction of a second — in both the compiled program is identical to one that genuinely
passed.

The real exposure is inputs Gradle does not track: a file read from outside the task's
declared inputs, an environment variable, the clock, or an external service (a database, a
container, a remote endpoint). Those can change while Gradle's inputs do not, and it will
serve a cached green.

When a checkpoint has to be trustworthy, force execution with `--rerun` (one task) or
`--no-build-cache`:

```bash
./gradlew test --tests "com.example.ClassNameTest" --rerun
```

**Not `cleanTest`** — it deletes the task's outputs, and with the cache on Gradle simply
restores them: `> Task :…:test FROM-CACHE`, 927ms, nothing executed.

**Gradle loses each inner-loop run and wins the session.** Measured on one multi-module
project: 3217ms median per single-test run against Maven's 2840ms, but 7.6s against
26.7s on the full suite, since it runs each module's tests in parallel in reused JVMs.
The crossover is roughly 50 single-test runs per full-suite run — below that Gradle is
ahead across a whole task, which a cycle with a refactor checkpoint comfortably is. This
is not a reason to introduce Gradle: use whichever build the project already has.

## Getting evidence when the build tool fights you

Test report files (Gradle's `build/test-results/`, Maven's
`target/surefire-reports/`) sit inside directories that are gitignored by
near-universal convention — and a client that respects `.gitignore` for file
reads will be unable to open them. This is not an occasional fluke or a
quirk of one client: it will recur on any Java project, on any client that
honors `.gitignore`. Don't let it stall the cycle; route around it in this
order.

1. **Read evidence from console output, not report files.** This alone
   satisfies rule 8 without touching the filesystem at all:
   - Gradle: `./gradlew test --tests "com.example.ClassNameTest" --console=plain`
     — start without `-i`. Plain console already prints the per-test result.
     Add `-i` **only** if that genuinely showed nothing, and only for the one
     diagnostic run: INFO logs every task and dependency resolution, which is
     a large token cost inside a loop that builds every cycle. Drop it again
     immediately afterwards.
   - Maven: prints per-test results to console by default; add `-e` for
     failure detail (cheap — stack trace only, unlike `-X`, which must not
     be used in the loop).
2. **If the scoped run reports zero tests executed**, don't jump straight to
   a full build — check these in order:
   - **Filter mismatch first.** Confirm the fully-qualified class name in
     `--tests`/`-Dtest` matches the real package and class exactly. A wrong
     pattern silently matches nothing rather than erroring.
   - **Caching second**, only if the filter is confirmed correct — force a
     rerun with `--rerun-tasks` (Gradle). On Maven there is nothing to add:
     `failIfNoSpecifiedTests` already defaults to `true`, so an unmatched
     filter fails on its own. (`-DfailIfNoTests=true` is a different setting
     — "no tests at all", default `false` — and is not what protects you
     here. Do not reach for it in a `-am` reactor run, where it fights
     `-Dsurefire.failIfNoSpecifiedTests=false`.)
3. **Last resort, only once 1 and 2 are genuinely exhausted:** run the full
   project build once. Look for that specific test's pass/fail line in the
   console output — most build tools print one even in a full run — and use
   that as evidence. Only fall back to "the build exited 0, so this test
   passed" if no per-test line is visible either. This is a deviation from
   rule 7 (build scope) and must be logged explicitly in that cycle's
   summary — e.g. "scoped evidence unavailable: report files gitignored,
   console showed no per-test filter match after `--rerun-tasks`; falling
   back to full-build exit code" — never silently. Treat this as routing
   around a broken environment, not a standing option to reach for whenever
   scoped testing feels inconvenient.

