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
