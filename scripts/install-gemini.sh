#!/usr/bin/env bash
# Install aixlper skills and helper agents for Gemini CLI, minus the
# Claude-only skills listed in scripts/gemini-exclude.txt:
#
#   curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install-gemini.sh | bash
#   ./scripts/install-gemini.sh        # from a local clone: installs the clone as it is
#
# Re-running it updates what it installed. An excluded or retired skill left
# by an earlier install (or by the extension) is removed. Use this or
# `gemini extensions install`, not both: the extension ships every skill,
# Claude-only ones included.
#
# Requires curl and tar when not run from a clone.
#
# Env vars:
#   AIXLPER_GEMINI_SKILLS  Where to install skills. Defaults to ~/.gemini/skills.
#                          Set to a project's .gemini/skills to install there.
#   AIXLPER_GEMINI_AGENTS  Where to install agents. Defaults to ~/.gemini/agents.
#   AIXLPER_REF            Branch, tag, or commit to fetch. Defaults to "main".

set -euo pipefail

REPO="Minhounet/aixlper"
REF="${AIXLPER_REF:-main}"
SKILLS_DIR="${AIXLPER_GEMINI_SKILLS:-$HOME/.gemini/skills}"
AGENTS_DIR="${AIXLPER_GEMINI_AGENTS:-$HOME/.gemini/agents}"
ARCHIVE_URL="https://github.com/$REPO/archive/$REF.tar.gz"

case "${1:-}" in
  "") ;;
  -h|--help) sed -n '2,/^set -euo pipefail/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "error: unknown argument: $1" >&2; exit 1 ;;
esac

# Names in a list file, comments and blank lines skipped.
names_in() {
  [ -f "$1" ] || return 0
  grep -v '^[[:space:]]*\(#\|$\)' "$1" | awk '{print $1}'
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/../skills" ] && [ -d "$SCRIPT_DIR/../agents" ]; then
  REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  echo "Installing from the local clone ($REPO_DIR)."
else
  for bin in curl tar; do
    command -v "$bin" >/dev/null 2>&1 || { echo "error: $bin is required but not found in PATH" >&2; exit 1; }
  done
  WORK_DIR="$(mktemp -d)"
  trap 'rm -rf "$WORK_DIR"' EXIT
  echo "Fetching aixlper (@$REF)..."
  curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$WORK_DIR"
  REPO_DIR="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d)"
fi

mkdir -p "$SKILLS_DIR" "$AGENTS_DIR"
EXCLUDED="$(names_in "$REPO_DIR/scripts/gemini-exclude.txt")"

# retired-names.txt lines are "<kind> <old> <new>".
while read -r kind old new_name _; do
  case "$kind" in
    skill) target="$SKILLS_DIR/$old" ;;
    agent) target="$AGENTS_DIR/$old.md" ;;
    *) continue ;;
  esac
  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -rf "${target:?}"
    echo "Removed retired $kind $old (now $new_name)."
  fi
done < <(grep -v '^[[:space:]]*\(#\|$\)' "$REPO_DIR/scripts/retired-names.txt" 2>/dev/null || true)

installed=()
skipped=()
for skill_dir in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill_dir")"
  rm -rf "${SKILLS_DIR:?}/$name"
  if grep -qx "$name" <<<"$EXCLUDED"; then
    skipped+=("$name")
    continue
  fi
  cp -r "$skill_dir" "$SKILLS_DIR/$name"
  installed+=("skill $name")
done
for agent in "$REPO_DIR"/agents/*.md; do
  [ -e "$agent" ] || continue
  cp "$agent" "$AGENTS_DIR/"
  installed+=("agent $(basename "$agent" .md)")
done

echo "Installed ${#installed[@]} item(s): skills in $SKILLS_DIR, agents in $AGENTS_DIR:"
printf '  - %s\n' "${installed[@]}"
[ ${#skipped[@]} -eq 0 ] || echo "Not installed (Claude Code only, see scripts/gemini-exclude.txt): ${skipped[*]}"
echo "Restart Gemini CLI to pick them up."
