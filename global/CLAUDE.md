# This file — when and how to maintain it

## Structure

Keep this file organized in clearly named top-level sections (`#`) and subsections (`##`). Before adding anything new, suggest where it fits (existing section, new subsection, or new section) and ask for confirmation.

## When to add something here

Add to this global CLAUDE.md only when a rule or preference applies **across all projects**, regardless of language or context — things like commit conventions, comment style, language to write in, or how to interact. Project-specific conventions (file structure, framework choices, domain rules) belong in the project's own CLAUDE.md instead.

---

# Global coding rules

## Code comments

Only add a comment when the **WHY** is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, behavior that would surprise a reader.

Never explain what the code does — well-named identifiers already do that.

Always write comments in English.

---

# Git workflow

## Commit messages

Always follow the format: `<gitmoji><JIRA ID>|<message>`

Examples:
- 📝PROJ-1234|Add package transfer part
- 🚑PROJ-5678|Fix missing DROP INDEX causing ORA-00955

Use [gitmoji](https://gitmoji.dev) to pick the right emoji (e.g. 🚑 hotfix, 🐛 bug fix, ✨ new feature, ♻️ refactor, 📝 docs).

## After committing

Always report the full commit message to the user immediately after committing.

## Squash before merging to a shared branch

Before a local feature branch is merged into a shared/main branch (`main`, `integration`, `develop`, ...), squash its commits into a single commit. The intermediate red/green/refactor or work-in-progress commits are useful while working locally; they add noise once the branch lands on a branch other people build on top of.

- If the shared branch has moved since the feature branch forked, rebase onto it first, then squash.
- If it hasn't moved (verify with `git merge-base <shared-branch> HEAD` vs `git rev-parse <shared-branch>`), squash directly with `git reset --soft <shared-branch-or-merge-base>` followed by one `git commit` — do not use `git rebase -i`, which needs interactive input this tooling can't provide.
- The squashed commit message still follows the format in "Commit messages" above. If the work has no associated ticket, drop the `<JIRA ID>|` segment rather than inventing one.
- This produces a single rewritten commit — never force-push it to the shared branch itself, and confirm with the user whether to push the feature branch, open a merge/pull request, or both before doing either.

---

# Session management

## Context length

Proactively warn when the conversation context is getting heavy — before it becomes a problem, not after. A good moment to flag it is when:
- several large file reads have accumulated in the session
- a natural stopping point is approaching (a decision just closed, a commit just landed)

When flagging, suggest a concrete break point: "finish X, then start a fresh session." Don't just say "context is high" — say when to cut and why that moment is clean.

The user should never have to ask.

## Response length

Output tokens cost roughly five times input tokens, and unlike the files
loaded into context they are paid fresh every turn — nothing caches them.
Length is therefore a cost lever that is entirely yours to pull, and pulling
it costs no correctness.

Answer in the fewest words that are actually complete:

- No preamble, no restating the question, no summarising what you just did
  when the diff or the command output already shows it.
- Report a result, not a narration of arriving at it. "Tests pass, 12/12" —
  not the reasoning that led there, unless it is what was asked for.
- Explanations and comparisons are expanded **on request**. A one-line answer
  plus "want the reasoning?" beats three paragraphs nobody asked for.
- Tables and lists over prose when the content is genuinely tabular; prose
  over tables when it is not. Neither as decoration.

This does not license leaving out something the answer needs — a caveat that
changes what the user would do, a limit on what was verified, or a real
disagreement still gets said. Brevity is about removing what adds nothing, not
about withholding what matters.

## Delegate reading-heavy work

When a task needs a lot of *reading* to produce a little *conclusion* —
locating a symbol across an unfamiliar codebase, working out how a legacy
component is wired, trawling a long log — delegate it to a subagent rather
than doing it inline.

The saving is not the subagent's own tokens; it is that everything it reads
stays in its context and never enters this one. A dozen file dumps become one
paragraph of findings. The cost compounds, because context already loaded is
re-sent on every later turn of the session.

The trade is real and worth stating: you get the conclusion, not the evidence.
Delegate the search, keep the decision — and when the finding is surprising or
load-bearing, verify the specific file or line yourself rather than taking the
summary on trust.

## Effort level

`claude --effort <low|medium|high|xhigh|max>` sets thinking depth and overall
token spend for a session; the default is `xhigh`. Lower effort means fewer
and more-consolidated tool calls, less preamble, terser confirmations.

Because it works *within* one model it does not split the prompt cache the way
switching models does — caches are model-scoped. So before routing work to a
cheaper model, try the capable model at lower effort on the same task: it
keeps one cache namespace and often holds quality that a model downgrade
would not.

Rule of thumb: `high` for routine work where the rules are already written
down (following a TDD or architecture skill), `xhigh` or `max` when the
judgment is the point (designing a structure, debugging something unfamiliar).

---

# Language- and platform-specific rules — read on demand

These are **not** `@`-imported, deliberately: an unconditional import loads
them into every session regardless of what the session is about, which is
pure resident cost on a bash, markdown or Python task. Read the file
yourself, with your file-reading tool, the first time a session turns out
to match — then treat its rules as binding for the rest of that session.

| Read | When |
|---|---|
| `~/.claude/java.md` | The session touches Java source: injected fields, the 121-char line limit, log levels, TDD ordering. Read it before writing or changing any `.java` file. |
| `~/.claude/nuxeo.md` | The session touches a Nuxeo project: listener event filtering, component documentation, contributing audit events, and when Gradle is allowed for dev speed vs. Maven being mandatory for release. Read it before changing a listener, a component contribution, or the build. |

Read the file once per session, not once per edit. If a session starts as
something else and *becomes* Java or Nuxeo work, read it at that point.
