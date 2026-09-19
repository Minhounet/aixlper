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

## Skill vs. agent: is this even a candidate?

Before writing a new `SKILL.md`, check whether the thing being asked for
actually fits the Skill shape. A Skill is packaged, on-demand
*instructions* — declarative, portable, loaded into the calling session so
the main Claude follows them itself with its own context and tools. If
what's being described instead needs its own isolated context, its own
tool allowlist or model, or genuinely separate/parallel execution
(delegated work, not followed instructions) — that's a Claude Code
**subagent** (`.claude/agents/*.md`), a different mechanism entirely.
Subagents aren't portable to Gemini CLI, so they're structurally out of
scope for this repo even when they'd be the better tool for the job.

Most requests are the "recipe" case: the whole thing is a Skill, and the
decision is per-*step*, not per-skill — does any individual step need to
be delegated rather than followed inline? A step needs an actual subagent
when it hits one of these, not on vibes ("this feels agentic"):
1. It needs a tool allowlist narrower or different from the calling
   session's (e.g. a reviewer that must never get `Edit`/`Write`).
2. It needs a different model (cheaper/faster for one narrow job).
3. It needs to run in parallel or in the background without its
   intermediate noise polluting the caller's context.
4. It needs to be addressable on its own — resumed later, messaged,
   named independently of whoever invoked it first.

None of these apply → the step stays inline, followed by whichever Claude
is running the skill. One or more apply → the skill's own instructions can
still tell it to spawn a subagent for just that step (see `mr`'s
background-draft step) without the skill itself stopping to be a portable
`SKILL.md` — spawning the subagent is one instruction inside the recipe,
not what the recipe *is*.

When a request is ambiguous, say which shape it looks like and why before
starting, rather than force-fitting it into a `SKILL.md`.

## Active work: igiari-tdd and chottomatte-archi

These two skills are being designed iteratively, directly with the repo's
author, across many sessions — they are **not** finished/stable in the way
the rest of this file is. Each `SKILL.md` is the source of truth for the
exact current rules; this section is a condensed settled-state summary so
a fresh session doesn't lose the thread. The full session-by-session
history — every rule addition, correction, and worked example, with the
reasoning behind each — lives in `docs/design-log.md`; read it when you
need the *why* behind a rule, not just the rule itself. Keep this section
and the log in sync whenever either skill changes.

They're deliberately kept as two separate skills: TDD governs *how you
write code over time* (the workflow), Clean Architecture governs *how the
code is structured* (the dependency rule) — orthogonal, composable, and
you shouldn't have to pull in architecture rules just to fix a bug in an
unstructured script. Both carry a one-line "Related skill" cross-reference
to each other and to `gyakuten-ddd` (DDD strategic patterns).

**`skills/igiari-tdd/`** — one-test-per-step TDD, framed for an AI
specifically: baby steps exist for *containment* (capping the blast
radius of a confidently-wrong diff), not *design-discovery*. The cycle is
Red / **Super Green** / **Refining Refactor** (not classic dirty-green) —
an AI should write minimal *and* clean on the first pass. Non-negotiable
rules: one test per step, real red before any production code,
minimal-only implementation with a "triangulate before generalizing"
clause (never introduce a loop/recursion/abstraction on one test's
strength — wait for a second test that a hardcoded implementation
genuinely can't satisfy), a mandatory checklist-bounded refactor pass
every cycle plus an "advanced refinement" tier gated by concrete trigger
thresholds (3rd same-type conditional → polymorphism, duplicated
validation across 2+ call sites → value object, 3rd reason-to-change on a
class → split it, 3+ branches on the same discriminant → Strategy), with
a "log, don't ask" rule for anything below threshold (rolled into a
"Deferred refinement notes" list at end of task), test-scoped builds
during the loop with one full build at the end,
`should<ExpectedResult>_when<Condition>` naming, never sourcing a test's
expected value from the implementation, and a "plan the tests before the
first cycle" approval gate (name + one-line intent per test, one
approval, then cycles run straight through — the plan is visibility, not
license to build ahead of the current test). The mechanical syntax
checklist (stream `.toList()`, lambda cleanup, method references, `var`,
diamond operator, pattern-matching `instanceof`) now lives in
`kaizen-refactor`'s "Tier 1" section as the single source of truth.
Author preferences: in-memory repositories over real adapters,
Mockito for collaborators not owned by the codebase (repositories are the
one exception) with `@ExtendWith(MockitoExtension.class)`, Vavr in
implementation code, `null` disallowed (`Option` is the default), build
the SUT in `@BeforeEach` unconditionally — never a field initializer
(captures `null` for `@Mock` fields), never inline per test method.

**`skills/chottomatte-archi/`** — dependency inversion via interfaces is
the one rule everything else follows from. Constructor injection always
(setter injection only as a narrow legacy-framework-wiring exception);
the use case is the entry point, taking repository/service/logger
interfaces via the constructor; on legacy code, dependency inversion
still applies at whatever seam *is* owned. Spring: no framework
annotations in core classes, wiring via `@Configuration`/`@Bean` at the
composition root. The actual line for "needs wrapping behind an
interface" is determinism, not "static" — a pure static call (`Math.max`)
is fine directly, a non-deterministic one (`Instant.now()`,
`UUID.randomUUID()`) always needs an owned interface (`Clock`,
`IdGenerator`). Repositories return the domain object itself, never a
primitive/partial projection; the use case builds its own `Response` via
an explicit mapper (CQRS-flavored naming: `Command`/`Query`/`Request`),
one mapper per domain type reused both directions. An **orchestrator use
case** routes a single infrastructure entry point to distinct
typed-`Command` use cases when it discriminates multiple business
operations (split when a variant develops its own validation/error
handling; stay merged when variants only differ in which fields are
sent). Heavy ECM/legacy SDKs (Nuxeo, Documentum): narrowly-scoped ports,
not relaxed dependency rules; framework-forced static lookups
(`Framework.getService(...)`) and `CoreSession` resolution happen inside
`handleEvent`, never an `EventListener` constructor (services/session
aren't available yet at construction time); a "Syncing Nuxeo to an
external system" pattern needs two separate ports (`DocumentRepository`
for reads, a distinctly-named `SyncGateway` for pushes), not one
repository stretched both ways. Deterministic computation embedded in a
framework action (e.g. assembling a business ID from date + random
fragment) gets pulled out into a plain, directly-unit-tested policy
class — only genuine reads/writes stay behind the port. Gateway stand-ins
(`LoggingX`/`NoOpX` implementations) are ordinary placeholder
implementations of the same interface, swapped for the real adapter
later. Config values threaded through a call chain become a named
Parameter Object behind an interface (never a loose primitive/
collection) — a constructor dependency like any other, same
interface-not-concrete-class rule; if the class can stop being
static-only, inject the config object via constructor instead of
threading it as a parameter. A structural change (new interface,
constructor signature change, `@Bean` rewiring) needs a full build, not
just the scoped test, and fixing every test call site it breaks is
mandatory even with no behavior change. "Plan the structure before
implementing" gate: classes/interfaces/ports, constructor dependencies,
composition-root wiring, and public method signatures, one approval
before implementation starts.

Both skills' plans allow exactly one further pause each: a genuine
deviation from the approved plan discovered during implementation, shown
and re-approved before resuming — never silent substitution. When both
skills are loaded, the clean-architecture structural plan comes first and
the TDD test plan is written against it rather than re-derived.

**Testing method: dogfood via kata.** Beyond `make validate`/`make eval`,
these two skills are pressure-tested by actually using them: pick a small
kata, set it up in a throwaway scratch directory (not committed), and
solve it while following the target skill's rules literally, showing real
command output at every red/green checkpoint. Choose the kata to fit
whichever skill is under test: numeric/parsing katas for `igiari-tdd`,
something with real collaborators (repository, service, logger) for
`chottomatte-archi`. Treat any friction as a direct signal to fix the
`SKILL.md`, not just the kata code. Three dogfooding runs so far (roman
numeral, String Calculator, a Gradle project) each surfaced a real gap
now documented in the skill, including a "Getting evidence when the build
tool fights you" escalation ladder in `igiari-tdd` for when
`build`/`target` output is gitignored and unreadable — see
`docs/design-log.md` for what each run found and how it was fixed.

Expect both files to keep growing with more rules, examples, and
preferences from ongoing conversation — don't treat either as complete,
and don't remove or "clean up" sections without the author asking.

## Active work: mujitsu-documentum

`skills/mujitsu-documentum/` is unverified — written from
general Documentum DQL/API knowledge, not yet run against a real docbase.
Treat every pattern in it as a draft until the author reports back from
real usage; don't cite it as settled the way the two Java skills above are.

The gap it targets: individually, DQL and the API (`iapi`/`idql`) are
well-documented and widely known; composing the two into a bash script
that's safe to re-run — existence-check before `create`, surviving a
partial failure, converging to the same end state across dev/test/prod —
is the part that isn't.

**Testing method: real docbase, not kata.** Unlike the Java skills' kata
dogfooding, there's no throwaway-project equivalent for a Documentum
skill — it needs a live docbase to mean anything. The author validates it
by using it against a real Documentum environment and reporting friction
back. Known-weak spot going in: pattern 4's `get_type_attr_count` is a
named placeholder, not confirmed real DQL. Any correction from real usage
should land as an edit to `skills/mujitsu-documentum/SKILL.md` plus a log
entry, the same discipline as the Java skills.

Ten patterns total as of now (including trusted-login password hygiene,
and set-based vs. ID-batch bulk update/delete loops) — see
`docs/design-log.md` for how patterns 8-10 were added.

## Active work: gyakuten-ddd

`skills/gyakuten-ddd/` is new and not yet dogfooded; treat it the same as
`mujitsu-documentum`'s unverified status until it's been exercised on a
real multi-context design.

**Scope:** covers DDD's *strategic* patterns only (Bounded Context,
Context Map, Shared Kernel, Anticorruption Layer, etc. — the boundaries
*between* models). Tactical patterns (Entity, Value Object, Aggregate,
Repository) stay in `chottomatte-archi`'s "Relationship to DDD" section,
since they're inseparable from that skill's Java-specific
dependency-direction rules; strategic design is language-agnostic and got
its own skill for that reason — see `docs/design-log.md` for the full
reasoning.

**Trigger design:** also works as a learning aid (explaining a term on
request, e.g. "what's a bounded context"), not just enforcement during
real design work. Cross-referenced from `chottomatte-archi`. No testing
method decided yet beyond `make validate`.

## Active work: kaizen-refactor

`skills/kaizen-refactor/` is new and not yet dogfooded. It covers
refactoring code that already *exists* — surfaced by an IDE inspection,
not a failing test — which doesn't fit `igiari-tdd`'s refactor step
(fires only on code just written this cycle) or `kanpeki-fp` (not every
refactor is FP-flavored).

**Two-tier split:** Tier 1 (IDE-verified mechanical refactorings —
rename, extract, inline, move, plus the fixed syntax-level checklist
moved here from `igiari-tdd` as the single source of truth) applies
directly, no gate. Tier 2 (judgment-call refactors — polymorphism, value
object, split class, Strategy, or any `kanpeki-fp`-governed style move)
stays gated by the same trigger-threshold discipline as `igiari-tdd`'s
advanced refinement, plus a test-coverage safety net (green baseline, one
change at a time, re-verify green after each).

Headless inspection: `qodana scan` (preferred) or `idea inspect`/
`inspect.sh` — see the skill for the command-line workflow. A "Recognizing
new Tier 1 candidates" section governs how the fixed mechanical list
grows (three checks: fixed input → fixed output, JDK/library-guaranteed
equivalence, recurs across classes — a candidate may state a documented
precondition at the call site, never an unstated one; the `getFirst()`/
`getLast()` entry is the worked example). Full history:
`docs/design-log.md`.

## Repository layout

```
skills/<skill-name>/SKILL.md      # one skill per directory
skills/<skill-name>/references/   # optional supporting files
skills/<skill-name>/scripts/      # optional scripts the skill runs
skills/<skill-name>/evals/        # claude plugin eval cases for the skill

global/                           # author's global ~/.claude config
global/litellm-budget.py          # statusline + SessionStart-hook budget script
global/settings.template.json     # public-safe; secrets injected at install

docs/design-log.md                # session-by-session history for active-work skills
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

## Global config

`global/` holds the author's own `~/.claude` config — the global `CLAUDE.md`
and the `java.md` / `nuxeo.md` it `@`-imports, `litellm-budget.py` (the script
`settings.template.json` wires into `statusLine` and the `SessionStart` hook
for the gateway budget display), and `settings.template.json` itself.
`scripts/install-global.sh` installs them onto any machine, chmod'ing
`litellm-budget.py` back to executable since content-only comparison would
otherwise leave a restored or hand-copied file non-executable.

`settings.template.json` also pins `model`. A re-install overwrites whatever
model is currently configured (including a runtime downgrade some other
mechanism persisted to `settings.json`) back to that pinned value — expected,
since the template is the single source of truth for this key, but worth
knowing before running the installer mid-session.

Rules for anything added here:
- **This repo is public.** No credential, no internal hostname, no real ticket
  ID or internal package name. The committed copies are genericized versions of
  the author's real files (`PROJ-1234`, `com.example.*`) — keep it that way.
- Secrets live only in `~/.claude/aixlper.env` (gitignored, `chmod 600`) and
  reach `settings.json` through the `@@ENV_BLOCK@@` marker at install time.
  Never add a real value to `settings.template.json`.
- The installer stays separate from `scripts/install.sh` and must never write
  to `~/.claude/skills/` — development machines symlink those into this repo.
- `jq` and `envsubst` are not assumed present; the script is pure bash + `sed`.

## Skill editing

`~/.claude/skills/<skill-name>/SKILL.md` is a symlink to `skills/<skill-name>/SKILL.md` in this repo. Edit the repo copy — the local install updates automatically. No manual copy needed.

## Git workflow

Commit message format: `<gitmoji><semantic>|<message>`

- `semantic` is one of: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`
- Pick the gitmoji from [gitmoji.dev](https://gitmoji.dev) to match the change

Examples:
- `✨feat|add ikuzo-nav skill`
- `🐛fix|correct frontmatter validation`
- `♻️refactor|reorganize skill directory structure`
- `📝docs|update igiari-tdd worked example`

### Auto-commit policy

After completing any change, commit automatically — never ask for permission first.
Tell the user the commit message used so they can request a change if not satisfied.
Never push automatically; push only when the user explicitly asks.
