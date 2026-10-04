---
type: llm
weight: 1
---

Ground truth: functions run from a `bind -x` keybinding execute while readline
owns the terminal (raw/non-canonical input mode), so the `read` builtin inside
them does not receive keystrokes normally. The robust fix is to not prompt
from inside the binding: have the binding put the command onto the command
line via `READLINE_LINE` (and `READLINE_POINT`), so the user types the
argument and presses Enter in normal line-editing mode - or an equivalent
approach that avoids calling `read` inside the `bind -x` callback (e.g. a
readline macro `bind '"\C-xl": "_grep_logs "'`, with the function taking its
pattern as an argument).

PASS if the agent attributes the problem to `bind -x`/readline's terminal
mode interfering with `read`, and proposes a fix that does not depend on
`read` working inside the binding (READLINE_LINE rewrite, or inserting text /
a macro so the command runs from the normal prompt).

FAIL if the main fix is something like `read </dev/tty`, `stty sane`, adding
`-e`, changing `-p`, or other tweaks that keep `read` inside the `bind -x`
callback, or if the diagnosis is wrong (e.g. blames quoting or the grep).
