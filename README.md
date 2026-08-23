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
| [`java-tdd-baby-steps`](skills/java-tdd-baby-steps/SKILL.md) | One-test-at-a-time TDD for Java: never more than one failing test at a time, minimal implementation only, a mandatory refactor checkpoint every cycle. |
| [`java-clean-architecture`](skills/java-clean-architecture/SKILL.md) | Dependency inversion via interfaces and constructor injection for Java: the use case as entry point, depending only on repository/service interfaces. |

## Installing

### Claude Code — quick, local (works today)

Skills load automatically from a `skills/` folder Claude Code already
watches — no manifest, no marketplace, nothing to publish first:

```bash
git clone https://github.com/minhounet/aixlper.git
# personal, available in every project:
cp -r aixlper/skills/* ~/.claude/skills/
# — or, project-scoped, from inside a specific project:
cp -r aixlper/skills/* .claude/skills/
```

Claude Code picks these up on the next session; each skill is invoked as
`/java-tdd-baby-steps` or `/java-clean-architecture`, or triggers
automatically based on its `description`.

### Gemini CLI — quick, local (works today)

```bash
git clone https://github.com/minhounet/aixlper.git
gemini extensions link ./aixlper
```

`link` symlinks the extension in for local development — changes in this
repo are reflected immediately without reinstalling.

### Marketplace / extension distribution (not published yet)

The longer-term plan is to publish this repo as a proper **Claude Code
plugin marketplace** (`.claude-plugin/marketplace.json` + `plugin.json`,
installed with `/plugin marketplace add minhounet/aixlper`) and a
**Gemini CLI extension** (`gemini-extension.json`, installed with
`gemini extensions install https://github.com/minhounet/aixlper --auto-update`).

Those manifest files don't exist in the repo yet, so those commands aren't
usable yet — use the local install steps above in the meantime.

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
