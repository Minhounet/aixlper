# Handing a recette matrix or table to someone else

Read this when the evidence from step 4 needs to leave the session as a
table or matrix a person will paste somewhere else (a ticket, a wiki, a
recette report) — not just sit in a file this session keeps.

## The usual way: the Artifact tool

If the Artifact tool is available, publish the table through it; it is
built for handing a page to the user. Don't build a local HTML page as a
substitute for Artifacts just because it's familiar — only fall back when
Artifacts genuinely don't work:

- **This session's auth doesn't support it.** A session authenticated via
  `ANTHROPIC_AUTH_TOKEN` (not a claude.ai login) gets every Artifact call
  refused outright. Don't retry it once this is confirmed for the session.
- **No artifact host at all** in this environment.

## The fallback: a local HTML file with select-to-copy tables

Build a plain local `.html` file with the table(s) as real `<table>`
elements — never a Markdown table pasted as text. Some wiki targets
(Confluence Server/Data Center, confirmed on at least one EDF-hosted
instance) do not auto-convert pasted Markdown into a table; it lands as
literal text with pipe characters. Cloud-hosted wikis often do convert it,
but don't assume that without checking on the actual target — a quick
paste-and-look test is cheap, a silently-broken handoff is not.

Each table gets its own "select to copy" button:

```js
function selectTable(tableEl) {
  const range = document.createRange();
  range.selectNode(tableEl);
  const sel = window.getSelection();
  sel.removeAllRanges();
  sel.addRange(range);
}
```

Use `window.getSelection()` + a `Range` over the table node, **not** the
Clipboard API — it avoids any clipboard-permission prompt or HTTPS-origin
restriction. The user clicks the button, the table highlights, they press
`Ctrl+C` themselves, then paste into the target: pasting a real selected
HTML table creates a native table in the destination regardless of
Cloud-vs-Server differences, because the browser hands over real `<table>`
markup, not text.

One file can hold several tables (for example one per screen in a
multi-screen recette run) as long as each has its own button, so selecting
one table doesn't carry the others along.

## Opening the file for the user

In a real (non-sandboxed) WSL2 session, `explorer.exe` can open it directly
from the Linux path:

```bash
explorer.exe "$(wslpath -w /path/to/file.html)"
```

Its exit code is unreliable (commonly non-zero even on success) — don't
treat that as failure; ask the user to confirm a window opened. Fallback:
give them the `\\wsl.localhost\<distro>\...` UNC path to paste into a
browser address bar themselves. The WSL distro name isn't always the
default one — read it from the environment (`$WSL_DISTRO_NAME`) rather than
assuming.

Outside WSL, just give the user the file path (or a `file://` URL) to open
themselves.
