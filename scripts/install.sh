#!/usr/bin/env bash
# Install aixlper skills for Claude Code with a single command:
#
#   curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install.sh | bash
#
# Re-running this script updates skills already installed by it.
# Requires only curl and tar - no git needed.
#
# Flags:
#   --link   For maintainers: instead of copying, symlink every skill into the
#            skills directory and every agent (global/agents/*.md) into
#            ~/.claude/agents, pointing back at this clone, so edits in the
#            repo are live. Anything already there (an earlier copy, an older
#            link) is removed and replaced. Needs a local clone: run
#            ./scripts/install.sh --link, not the curl one-liner.
#
# Env vars:
#   AIXLPER_TARGET         Where to install skills. Defaults to the personal
#                          directory (~/.claude/skills). Set to a project's
#                          .claude/skills to install there instead.
#   AIXLPER_AGENTS_TARGET  Where --link puts agents. Defaults to
#                          ~/.claude/agents.
#   AIXLPER_REF      Branch, tag, or commit to install from. Defaults to "main".

set -euo pipefail

REPO="Minhounet/aixlper"
REF="${AIXLPER_REF:-main}"
TARGET_DIR="${AIXLPER_TARGET:-$HOME/.claude/skills}"
AGENTS_DIR="${AIXLPER_AGENTS_TARGET:-$HOME/.claude/agents}"
ARCHIVE_URL="https://github.com/$REPO/archive/$REF.tar.gz"

LINK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --link) LINK=1 ;;
    -h|--help) sed -n '2,/^set -euo pipefail/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done

if [ "$LINK" -eq 1 ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
  CLONE_DIR="$SCRIPT_DIR/.."
  if [ -z "$SCRIPT_DIR" ] || [ ! -d "$CLONE_DIR/skills" ]; then
    echo "error: --link needs a local clone of the repo; run ./scripts/install.sh --link from it" >&2
    exit 1
  fi
  CLONE_DIR="$(cd "$CLONE_DIR" && pwd)"
  mkdir -p "$TARGET_DIR" "$AGENTS_DIR"

  linked=()
  for skill_dir in "$CLONE_DIR"/skills/*/; do
    name="$(basename "$skill_dir")"
    rm -rf "${TARGET_DIR:?}/$name"
    ln -s "${skill_dir%/}" "$TARGET_DIR/$name"
    linked+=("skill $name")
  done
  for agent in "$CLONE_DIR"/global/agents/*.md; do
    [ -e "$agent" ] || continue
    name="$(basename "$agent")"
    rm -rf "${AGENTS_DIR:?}/$name"
    ln -s "$agent" "$AGENTS_DIR/$name"
    linked+=("agent $name")
  done

  echo "Linked ${#linked[@]} item(s) to this clone ($CLONE_DIR):"
  printf '  - %s\n' "${linked[@]}"
  echo "Skills in $TARGET_DIR, agents in $AGENTS_DIR."
  echo "Restart Claude Code (or start a new session) to pick them up."
  exit 0
fi

for bin in curl tar; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "error: $bin is required but not found in PATH" >&2
    exit 1
  }
done

mkdir -p "$TARGET_DIR"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Fetching aixlper (@$REF)..."
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$WORK_DIR"

REPO_DIR="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d)"

installed=()
for skill_dir in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill_dir")"
  rm -rf "${TARGET_DIR:?}/$name"
  cp -r "$skill_dir" "$TARGET_DIR/$name"
  installed+=("$name")
done

echo "Installed ${#installed[@]} skill(s) to $TARGET_DIR:"
printf '  - %s\n' "${installed[@]}"
echo "Restart Claude Code (or start a new session) to pick them up."
