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
PORTED = ["kenji-reviewer", "shonin-dev", "mokugeki-tester", "tantei-inspector"]

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
# The Claude descriptions say "saiban-orchestrator spawns it, not for direct
# use". The orchestrator is not ported, so in Gemini CLI the main session is
# the caller: each description says when to delegate and what to hand over.
GEMINI_DESCRIPTIONS = {
    "kenji-reviewer": (
        "Reviewer (kenji = the prosecutor). Read-only. Delegate to it after the TDD run for one "
        "acceptance criterion, before calling that criterion done. Give it the criterion verbatim, "
        "the commit range, the approved structural plan, the ticket folder and the test command. "
        "It checks the run against the aixlper skills as written and reports findings; it never fixes."
    ),
    "shonin-dev": (
        "Implementer (shonin = the witness). Delegate to it the GREEN steps of a TDD run (igiari-tdd), one at a time, "
        "so the code is not biased by what comes next. Give it only the failing test, the test command, "
        "the production files in play and the approved structural plan - never the test plan, the "
        "ticket or the acceptance criteria. It writes the least code that passes and never commits."
    ),
    "mokugeki-tester": (
        "UI tester (mokugeki = the eyewitness). Delegate to it the Playwright check of each acceptance "
        "criterion of one web screen (shoko-playwright), so the check proves what a user sees rather than "
        "what the code was changed to do. Give it each criterion verbatim, the base URL and the way to the "
        "screen, the names of the login environment variables, the viewports a layout criterion names and "
        "where the project's checks live - never the diff, the app source, the decision log or the design. "
        "Deploy first; after each change, ask it to re-run the same check. It writes only check files, "
        "never commits, and reports PASS, FAIL, ENV or HUMAN per criterion."
    ),
    "tantei-inspector": (
        "Inspector of the aixlper skills (tantei = the detective). Read-only. Delegate to it to review "
        "how the aixlper skills and agents were used. Give it the path of "
        "skills/saiban-orchestrator/references/improve.md in the aixlper clone (its checklist; that "
        "skill itself is not installed for Gemini), the aixlper clone path, the "
        "scope and the evidence paths (decision logs, retros, process notes). It proposes exact wording "
        "changes with the evidence; it never edits."
    ),
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
    description = GEMINI_DESCRIPTIONS[name]
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
