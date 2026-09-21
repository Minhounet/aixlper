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
still tell it to spawn a subagent for just that step — e.g. "draft this in
the background when nobody's watching, then continue inline once it
reports back" — without the skill itself stopping to be a portable
`SKILL.md`. Spawning the subagent is one instruction inside the recipe,
not what the recipe *is*.

When a request is ambiguous, say which shape it looks like and why before
starting, rather than force-fitting it into a `SKILL.md`.

## Active work: skills still being designed

Five skills are in active design and are **not** stable. For each, the
`SKILL.md` is the source of truth for its current rules, and
`docs/design-log.md` holds the session-by-session history — every rule
addition, correction and worked example, with the reasoning behind it.
Read the `SKILL.md` when you need the rule; read the log when you need the
*why*. Don't restate either here: this section is a map, not a summary.
Keep the log updated whenever a skill changes.

For all five: expect them to keep growing from ongoing conversation with
the author. Don't treat any as complete, and **don't remove or "clean up"
sections without the author asking.**

| Skill | State | Notes |
|---|---|---|
| `igiari-tdd` | Co-designed across many sessions | One-test-per-step TDD framed for an AI: baby steps for *containment*, not design-discovery. Red / Super Green / Refining Refactor. |
| `chottomatte-archi` | Co-designed across many sessions | Dependency inversion via interfaces; everything else follows from it. |
| `mujitsu-documentum` | **Unverified** | Written from general DQL/API knowledge, never run against a real docbase. Treat every pattern as a draft; don't cite it as settled. Known-weak spot: pattern 4's `get_type_attr_count` is a named placeholder, not confirmed DQL. |
| `gyakuten-ddd` | New, not dogfooded | DDD *strategic* patterns only (Bounded Context, Context Map, ACL...). Tactical patterns stay in `chottomatte-archi`. Doubles as a learning aid — explaining a term on request is a valid trigger. |
| `kaizen-refactor` | New, not dogfooded | Refactoring code that already *exists*, surfaced by an IDE inspection. Two tiers: mechanical (no gate) vs. judgment-call (trigger-gated + test safety net). Owns the syntax-level checklist as single source of truth, moved here from `igiari-tdd`. |

`igiari-tdd` and `chottomatte-archi` are deliberately **two** skills: TDD
governs *how you write code over time*, Clean Architecture governs *how the
code is structured* — orthogonal and composable, and you shouldn't need
architecture rules to fix a bug in an unstructured script. Both
cross-reference each other and `gyakuten-ddd`. When both are loaded, the
clean-architecture structural plan comes first and the TDD test plan is
written against it rather than re-derived. Each allows exactly one further
pause after its plan is approved: a genuine deviation discovered during
implementation, shown and re-approved — never silent substitution.

### Testing method

- **The two Java skills: dogfood via kata.** Beyond `make validate` /
  `make eval`, pressure-test them by actually using them — pick a small
  kata, set it up in a throwaway scratch directory (not committed), and
  solve it following the skill's rules literally, showing real command
  output at every red/green checkpoint. Numeric/parsing katas for
  `igiari-tdd`; something with real collaborators for `chottomatte-archi`.
  Treat any friction as a signal to fix the `SKILL.md`, not just the kata
  code. Three runs so far, each surfacing a real gap now documented — see
  `docs/design-log.md`.
- **`mujitsu-documentum`: real docbase, not kata.** There's no
  throwaway-project equivalent; the author validates it against a real
  Documentum environment and reports friction back. Corrections land as an
  edit to the `SKILL.md` plus a log entry, same discipline as above.
- **`gyakuten-ddd` / `kaizen-refactor`:** nothing decided yet beyond
  `make validate`.

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

### Keeping SKILL.md small: progressive disclosure

A `SKILL.md` is loaded **in full** the moment the skill triggers, and stays
resident for the rest of the session. `references/` files are not — they're
read only if and when the body points at one. That difference is the whole
token budget, so it decides what goes where.

Keep in `SKILL.md` the rules that apply *whatever* the framework, plus a
short pointer table saying which reference to read and when. Move out
anything conditional or lookup-shaped:

- framework- or vendor-specific material (Spring wiring, Nuxeo packaging,
  a particular SDK's seams) — it's dead weight on every session that
  doesn't use that framework;
- exact command invocations and their troubleshooting ladders;
- meta-sections about extending the skill itself, which aren't needed while
  *applying* it.

Rules of thumb: never split a rule from its own statement — a reference
shows how to satisfy a rule in one environment, it never holds the rule;
write each reference to stand alone, with a title and a one-line "read this
when..."; and make the pointer specific enough to decide from without
opening the file. A `SKILL.md` past ~20KB almost certainly has a reference
hiding in it.

The inverse matters just as much: a reference opened on almost every
trigger costs *more* than inline — the tokens arrive via the tool result
anyway, plus an extra turn to decide to read it and a lost prefix cache.
And a step that runs a command owes the same discipline to its **output**,
which is charged per run and kept for the session: suppress progress and
debug noise, and bound what gets echoed. Every `SKILL.md` carries a "Token
self-audit" section stating these; `docs/design-log.md` has the full
reasoning, including the two cases where this repo got it wrong first.

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
