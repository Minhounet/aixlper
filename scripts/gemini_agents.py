#!/usr/bin/env python3
"""Generate the Gemini CLI copies of the helper agents from global/agents/.

global/agents/<name>.md is the only source (Claude Code format). This writes
agents/<name>.md at the repo root, the directory a Gemini CLI extension
bundles. Never edit the generated files; edit the source and re-run.

usage: gemini_agents.py           # write agents/*.md
       gemini_agents.py --check   # exit 1 if agents/*.md is out of date (used by make validate)

Not ported: saiban-orchestrator. It must run as the main session and spawn
helpers, which is Claude Code behaviour (see CLAUDE.md).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "global" / "agents"
TARGET = ROOT / "agents"
PORTED = ["kenji-reviewer", "shonin-dev", "tantei-inspector"]

# Claude Code tool name -> Gemini CLI tool name. Unverified against a live
# Gemini install: check each name on first use and fix it here.
TOOL_MAP = {
    "Read": "read_file",
    "Grep": "grep_search",
    "Glob": "glob",
    "Bash": "run_shell_command",
    "Edit": "replace",
    "Write": "write_file",
}
# Skills are not a tool in Gemini CLI; they are loaded by name, so the Skill
# tool is dropped and the body says "by name" instead.
DROPPED = {"Skill", "NotebookEdit"}


def parse(path):
    _, front, body = path.read_text().split("---", 2)
    meta = dict(re.findall(r"^(\w+): (.*)$", front, re.M))
    return meta, body.strip()


def render(name):
    meta, body = parse(SOURCE / f"{name}.md")
    disallowed = {t.strip() for t in meta.get("disallowedTools", "").split(",") if t.strip()}
    tools = []
    for t in (t.strip() for t in meta["tools"].split(",")):
        if t in disallowed or t in DROPPED:
            continue
        tools.append(TOOL_MAP[t])
    description = meta["description"].replace("Claude Code only. ", "")
    body = body.replace("with the Skill tool", "by name")
    front = [
        "---",
        f"name: {meta['name']}",
        f"description: {description}",
        "tools:",
        *[f"  - {t}" for t in tools],
        "---",
    ]
    header = f"<!-- Generated from global/agents/{name}.md by scripts/gemini_agents.py. Do not edit. -->"
    return "\n".join(front) + "\n\n" + header + "\n\n" + body + "\n"


def main():
    check = "--check" in sys.argv[1:]
    stale = []
    for name in PORTED:
        out = TARGET / f"{name}.md"
        text = render(name)
        if check:
            if not out.exists() or out.read_text() != text:
                stale.append(str(out.relative_to(ROOT)))
        else:
            TARGET.mkdir(exist_ok=True)
            out.write_text(text)
            print(f"wrote {out.relative_to(ROOT)}")
    if stale:
        print("out of date (run scripts/gemini_agents.py): " + ", ".join(stale))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
