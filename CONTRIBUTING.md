# Contributing

## Testing

- `make validate`: checks every `SKILL.md` frontmatter (portable subset only)
  and that `agents/` matches its generator. Free; runs in CI.
- `make eval`: behavioural evals with `claude plugin eval` for skills that have an
  `evals/` directory. Costs API usage, so run it by hand.
- `make ci`: both, in order.

## Layout

```
skills/<name>/SKILL.md      # one skill per directory, shared by both clients
skills/<name>/references/   # optional supporting files
skills/<name>/scripts/      # optional scripts the skill runs
skills/<name>/evals/        # Claude plugin eval cases

global/agents/              # Claude Code agents (source of truth for helper agents)
agents/                     # Gemini CLI agents, GENERATED from global/agents/ (make gemini-agents)
scripts/                    # installers (install.sh, install-gemini.sh), validator, gemini_agents.py generator
scripts/gemini-exclude.txt  # Claude-only skills the Gemini installer skips
docs/                       # design log, saiban-orchestrator tutorials (EN, FR)
```

## Gemini CLI agents

The helper agents (`kenji-reviewer`, `shonin-dev`, `mokugeki-tester`,
`tantei-inspector`) exist
for both clients. Edit only `global/agents/<name>.md`, then run
`make gemini-agents` and commit the regenerated `agents/*.md` with it.
`make validate` fails if they are out of date. `saiban-orchestrator` is
Claude Code only and is not ported, so in Gemini CLI the main session
delegates to the helpers directly; their Gemini descriptions (in
`scripts/gemini_agents.py`) say when and with what.

## Maintainer install

```bash
./scripts/install.sh --link     # symlink skills and agents into ~/.claude, so repo edits are live
AIXLPER_REF=some-branch ./scripts/install.sh   # install from a branch or tag
```

## Author's global config (personal machines)

This is the repo author's own machine
setup — global `CLAUDE.md` (plus the `java.md` / `nuxeo.md` it imports), the
`litellm-budget.py` script that backs the statusline/session-start budget
display, `court-session.sh` (a `SessionStart` hook listing the project's open
`saiban-orchestrator` cases; `AIXLPER_NO_COURT=1` silences it), and a generated
`settings.json` wiring them in:

```bash
./scripts/install-global.sh            # from a clone
curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install-global.sh | bash
```

It is deliberately **separate** from `install.sh` — a skills installer should
never rewrite a stranger's `CLAUDE.md` or `settings.json`. It also never touches
`~/.claude/skills/`, so a development machine where those are symlinks back into
a clone keeps working.

**No secret is stored in this repo.** `global/settings.template.json` carries a
`@@ENV_BLOCK@@` marker; the API gateway, token and proxy are read at install
time from `~/.claude/aixlper.env` (gitignored) or the shell environment:

```bash
cp global/aixlper.env.example ~/.claude/aixlper.env
chmod 600 ~/.claude/aixlper.env   # then fill it in
./scripts/install-global.sh
```

Leave every value empty and the env block collapses to telemetry alone, which
is what a personal machine with no corporate gateway wants. Existing files are
backed up to `.bak.<epoch>` before being replaced, re-running changes nothing if
nothing differs, and `--dry-run` reports without writing.

`settings.template.json` also pins `model` to `opus[1m]`. Re-running the
installer restores that value, so a temporary model override made outside this
repo (by hand, or by the client itself) does not survive a re-install — edit
the template if you want a different default to stick.

