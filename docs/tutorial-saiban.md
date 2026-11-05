# Tutorial: the `saiban-orchestrator` agent

*Version française : [tutorial-saiban.fr.md](tutorial-saiban.fr.md).*

`saiban-orchestrator` is a **Claude Code agent** (not portable to Gemini CLI) that runs
the [aixlper skills](../README.md#skills) for you, in the right order, and stops only when a decision
is really yours. It keeps a written trail of every decision, so you can follow
the work from anywhere, your phone included.

The names follow the skills: an Ace Attorney word, then the role. The words
come from a trial: *saiban* (the trial) runs the case, *kenji* (the
prosecutor) reviews each AC and never fixes, *shonin* (the witness) writes the
code without hearing the test plan, and *tantei* (the detective) investigates
how the skills were used. They were `iterate`, `iterate-reviewer` and
`iterate-dev` before; the installers clean up the old names.

| Name | Goal | Why it is a separate agent | Started by | Can edit |
|---|---|---|---|---|
| `saiban-orchestrator` | Orchestrator: picks the mode and the skills, runs the loop, asks you at the gates | It replaces you for a known process, so it must run as the main session to ask you questions | You (`ci`, or `/saiban-orchestrator`) | Yes |
| `kenji-reviewer` | Reviewer: checks each AC's work against the skills, reports, never fixes | Fresh eyes and no write access: it can't fix what it reviews | `saiban-orchestrator`, after each AC | No |
| `shonin-dev` | Implementer: writes one GREEN without seeing the test plan or the ACs | It must not know what tests come next, so its code can't be biased toward them | `saiban-orchestrator`, the GREENs of a large TDD run, one dev per run (fix, build) | Yes |
| `tantei-inspector` | Inspector: reads how the skills were used, proposes changes to them | Read-only, and must not know the working session's reasons; its long reading stays out of the main session | `saiban-orchestrator`, improve mode | No |

The three helpers run on Sonnet whatever model the main session uses
(`model: sonnet` in their frontmatter): their work is following written
rules, where Sonnet measured level with Opus. The orchestrator uses your
session's model; pick Opus with `/model` when the planning needs it.

### 1. Install

```bash
./scripts/install-global.sh   # copies global/agents/*.md to ~/.claude/agents/
./scripts/install.sh          # the skills themselves
```

`install-global.sh` also adds the `ci` alias to `~/.bashrc`, in a block
marked `# >>> aixlper >>>`. Re-running replaces that block, never duplicates
it, and touches nothing else (`--no-shell` to skip it). Open a new terminal
afterwards.

To install only the agents: `cp global/agents/*.md ~/.claude/agents/` (then
add the alias by hand). Nothing changes in your projects until you ask for
the agent.

### 2. Start it

From your project folder:

| You want | You type |
|---|---|
| Agent mode (`saiban-orchestrator`) | `ci` |
| The normal assistant | `claude` |

`ci` is `claude --agent saiban-orchestrator --permission-mode acceptEdits`: it edits
files without asking each time; commands and pushes still ask. It also adds
`--append-system-prompt-file ~/.claude/skills/saiban-orchestrator/SKILL.md`
when that file exists, so the skill is in context from the start: the
agent's `skills:` preload is ignored when the agent is the main session
(checked).

It only applies to that session: plain `claude` stays the normal assistant,
though its direct mode covers questions and quick edits too. Tip: `alias ci='claude --agent
saiban-orchestrator --permission-mode acceptEdits'` lets it edit files without asking
each time (commands and pushes still ask). The mode has to be on the command
line: `permissionMode` in the agent file is ignored when the agent is the
main session (checked). Avoid `"agent": "saiban-orchestrator"` in a settings file unless you want
every session there to start as `saiban-orchestrator`, since it replaces the default
system prompt.

Then describe the work in your first message. Two examples:

- **Fix mode** (a clear change to existing code):
  *"Bug: an account created as `alice` cannot log in as `Alice`. Usernames
  must be case-insensitive."*
  It uses `igiari-tdd` + `kanpeki-fp` (+ `kaizen-refactor`), nothing else.
- **Build mode** (something new):
  *"Ticket PROJ-8: lock an account after three failed logins. AC1: ...
  AC2: ..."* It uses `chottomatte-archi` first, then `objection-conception`
  for the ticket and its acceptance criteria (ACs), then TDD.
- **UI mode** (a web front end, for example Nuxeo): each AC gets a
  Playwright check (`shoko-playwright`), run against the app redeployed
  with Podman. Already passing: the AC is met. Failing: it changes the code
  until it passes, or, for a change only you can make (Nuxeo Studio
  Modeler), tells you what to change and waits for your hot reload. One
  screen at a time, with a pause between screens. No unit-test TDD here.
  Two tabs can work two different screens at once, in the same folder (not
  a worktree: the server only sees the folder its volume syncs). Each tab
  touches and commits only its own screen's files, and asks you before
  restarting the server, since that breaks the other tab's checks.
- **Think mode** (thinking and analysis only): `objection-conception`
  alone; `chottomatte-archi` only if you ask for it (or agree when it
  proposes it). It reads the code it needs, writes only the design files,
  never code.
- **Improve mode** (the skills and agents themselves): *"improve the skills
  from my last runs"*. `tantei-inspector`, read-only and fresh, reads your
  decision logs, retros, process notes and session transcripts, and proposes
  exact wording changes with the evidence. You accept or reject each one;
  accepted ones are applied and committed in your aixlper clone, never in the
  project. Needs the skills installed with `./scripts/install.sh --link`,
  otherwise it only prints the patch.
- **Direct mode** (anything else): a question, a small edit, a command. It
  just does it, with no ceremony, so you never need plain `claude`.

It proposes the mode; you confirm. Options you can add to that first
message:

| Say | Effect |
|---|---|
| `pre-approve TDD plans` | No approval per AC plan. |
| `no pauses` | No stop after each AC. |
| `no review` | No `kenji-reviewer` after each AC (build mode). |
| `with review` | In fix mode, a `kenji-reviewer` pass on the fix (off by default; about $0.30). |
| `with dev` / `no dev` | Force `shonin-dev` on or off. Without either, the orchestrator decides per TDD run: on for a build ticket with two or more ACs or a plan of four or more tests, off otherwise, and says so in the plan you approve. With it, the code is written by one agent per run that only sees the failing tests, not the plan; it costs about 2.7× on katas, benefit not yet measured. |

### Agent or plain session?

- **You know the process** (a ticket, a fix, a UI change, a design): start
  straight with the agent, `ci`. It is autonomous from the first message.
- **You don't yet** (exploring, a one-off): plain `claude`.
- **You can't switch a session** between the two: the prompt is fixed when
  the conversation starts and stays on resume (checked). Move between them
  through files instead: a new `ci` session and *"resume PROJ-8"* picks up
  from the decision log's `Resume` block.
- **Already in a plain session** and the process turns out known? Type
  `/saiban-orchestrator`: the same process loads as a skill, with the default assistant
  around it. The agent and the skill share one text, so nothing drifts.

### 3. What happens

1. **One approval up front** (build mode): the structural plan, the AC check
   and any contradiction in the ticket, quoted on both sides.
2. **One TDD run per AC**, true TDD rather than test-first: one test at a
   time, seen failing, then the least code that passes it, then a refactor;
   never a batch of tests written ahead. The run ends with the full build
   and an audit of the git history that proves each test was red first.
3. **A review per AC** by `kenji-reviewer`, which can read but never edit:
   is the AC really proven, does the structure hold, nothing extra?
4. **The AC record is updated** in `docs/ticket/<id>/acceptance.md`, then
   committed.
5. **A pause**: *"AC1 done. Continue, or /clear and resume?"*

It asks you only for hard-to-reverse actions, real forks, deviations from
an approved plan, out-of-scope work, or an unclear AC. Everything else, it
decides and writes down.

### 4. Follow it and save money

- `docs/decisions/<topic>.md`: every decision, why, and what was rejected.
  Its `Resume` block always says where the work stands.
- `docs/ticket/<id>/`: design, ACs with their evidence, difficulties met.
- Context gets expensive as it grows. At a pause, type `/clear`, then
  `claude --agent saiban-orchestrator` and *"resume PROJ-8"*: it continues from the
  `Resume` block instead of re-reading everything.
- Forgot the topic? Start `ci` with no topic (or ask *"where were we?"*): it
  lists the open decision logs, one line each with mode and next step, and
  asks which to resume. A log marked `Status: done` at the finish is no
  longer listed.

It commits locally, never pushes, and never writes to Jira unless asked.

**Cost, measured** on a two-AC ticket: about $2.60 on Sonnet, $6.30 on
Opus without `shonin-dev`; with it (one spawn per GREEN, before it became
one per run) about half more, about $4 on Sonnet. A small fix-mode bug: about $0.30 without it, measured before
it was the default.

### 5. Improve it

The final report always ends with **Improvements**: friction it hit and the
exact wording it would change, in the agent or a skill. It never applies
them itself. Edit `global/agents/saiban-orchestrator.md` (or the skill) and reinstall,
or symlink `~/.claude/agents/saiban-orchestrator.md` to the repo file so edits apply at
once.

