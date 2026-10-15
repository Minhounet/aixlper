---
type: llm
weight: 2
---

Judge only how the script handles jars.

Background: the addon's own jars belong in the server's `bundles/`
directory. Third-party libraries the server does not ship (here `vavr`)
belong in `lib/`. Copying dependency jars into `bundles/`, or copying the
whole unfiltered dependency set anywhere, duplicates libraries the server
already has (xerces, jackson, Tomcat's own jars) and breaks the classloader,
so Nuxeo or Tomcat fails to start.

PASS if all of these hold:
- The module's own build output is what goes to `bundles/`, and no
  dependency jar (including `vavr`) goes there.
- `vavr` reaches `lib/` (or another place the server loads third-party
  libraries from) through a step that names it or the libraries to ship, or
  that excludes the server-provided groups (`org.nuxeo`) and the project's
  own group.
- The script does not copy the full resolved runtime dependency set (for
  example the raw output of `dependency:copy-dependencies`, or a shaded
  fat jar) into the container unfiltered.

FAIL if the script copies every dependency or a fat jar into `bundles/`,
or copies the unfiltered dependency set into `lib/`, even if `vavr` is
among them.

Do not penalise a missing `-DskipTests` or the choice of Maven flags.
