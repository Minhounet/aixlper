# PIT (PITest): setup, scoped runs, reading the report

Read this when running a mutation check on a Java project built with Maven
or Gradle. The Maven path was run once (2026-11-02: `pitest-maven` 1.17.4,
`pitest-junit5-plugin` 1.2.1, JUnit 5.11, JDK 21); the Gradle path is
written from general knowledge, not run. Check each flag against the plugin
version the project uses.

## Is it already set up?

Look for `pitest-maven` in `pom.xml`, or the `info.solidsoft.pitest` plugin
in the Gradle build. If it's there, use its configuration and only narrow
the scope on the command line. If it isn't, ask before adding it.

JUnit 5 needs the `pitest-junit5-plugin` as a dependency of the PIT plugin;
without it PIT finds no tests and reports every mutant as not covered.

Minimal Maven setup (versions: take the latest the project's JDK supports):

```xml
<plugin>
  <groupId>org.pitest</groupId>
  <artifactId>pitest-maven</artifactId>
  <version>${pitest.version}</version>
  <dependencies>
    <dependency>
      <groupId>org.pitest</groupId>
      <artifactId>pitest-junit5-plugin</artifactId>
      <version>${pitest-junit5.version}</version>
    </dependency>
  </dependencies>
</plugin>
```

## Scope: the classes the task touched

Get the production classes from the diff, not by guessing:

```
git diff --name-only <base>..HEAD | grep 'src/main/java/.*\.java$' \
  | sed 's#.*src/main/java/##; s#\.java$##; s#/#.#g' | paste -sd, -
```

Pass that list as `targetClasses`. Leave `targetTests` to PIT unless the
run is too slow; then narrow it to the tests of those classes.

## Maven

PIT works on compiled classes, so compile in the same command. `-q` does
not silence PIT itself (about 45 lines per run, even on one class), so send
the console to a file and print only the summary:

```
mvn -q test-compile org.pitest:pitest-maven:mutationCoverage \
  -DtargetClasses=<list> -DoutputFormats=CSV -DtimestampedReports=false \
  > pit.log 2>&1; grep -E 'Line Coverage|Generated' pit.log | tail -2
```

A failing test stops it: `Tests failing without mutation ... requires a
green suite` in the log means the suite is red, not that PIT is broken.
One run on a single small class took about 20 seconds, most of it Maven
starting.

The default mutator set is enough to start. `-Dmutators=STRONGER` adds
mutants (2 → 3 on one small class, 4 → 6 on another) but found no other
survivor in the one run where both were compared.

Add `-Dthreads=<cores>` for speed. `-DwithHistory` reuses the previous
run's results for unchanged code, useful when re-running after killing a
survivor.

## Gradle

With the `info.solidsoft.pitest` plugin, set `targetClasses`,
`outputFormats = ['CSV']`, `timestampedReports = false` and
`junit5PluginVersion` in the `pitest { }` block, then run `./gradlew -q
pitest`. To narrow the scope per run, read `targetClasses` from a project
property in that block (`-P...`), rather than editing the build each time.

## Reading the report

The CSV report is `target/pit-reports/mutations.csv` (Maven) or
`build/reports/pitest/mutations.csv` (Gradle). One mutant per line:
source file, class, mutator, method, line, status, killing test.

Print only what needs a verdict:

```
grep -E ',(SURVIVED|NO_COVERAGE),' <report>/mutations.csv
```

The `Line Coverage` line from the summary is the other half: below 100% of
the scope, open `index.html` in the same folder to see which lines no test
runs (a line with no mutation point never appears in the CSV).

Statuses: `KILLED` (good), `SURVIVED` and `NO_COVERAGE` (need a verdict),
`TIMED_OUT`, `MEMORY_ERROR`, `RUN_ERROR` (the environment, not a verdict:
rerun or report). The mutator name says what was changed
(`ConditionalsBoundaryMutator`: `<` became `<=`, `NegateConditionalsMutator`:
`==` became `!=`, `NullReturnValsMutator`: the return became `null`, and so
on). Open the HTML report only when a line is unclear: it shows each mutant
in the source.
