# Testing across the seam

> Reference for the `chottomatte-archi` skill. Read when writing tests that cross the interface boundary (in-memory repositories, fakes vs mocks at the port).

## Testing across the seam

Two tiers, not one:

- **Use case tests** stay pure unit tests — no framework runtime, an
  in-memory repository and Mockito per `igiari-tdd`'s existing
  preferences. This is where most tests live.
- **Adapter/listener integration tests** exist only to prove the seam's
  translation is correct (event → `Command`, SDK type ↔ domain object, the
  static lookup actually resolves) — not to re-test business rules already
  covered by the use case's unit tests. Nuxeo provides this via
  `nuxeo-runtime-test`'s `FeaturesRunner` + `@Features(CoreFeature.class)`:
  an embedded runtime where `Framework.getService(...)` resolves for real,
  scoped down with `@Deploy` to just the components under test.
- **Checklist for listener changes — every new path needs a FeaturesRunner case.**
  Any code path added to a listener's `handleEvent()` that involves a session
  query or a decision based on Nuxeo state requires a FeaturesRunner test case
  that exercises it. Before committing a listener change, enumerate every new
  `if`/`switch` branch added to `handleEvent()` — if any branch reaches a
  Nuxeo API, there must be a `@Test` method exercising it:
  - A session call whose result drives a branch (`session.getVersions()`, an
    NXQL query, `session.getWorkingCopy()`) → test each branch
  - A property read from a Nuxeo document that feeds downstream output
    (`gen:edfUuid`, `gen:indice`) → test the property-to-field translation
    end-to-end through the listener
  - A `Framework.getService(...)` lookup that affects behaviour → test that
    the resolved service is called with the right arguments

  What does **not** need a FeaturesRunner test:
  - The listener registration itself (OSGi wiring — proven by the fact the
    test fires at all)
  - A filter already covered by an existing test case (e.g. a
    non-HydroDocument guard already tested elsewhere)

  Missing a FeaturesRunner case for a new branch is a violation of this skill,
  even when the use case it delegates to is already unit-tested — the seam
  translation itself (the session query, the branch, the field mapping) is
  what the FeaturesRunner test proves.

- **Documentum: unresolved, flag rather than assume.** There's no known
  embedded-runtime equivalent for DFC. `IDfSysObject`/`IDfSession` are
  interfaces, so they're directly Mockito-mockable, but the fidelity of
  that mock against real Documentum behavior is an open concern, not a
  settled pattern — the same unverified status as
  `mujitsu-documentum`. Don't present a mocked-DFC adapter
  test as equivalent proof to a Nuxeo `FeaturesRunner` test; treat it as a
  weaker substitute until real usage says otherwise, and prefer validating
  the adapter against a real docbase where practical.

