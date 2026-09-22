#!/usr/bin/env bash
# Install the author's global Claude Code config (CLAUDE.md + its imports, and
# a generated settings.json) onto any machine:
#
#   ./scripts/install-global.sh                       # from a local clone
#   curl -fsSL https://raw.githubusercontent.com/Minhounet/aixlper/main/scripts/install-global.sh | bash
#
# Skills are NOT handled here - use scripts/install.sh for those. Keeping them
# separate means this script never disturbs a development machine where
# ~/.claude/skills/* are symlinks back into a clone of this repo.
#
# Secrets never live in this repo. Values for the settings "env" block are read
# from ~/.claude/aixlper.env (see global/aixlper.env.example) or from the
# environment. Anything left empty is omitted from the generated file, so a
# personal machine with no corporate gateway gets a clean working config.
#
# Env vars:
#   AIXLPER_HOME_TARGET  Where to install. Defaults to ~/.claude.
#   AIXLPER_REF          Branch/tag/commit to fetch when not run from a clone.
#   ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, HTTP_PROXY, NO_PROXY
#                        Override whatever aixlper.env provides.
#
# Flags:
#   --dry-run   Report what would change and write nothing.

set -euo pipefail

REPO="Minhounet/aixlper"
REF="${AIXLPER_REF:-main}"
TARGET_DIR="${AIXLPER_HOME_TARGET:-$HOME/.claude}"
ENV_FILE="$TARGET_DIR/aixlper.env"
DRY_RUN=0

# Files copied verbatim. java.md and nuxeo.md are no longer @-imported by
# CLAUDE.md — it points at them to be read on demand — but they must still be
# installed, since a missing file would leave those pointers dangling.
# litellm-budget.py is the
# statusLine/SessionStart-hook script settings.template.json wires in below;
# it needs its executable bit preserved, which the copy loop below handles
# for any file in this list, not just this one.
CONFIG_FILES=(CLAUDE.md java.md nuxeo.md litellm-budget.py)

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done

say()  { printf '%s\n' "$*"; }
act()  { if [ "$DRY_RUN" -eq 1 ]; then printf '  [dry-run] %s\n' "$*"; else printf '  %s\n' "$*"; fi; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- source files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/../global" ]; then
  SRC_DIR="$(cd "$SCRIPT_DIR/../global" && pwd)"
  say "Using local checkout: $SRC_DIR"
else
  for bin in curl tar; do
    command -v "$bin" >/dev/null 2>&1 || die "$bin is required but not found in PATH"
  done
  WORK_DIR="$(mktemp -d)"
  trap 'rm -rf "$WORK_DIR"' EXIT
  say "Fetching aixlper (@$REF)..."
  curl -fsSL "https://github.com/$REPO/archive/$REF.tar.gz" | tar -xz -C "$WORK_DIR"
  SRC_DIR="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d)/global"
  [ -d "$SRC_DIR" ] || die "no global/ directory in the fetched archive"
fi

TEMPLATE="$SRC_DIR/settings.template.json"
[ -f "$TEMPLATE" ] || die "missing $TEMPLATE"

# ------------------------------------------------------------------- env block

# Parsed rather than sourced: this file holds a credential and must never be
# able to execute anything.
read_env_file() {
  local key="$1" line value
  [ -f "$ENV_FILE" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "$key="*)
        value="${line#*=}"
        value="${value%\"}"; value="${value#\"}"
        printf '%s' "$value"
        return 0
        ;;
    esac
  done < "$ENV_FILE"
}

# Environment wins over the file, so a one-off run can override without editing.
# Note this also picks up an already-exported value from the calling shell -
# convenient for capturing a working setup, but the summary always names the
# source so it is never a silent capture.
FROM_ENV=0
FROM_FILE=0
RESOLVED=""
resolve() {
  local key="$1"
  RESOLVED=""
  if [ -n "${!key:-}" ]; then
    RESOLVED="${!key}"
    FROM_ENV=$((FROM_ENV + 1))
    return 0
  fi
  RESOLVED="$(read_env_file "$key")"
  [ -n "$RESOLVED" ] && FROM_FILE=$((FROM_FILE + 1))
  return 0
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

ENTRY_KEYS=()
ENTRY_VALUES=()
add_entry() {
  [ -n "$2" ] || return 0
  ENTRY_KEYS+=("$1")
  ENTRY_VALUES+=("$(json_escape "$2")")
}

resolve ANTHROPIC_BASE_URL;   base_url="$RESOLVED"
resolve ANTHROPIC_AUTH_TOKEN; auth_token="$RESOLVED"
resolve HTTP_PROXY;           http_proxy_val="$RESOLVED"
resolve NO_PROXY;             no_proxy_val="$RESOLVED"

add_entry CLAUDE_CODE_ENABLE_TELEMETRY "0"
add_entry ANTHROPIC_BASE_URL "$base_url"
add_entry ANTHROPIC_AUTH_TOKEN "$auth_token"
# Both casings: different tools in the chain read different ones.
add_entry HTTP_PROXY "$http_proxy_val"
add_entry HTTPS_PROXY "$http_proxy_val"
add_entry http_proxy "$http_proxy_val"
add_entry https_proxy "$http_proxy_val"
add_entry NO_PROXY "$no_proxy_val"
add_entry no_proxy "$no_proxy_val"

ENV_BLOCK=""
for i in "${!ENTRY_KEYS[@]}"; do
  sep=","
  [ "$i" -eq $(( ${#ENTRY_KEYS[@]} - 1 )) ] && sep=""
  ENV_BLOCK+="    \"${ENTRY_KEYS[$i]}\": \"${ENTRY_VALUES[$i]}\"${sep}"
  [ -n "$sep" ] && ENV_BLOCK+=$'\n'
done

# --------------------------------------------------------------------- install

say ""
say "Installing global config to $TARGET_DIR"
[ "$DRY_RUN" -eq 1 ] || mkdir -p "$TARGET_DIR"

backup_if_needed() {
  local dest="$1"
  [ -e "$dest" ] || return 0
  local bak="$dest.bak.$(date +%s)"
  act "backup $(basename "$dest") -> $(basename "$bak")"
  [ "$DRY_RUN" -eq 1 ] || cp -p "$dest" "$bak"
}

for f in "${CONFIG_FILES[@]}"; do
  src="$SRC_DIR/$f"
  dest="$TARGET_DIR/$f"
  [ -f "$src" ] || die "missing $src"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    act "$f unchanged"
  else
    backup_if_needed "$dest"
    act "write $f"
    [ "$DRY_RUN" -eq 1 ] || cp "$src" "$dest"
  fi
  # cmp only checks content, so an unchanged file with the wrong mode (e.g.
  # restored from a backup, or copied by hand) would otherwise stay non-executable.
  if [ "$DRY_RUN" -eq 0 ] && [ -x "$src" ] && [ ! -x "$dest" ]; then
    chmod +x "$dest"
  fi
done

# settings.json is generated, not copied, so the template can stay secret-free.
settings_dest="$TARGET_DIR/settings.json"
rendered="$(
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "@@ENV_BLOCK@@" ]; then
      printf '%s\n' "$ENV_BLOCK"
    else
      printf '%s\n' "$line"
    fi
  done < "$TEMPLATE"
)"

case "$rendered" in
  *@@*) die "unexpanded placeholder left in settings.json - refusing to write" ;;
esac

if [ -f "$settings_dest" ] && [ "$rendered" = "$(cat "$settings_dest")" ]; then
  act "settings.json unchanged"
else
  backup_if_needed "$settings_dest"
  act "write settings.json (${#ENTRY_KEYS[@]} env entries)"
  if [ "$DRY_RUN" -eq 0 ]; then
    printf '%s\n' "$rendered" > "$settings_dest"
    chmod 600 "$settings_dest"
  fi
fi

# ---------------------------------------------------------------------- report

say ""
if [ -z "$auth_token$base_url$http_proxy_val" ]; then
  say "No gateway/proxy values found - generated a plain config."
  say "To add them: cp global/aixlper.env.example $ENV_FILE && chmod 600 $ENV_FILE"
else
  # Reports source and count only - never a value.
  say "Gateway/proxy settings applied: $FROM_ENV from the shell environment, $FROM_FILE from $ENV_FILE."
  [ "$FROM_ENV" -gt 0 ] && say "  (shell values take precedence; unset them to use the file instead)"
fi
say "Skills are installed separately: scripts/install.sh"
say "Restart Claude Code (or start a new session) to pick this up."
