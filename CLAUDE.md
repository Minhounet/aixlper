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
evals/<skill-name>/               # claude plugin eval cases for the skill
```

## Testing

- **Claude Code**: skills can be exercised live in a Claude Code session,
  or scored with `claude plugin eval` against `evals/<skill-name>/`
  (`case.yaml`/`prompt.md` + grader files), including a no-skill baseline
  comparison.
- **Gemini CLI**: no automated eval harness here yet; verify manually with
  a local `gemini` CLI install pointed at `skills/`.

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
