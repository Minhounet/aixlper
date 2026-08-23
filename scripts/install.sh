#!/usr/bin/env bash
# Install aixlper skills for Claude Code with a single command:
#
#   curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install.sh | bash
#
# Re-running this script updates skills already installed by it.
# Requires only curl and tar - no git needed.
#
# Env vars:
#   AIXLPER_TARGET  Where to install skills. Defaults to the personal
#                    directory (~/.claude/skills). Set to a project's
#                    .claude/skills to install there instead.
#   AIXLPER_REF      Branch, tag, or commit to install from. Defaults to "main".

set -euo pipefail

REPO="Minhounet/aixlper"
REF="${AIXLPER_REF:-main}"
TARGET_DIR="${AIXLPER_TARGET:-$HOME/.claude/skills}"
ARCHIVE_URL="https://github.com/$REPO/archive/$REF.tar.gz"

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
