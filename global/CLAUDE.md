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


---

# Session management

## Context length

Proactively warn when the conversation context is getting heavy — before it becomes a problem, not after. A good moment to flag it is when:
- several large file reads have accumulated in the session
- a natural stopping point is approaching (a decision just closed, a commit just landed)

When flagging, suggest a concrete break point: "finish X, then start a fresh session." Don't just say "context is high" — say when to cut and why that moment is clean.

The user should never have to ask.

@~/.claude/java.md

@~/.claude/nuxeo.md
