# Driving IntelliJ's debugger through MCP (untested)

Read this when the user wants the investigation done in their IntelliJ
debugger (they watch the breakpoints and values in the IDE while the
assistant drives) instead of `jdb`. **Not run from this repo yet**: treat
every detail below as a lead to check, not a recipe.

## What exists

Third-party IntelliJ plugins expose the IDE's debugger as an MCP server:
breakpoints, start a debug session from a run configuration, step,
stack, variables, evaluate expression. Two seen so far:

- `jetbrains-debugger-mcp-plugin` (github.com/hechtcarmel/jetbrains-debugger-mcp-plugin),
  installed from the IDE's plugin settings; its own settings page gives the
  MCP port and path (sources disagree on the defaults, so read them there).
- Amplicode's `java-debug` skill and its IntelliJ debug MCP server.

IntelliJ's own built-in MCP server (recent versions) exposes files, search
and run configurations; check whether it has debugger tools before
assuming it does.

## How it differs from jdb

- **It is the IDE's Debug session**, so `jdb` can't attach to the same JVM
  at the same time (one debugger per JVM). Pick one per investigation.
- **Better reading**: the IDE's evaluator takes lambdas, and collections show
  their elements, not their internals.
- **No event push**: after resume or step, the MCP server doesn't announce
  the breakpoint hit. Poll the session state before reading values.
- **Evaluation runs real code** in the JVM: an expression with a side
  effect (a setter, a save) changes the state being investigated. Evaluate
  getters and pure expressions only, unless testing a hypothesis on purpose
  (record it in the note).
- Local only: the IDE and the MCP server run on the user's machine, so the
  assistant must run there too.

The bisection, the note and the hand-over in `SKILL.md` don't change.
Only the tool that reads the values does.

## When it is first used for real

Record here what was confirmed: the plugin and version, the MCP port and
path, the tool names actually used for breakpoint / step / evaluate, and
any pitfall. Then remove "(untested)" from the title.
