---
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

I have this in a helper that my `.bashrc` sources:

```bash
_grep_logs() {
  local pattern
  read -r -p "pattern: " pattern
  grep -rn -- "$pattern" /var/log/myapp/
}
bind -x '"\C-xl": _grep_logs'
```

When I press Ctrl-X L the prompt shows, but whatever I type doesn't seem to go
anywhere - it just sits there, or returns immediately with nothing. Running
`_grep_logs` by hand works fine. What's wrong and how do I fix it so the
shortcut still works?

(There is no shell to run here - answer in your reply.)
