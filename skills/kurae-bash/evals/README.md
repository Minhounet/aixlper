# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

| Case | Targets | Sonnet, 3+3 runs, 2026-10-03 |
|---|---|---|
| `bind-x-prompt` | Pattern 1: no `read` inside a `bind -x` callback; put the command onto `READLINE_LINE` instead | with 1.00 / without 0.00 |
| `bookmark-remove` | Pattern 10 (`grep -vxF`) and pattern 6 (`mktemp` + `mv`) | with 1.00 / without 1.00 |

**`bind-x-prompt` discriminates, but less sharply than 1.00 vs 0.00
suggests.** The baseline does diagnose readline's raw mode correctly. Its
*primary* fix is `read </dev/tty` (plus `stty sane` as a fallback), which
keeps `read` inside the callback. The `READLINE_LINE` approach shows up only
as the second or third option. With the skill, the robust fix comes first.
The grader judges the main fix, so the 0.00 is the right score, but the
baseline was not clueless.

**`bookmark-remove` does not discriminate.** Sonnet finds the substring
match and the non-atomic rewrite without the skill. Patterns 6 and 10 are
common shell knowledge. Run cost: $0.68.
