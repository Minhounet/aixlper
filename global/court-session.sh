#!/usr/bin/env bash
# court-session.sh: SessionStart hook. The judge opens the session.
#
# Reads the Resume block of each open docs/decisions/*.md in the project
# (the saiban-orchestrator decision logs) and prints the open cases to the
# user: topic, mode, Next, plus branch and uncommitted file count.
#
# Shown to the user (hook JSON "systemMessage"). Claude's context gets one
# short line, only when cases are open, so saiban-orchestrator's own recap
# doesn't list them a second time. Silent when the project keeps no
# docs/decisions/, after a compaction, or when AIXLPER_NO_COURT=1.
# The verdict at the end belongs to saiban-orchestrator (its "Court" section):
# only the session knows whether the ACs were proven.
#
# Pure bash + sed: no jq, as for the rest of global/.
set -uo pipefail

[ "${AIXLPER_NO_COURT:-0}" = "1" ] && exit 0

input="$(cat 2>/dev/null || true)"
case "$input" in
  *'"source"'*'"compact"'*) exit 0 ;;
esac

project="${CLAUDE_PROJECT_DIR:-$PWD}"
dir="$project/docs/decisions"
[ -d "$dir" ] || exit 0

# Value of "- <key>:" inside the "## Resume" block of a log.
resume_field() {
  sed -n '/^## Resume[[:space:]]*$/,/^## /p' "$2" \
    | sed -n "s/^- $1:[[:space:]]*//p" | head -n 1
}

cases=""
count=0
# Newest first, at most 10, as the orchestrator's own recap.
while IFS= read -r log; do
  [ -f "$log" ] || continue
  status="$(resume_field Status "$log")"
  case "$status" in done*) continue ;; esac
  grep -q '^## Resume' "$log" || continue
  topic="$(basename "$log" .md)"
  mode="$(resume_field Mode "$log")"
  next="$(resume_field Next "$log")"
  [ "${#next}" -gt 90 ] && next="${next:0:87}..."
  count=$((count + 1))
  cases+=$'\n'"  ${count}. ${topic} (${mode:-?}): next: ${next:-?}"
  [ "$count" -ge 10 ] && break
done < <(ls -t "$dir"/*.md 2>/dev/null)

branch="$(git -C "$project" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
dirty="$(git -C "$project" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

msg="⚖️  The court is in session."
if [ "$count" -eq 0 ]; then
  msg+=" No case on the docket."
else
  msg+=" The defendant stands accused of unfinished work:${cases}"
fi
if [ -n "$branch" ]; then
  msg+=$'\n'"  Branch ${branch}, ${dirty:-0} uncommitted file(s)."
fi
[ "$count" -gt 0 ] && msg+=$'\n'"  How do you plead? Resume a case, or open a new one."

# JSON-escape: backslash, double quote, then control characters.
esc="${msg//\\/\\\\}"
esc="${esc//\"/\\\"}"
esc="${esc//$'\n'/\\n}"
esc="${esc//$'\t'/\\t}"
if [ "$count" -gt 0 ]; then
  ctx="The court-session hook already showed the user ${count} open case(s)."
  printf '{"systemMessage": "%s", "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "%s"}}\n' "$esc" "$ctx"
else
  printf '{"systemMessage": "%s"}\n' "$esc"
fi
