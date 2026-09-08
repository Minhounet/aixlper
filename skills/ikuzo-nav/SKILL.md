---
name: ikuzo-nav
description: Directory bookmarks — save the current folder, list saved spots, and jump to any bookmark with /cd. Use when the user says "bookmark this", "add this folder", "where are my bookmarks", "go to <name>", "ikuzo <name>", or any navigation intent between saved directories.
---

# Ikuzo Nav — Directory Bookmarks

*"Let's go!" — iku zo! (行くぞ!)*

You are a bookmark manager for directories. Three things, nothing else:
save the current folder, list saved bookmarks, and jump to one.

Bookmarks are stored in a single JSON file: `~/.claude/bookmarks.json`.
It is global — shared across all projects and sessions.

## Reading the user's intent

Parse what the user typed when invoking this skill. The argument after the skill name is the command:

| What the user typed | Command |
|---|---|
| No argument, or `list`, or `ls` | List all bookmarks |
| `add`, `bookmark`, `save`, or `+` | Bookmark the current folder |
| `add <name>` or `bookmark <name>` | Bookmark the current folder under `<name>` |
| `cd <name>`, `go <name>`, or just `<name>` | Jump to that bookmark |
| `rm <name>`, `remove <name>`, or `delete <name>` | Remove a bookmark |

If you cannot determine the intent, show the list.

## Bookmarks file format

`~/.claude/bookmarks.json`:

```json
{
  "bookmarks": {
    "workspace": "/home/alice/workspaces",
    "aixlper": "/home/alice/workspaces/aixlper"
  }
}
```

If the file does not exist, treat it as `{ "bookmarks": {} }` and create it on first write.

## Command: list

Read `~/.claude/bookmarks.json`. Print the bookmarks as a table:

```
Name          Path
──────────    ──────────────────────────────
workspace     /home/alice/workspaces
aixlper       /home/alice/workspaces/aixlper
```

If there are no bookmarks yet, say so and hint that `add` saves the current one.

## Command: add

1. Run `pwd` to get the current directory path.
2. Determine the bookmark name:
   - If the user supplied a name, use it.
   - Otherwise, use the last segment of the current path (e.g. `/home/alice/workspaces/aixlper` → `aixlper`).
3. Read the bookmarks file (or start from empty if it doesn't exist).
4. Add or overwrite the entry: `"<name>": "<path>"`.
5. Write the updated file back atomically — write to `~/.claude/bookmarks.json.tmp` first, then rename it over the original.
6. Confirm: `Bookmarked "aixlper" → /home/alice/workspaces/aixlper`.

If a bookmark with that name already exists, overwrite it and say so: `Updated "aixlper" (was /old/path, now /new/path)`.

## Command: cd

1. Read `~/.claude/bookmarks.json`.
2. Look up `<name>`. If not found, list the available bookmarks and stop.
3. Output the resolved path and the ready-to-run slash command for the user to execute:

```
→ /home/alice/workspaces/aixlper

/cd /home/alice/workspaces/aixlper
```

The user runs `/cd <path>` themselves — Claude cannot invoke slash commands directly.

When the path no longer exists on disk, warn: `Bookmark "aixlper" points to /home/alice/workspaces/aixlper which does not exist. Remove it with /ikuzo-nav rm aixlper?`

## Command: rm

1. Read the bookmarks file.
2. Remove the entry for `<name>`. If it doesn't exist, say so.
3. Write the file back.
4. Confirm: `Removed "aixlper".`

## Error handling

- Missing bookmarks file → treat as empty, never error.
- Corrupt JSON → tell the user, show the path, stop. Do not overwrite a corrupt file silently.
- Ambiguous name (prefix matches multiple entries) → list the candidates and ask which one.
- No argument when the intent was clearly navigation (e.g. the user typed just a word) → try it as a bookmark name before falling back to list.
