# aixlper

## Goal

A repository of generic, reusable AI agent skills, written once and usable
in multiple AI coding assistants — primarily **Claude Code** and
**Gemini CLI**. Skills follow the open **Agent Skills** standard
(`SKILL.md` + YAML frontmatter, optional bundled scripts/references), which
both clients read natively.

Portability rules for every skill in this repo:
- Frontmatter is limited to the shared subset: `name`, `description`
  (and other fields only if confirmed supported by both clients).
- No Claude-only fields (e.g. `allowed-tools`) unless the skill is
  explicitly Claude-only, in which case say so in the skill's description.
- Instructions in the body stay tool-agnostic — describe *what* to do, not
  a specific client's tool names, unless a step genuinely differs per
  client (call that out explicitly).

## Active work: java-tdd-baby-steps and java-clean-architecture

These two skills are being designed iteratively, directly with the repo's
author, across many sessions — they are **not** finished/stable in the way
the rest of this file is. Each `SKILL.md` is the source of truth; this
section is a status snapshot so a fresh session doesn't lose the thread
and re-litigate settled decisions. Keep this section in sync whenever
either skill changes in a way that affects the summary below.

They're deliberately kept as two separate skills: TDD governs *how you
write code over time* (the workflow), Clean Architecture governs *how the
code is structured* (the dependency rule) — orthogonal, composable, and
you shouldn't have to pull in architecture rules just to fix a bug in an
unstructured script.

**`skills/java-tdd-baby-steps/`** — one-test-per-step TDD, framed for an
AI specifically: baby steps exist for *containment* (capping the blast
radius of a confidently-wrong diff), not *design-discovery* (the usual
human justification, which is weak for an AI that often already sees the
full solution). Settled, non-negotiable rules: one test per step, real
red before any production code, minimal-only implementation, a mandatory
(checklist-bounded, not "if warranted") refactor pass every cycle,
test-scoped builds during the loop with a full build only once at the
end, `should<ExpectedResult>_when<Condition>` naming, and never sourcing a
test's expected value from the implementation (e.g. a shared constant).
Converting tests to `@ParameterizedTest` during refactor is allowed without
asking first, but must never be silent — it's traced in the cycle's
refactor summary (tests merged, named before/after), the same requirement
that applies to any other refactor that changes test code itself rather
than production code. The refactor step also always
applies a fixed set of mechanical syntax refactorings (stream
`.toList()`, lambda brace/return cleanup, method references, `var`,
diamond operator, pattern-matching `instanceof`) — these are not
judgment calls, unlike the design-level checklist. Author's preferences
captured so far: in-memory repositories over real adapters when the task
allows it, Mockito for collaborators not owned by the codebase (services,
gateways, clients — repositories are the one exception, kept in-memory)
with `@ExtendWith(MockitoExtension.class)` (`lenient()` freely allowed),
Vavr in implementation code, avoid side effects. Build the
class under test in `@BeforeEach`, never as a field initializer — a
field initializer that reads a `@Mock` field captures `null`, since
`MockitoExtension` populates `@Mock` fields only after construction
(found live while dogfooding, see below); `@InjectMocks` is a narrower
alternative, only when every dependency is a genuine mock/spy.

**`skills/java-clean-architecture/`** — dependency inversion via
interfaces is the one rule everything else follows from. Constructor
injection always (setter injection is a narrow, seam-scoped exception for
legacy framework wiring that genuinely blocks the constructor path, not a
general option). From scratch, the use case is the entry point, taking
its repository/service/logger interfaces via the constructor; on legacy
code where the entry point isn't owned, dependency inversion still
applies at whatever seam *is* owned rather than being skipped wholesale.
Spring guidance: no framework annotations in core classes by
default, wiring via `@Configuration`/`@Bean` at the composition root
(with a "reality check" that an already-annotated legacy project gets the
same seam treatment, not a forced rewrite); the logger is bound to its
declaring class via a prototype-scoped `InjectionPoint` bean rather than
one shared logger. One open assumption not yet explicitly confirmed by
the author: the `Logger` interface is taken to mean SLF4J's
`Logger`/`LoggerFactory` (log4j2 as the binding), not a hand-rolled
interface.

Expect both files to keep growing with more rules, examples, and
preferences from ongoing conversation — don't treat either as complete,
and don't remove or "clean up" sections without the author asking.

**Testing method: dogfood via kata.** Beyond `make validate`/`make eval`,
these two skills are pressure-tested by actually using them: pick a small
kata, set it up in a throwaway scratch directory (not committed — a
one-off smoke test, not a project artifact), and solve it while following
the target skill's rules literally and verbatim, showing real command
output at every red/green checkpoint rather than asserting it worked.
Choose the kata to fit whichever skill is under test: something with many
small, naturally incremental cases (numeric conversions, parsers, small
calculators) exercises `java-tdd-baby-steps`; something shaped like a
real use case with real collaborators (a repository, a service, a
logger) exercises `java-clean-architecture`'s DIP/constructor-injection/
seam rules. Treat any friction — an ambiguous rule, a step that doesn't
produce the right behavior, a bug the rules should have caught but didn't
— as a direct signal to fix the SKILL.md, not just the kata code. First
run: the roman-numeral kata (int → roman numeral, wrapped in a use case
with an injected repository and logger) surfaced the `@Mock`
field-initializer trap now documented in `java-tdd-baby-steps`.

## Layout

```
skills/<skill-name>/SKILL.md      # one skill per directory
skills/<skill-name>/references/   # optional supporting files
skills/<skill-name>/scripts/      # optional scripts the skill runs
skills/<skill-name>/evals/        # claude plugin eval cases for the skill
```

## Build / CI

There's nothing to compile — skills are plain markdown+YAML read directly
by the client — but there is a validate/test pipeline, the equivalent of
`mvn verify` for this repo:

- `make validate` — runs `scripts/validate_skills.py`, which checks every
  `skills/<name>/SKILL.md` has well-formed frontmatter, exactly one
  `SKILL.md`, and frontmatter limited to the portable subset (flags
  Claude-only keys like `allowed-tools` unless the skill's description
  says it's Claude-only).
- `make eval` — runs `claude plugin eval` for every skill that has a
  `skills/<name>/evals/` directory (`case.yaml`/`prompt.md` + grader
  files), including a no-skill baseline comparison.
- `make ci` — both, in order. Wired into `.github/workflows/`.

## Testing

- **Claude Code**: skills can be exercised live in a Claude Code session,
  or scored with `make eval` (see above).
- **Gemini CLI**: no automated check here — since Gemini CLI isn't
  available to script against in this environment, we rely on the
  portability rules above (shared frontmatter subset, tool-agnostic
  instructions) instead of an automated cross-check. A skill that follows
  those rules and passes `make validate` is assumed to work in Gemini CLI
  too, since the content itself (e.g. "how to cook a chicken") doesn't
  depend on which client is reading it — only genuinely Claude-specific
  steps need a manual Gemini check.

## Distribution

Skills are packaged for install/update via each client's native mechanism,
both sourced from this same repo:
- **Claude Code**: a plugin marketplace (`.claude-plugin/marketplace.json`
  + `plugin.json`), added with `/plugin marketplace add <repo-url>` and
  updated via the marketplace/plugin update flow.
- **Gemini CLI**: a `gemini-extension.json` extension manifest, installed
  with `gemini extensions install <repo-url> --auto-update`.

Both manifests point at the shared `skills/` directory — there is one copy
of each skill, not a fork per client.
