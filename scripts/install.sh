#!/usr/bin/env bash
# Install aixlper skills for Claude Code with a single command:
#
#   curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install.sh | bash
#
# Re-running this script updates skills already installed by it.
#
# Env vars:
#   AIXLPER_TARGET  Where to install skills. Defaults to the personal
#                    directory (~/.claude/skills). Set to a project's
#                    .claude/skills to install there instead.
#   AIXLPER_REF      Git ref (branch/tag) to install from. Defaults to "main".

set -euo pipefail

REPO_URL="https://github.com/Minhounet/aixlper.git"
REF="${AIXLPER_REF:-main}"
TARGET_DIR="${AIXLPER_TARGET:-$HOME/.claude/skills}"

command -v git >/dev/null 2>&1 || {
  echo "error: git is required but not found in PATH" >&2
  exit 1
}

mkdir -p "$TARGET_DIR"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Fetching aixlper (@$REF)..."
git clone --quiet --depth 1 --branch "$REF" "$REPO_URL" "$WORK_DIR/repo"

installed=()
for skill_dir in "$WORK_DIR"/repo/skills/*/; do
  name="$(basename "$skill_dir")"
  rm -rf "${TARGET_DIR:?}/$name"
  cp -r "$skill_dir" "$TARGET_DIR/$name"
  installed+=("$name")
done

echo "Installed ${#installed[@]} skill(s) to $TARGET_DIR:"
printf '  - %s\n' "${installed[@]}"
echo "Restart Claude Code (or start a new session) to pick them up."
