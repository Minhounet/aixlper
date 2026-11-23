#!/usr/bin/env bash
# Does saiban-orchestrator switch shonin-dev on by itself once one of its own
# greens built ahead? Resumes the fixture in evals/agents/shonin-dev-switch/
# (fix mode, three planned tests, green 1 already handles test 2) and counts
# the dev spawns after red 2 passes on arrival. The prompt never mentions the
# dev. Costs real money: bound it with --budget-usd.
# usage: eval_dev_switch.sh [--runs 2] [--model sonnet] [--budget-usd 1.5]
#          [--skill-rev <git rev>] [--out <dir>]
#   --skill-rev  take saiban-orchestrator's SKILL.md from this revision (the
#                control arm: a revision before the reactive rule); default
#                the working tree
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
runs=2 model=sonnet budget=1.5 rev= out=${TMPDIR:-/tmp}/eval-dev-switch
while [ $# -gt 0 ]; do
  case $1 in
    --runs) runs=$2; shift 2;;
    --model) model=$2; shift 2;;
    --budget-usd) budget=$2; shift 2;;
    --skill-rev) rev=$2; shift 2;;
    --out) out=$2; shift 2;;
    -h|--help) sed -n 2,11p "$0"; exit 0;;
    *) echo "unknown option $1" >&2; exit 2;;
  esac
done

arm=${rev:+rev-$rev}; arm=${arm:-current}
plugin="$out/plugin-$arm"
rm -rf "$plugin"
mkdir -p "$plugin/.claude-plugin" "$plugin/skills"
printf '{"name":"aixlper-eval","version":"0.0.0"}\n' > "$plugin/.claude-plugin/plugin.json"
for s in saiban-orchestrator igiari-tdd kanpeki-fp chottomatte-archi; do
  cp -r "$repo/skills/$s" "$plugin/skills/"
  rm -rf "$plugin/skills/$s/evals"
done
[ -z "$rev" ] || git -C "$repo" show "$rev:skills/saiban-orchestrator/SKILL.md" \
  > "$plugin/skills/saiban-orchestrator/SKILL.md"
python3 -I "$repo/scripts/agent_to_json.py" "$repo/global/agents/shonin-dev.md" > "$out/agents.json"

prompt="Use the saiban-orchestrator skill to resume the work in this project
from its decision log (no review, no pauses, the plan is already approved).
Finish the TDD run to the end and keep the decision log current. There is no
IDE attached; use Maven."

for i in $(seq 1 "$runs"); do
  dir="$out/$arm-$i"
  rm -rf "$dir"; mkdir -p "$dir"
  bash "$repo/evals/agents/shonin-dev-switch/make-fixture.sh" "$dir/work"
  (cd "$dir/work" &&
    claude -p "$prompt" --plugin-dir "$plugin" --agents "$out/agents.json" --model "$model" \
      --allowedTools "Bash Edit Write Read Glob Grep Skill Agent Task SendMessage" \
      --max-turns 80 --max-budget-usd "$budget" \
      --output-format json > "$dir/result.json" 2> "$dir/stderr.txt") || true
  cost=$(python3 -I -c "import json,sys; print(round(json.load(open(sys.argv[1])).get('total_cost_usd',0),3))" "$dir/result.json" 2>/dev/null || echo "?")
  # By the run's own project folder: a nested run can inherit the caller's session id.
  proj=$(python3 -I -c "import re,sys; print(re.sub(r'[^A-Za-z0-9]', '-', sys.argv[1]))" "$(cd "$dir/work" && pwd -P)")
  spawns=$( (ls "$HOME/.claude/projects/$proj"/*/subagents/*.jsonl 2>/dev/null || true) | wc -l)
  devline=$(grep -m1 -i '^- Dev:' "$dir/work/docs/decisions/string-calculator.md" 2>/dev/null || echo "-")
  commits=$(git -C "$dir/work" log --format=%s | tac | tail -n +4 | paste -sd ';' -)
  echo "$arm #$i  cost \$$cost  subagents $spawns  resume: $devline  commits: $commits"
done
