# aixlper

A repository of generic, reusable AI agent **skills** — written once, usable
in multiple AI coding assistants (primarily [Claude Code](https://code.claude.com)
and [Gemini CLI](https://github.com/google-gemini/gemini-cli)).

Skills follow the open **[Agent Skills](https://code.claude.com/docs/en/skills.md)**
standard: a `SKILL.md` file with `name`/`description` YAML frontmatter, plus
optional bundled scripts/references. Both clients read this format natively,
so each skill is written once under `skills/<name>/` and works in either
tool — no per-client fork.

## Available skills

| Skill | What it does |
|---|---|
| [`igiari-tdd`](skills/igiari-tdd/SKILL.md) | One-test-at-a-time TDD for Java: never more than one failing test at a time, minimal implementation only, a mandatory refactor checkpoint every cycle. |
| [`chottomatte-archi`](skills/chottomatte-archi/SKILL.md) | Dependency inversion via interfaces and constructor injection for Java: the use case as entry point, depending only on repository/service interfaces. |
| [`gyakuten-ddd`](skills/gyakuten-ddd/SKILL.md) | Domain-Driven Design's strategic patterns: Bounded Context, Context Map, Ubiquitous Language, and Core Domain distillation — the boundary between models, teams, and systems. |
| [`kurae-bash`](skills/kurae-bash/SKILL.md) | Ten hardening patterns for robust, interactive bash CLI tools: keybinding dispatch, atomic writes, strict mode, framework-free testing, and more. |
| [`mujitsu-documentum`](skills/mujitsu-documentum/SKILL.md) | Idempotent bash scripts composing Documentum DQL + API calls: existence-check-before-create, output-based error detection, safe session lifecycle. |
| [`objection-conception`](skills/objection-conception/SKILL.md) | Persists a ticket's design conversation and the difficulties hit along the way to disk, so the thinking survives past the current session. |

## Installing

### Claude Code — one-line install (works today)

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install.sh | bash
```

This copies every skill into `~/.claude/skills/` — no manifest, no
marketplace, nothing to publish first. Re-run the same command any time to
update to the latest version. To install into a single project instead of
personally, or to pin a branch/tag:

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install.sh | AIXLPER_TARGET=.claude/skills bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install.sh | AIXLPER_REF=some-branch bash
```

Claude Code picks these up on the next session; each skill is invoked as
`/igiari-tdd` or `/chottomatte-archi`, or triggers
automatically based on its `description`.

### Gemini CLI — one-line install

```bash
gemini extensions install https://github.com/Minhounet/aixlper --auto-update
```

This requires `git` on your machine (Gemini CLI's own requirement for
installing from GitHub) but no manual clone step — Gemini CLI clones it
internally. `--auto-update` keeps it in sync with the repo.

> This repo's [`gemini-extension.json`](gemini-extension.json) manifest
> hasn't been verified against a live Gemini CLI install yet (see
> [`CLAUDE.md`](CLAUDE.md) — no automated Gemini check runs here). If this
> command doesn't work as expected, please open an issue.

### Marketplace distribution (optional, not set up)

Claude Code also supports a plugin-marketplace mechanism
(`.claude-plugin/marketplace.json` + `plugin.json`, installed with
`/plugin marketplace add minhounet/aixlper`). It isn't set up in this
repo — the curl install above already covers "install easily" without
that extra machinery, which mainly pays off if this ever needs versioned
releases or install/update/uninstall commands for a wider audience.

## Repo layout

```
skills/<skill-name>/SKILL.md      # one skill per directory
skills/<skill-name>/references/   # optional supporting files
skills/<skill-name>/scripts/      # optional scripts the skill runs
skills/<skill-name>/evals/        # claude plugin eval cases for the skill
```

## Contributing / testing

- `make validate` — checks every skill's `SKILL.md` frontmatter is
  well-formed and limited to the portable subset both clients support.
- `make eval` — runs `claude plugin eval` for any skill with an `evals/`
  directory (behavioral testing; costs API usage, run locally/manually).
- `make ci` — both, in that order. `make validate` alone is wired into
  CI (`.github/workflows/ci.yml`) and is free to run on every push/PR.

See [`CLAUDE.md`](CLAUDE.md) for the full design rationale and in-progress
notes on each skill.
