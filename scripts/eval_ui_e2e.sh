#!/usr/bin/env bash
# End-to-end comparison for mokugeki-tester: a session implements four UI ACs
# on a page that isn't fixed yet, then proves them, either with its own checks
# (--arm inline, UI mode without the tester) or through the mokugeki-tester
# agent (--arm tester). A hidden oracle (evals/agents/mokugeki-tester/e2e/
# oracle.js) then judges the page it left. Costs real money: bound it with
# --budget-usd (per run, subagents included).
#
# usage: eval_ui_e2e.sh --arm inline|tester [--runs 1] [--model sonnet]
#          [--budget-usd 3] [--max-turns 120] [--out <dir>]
# Prints one line per run: the arm's claim and the oracle's verdict per AC,
# defects shipped (oracle FAIL), false proofs (claimed PASS, oracle FAIL),
# and whether the tester was really spawned. ERROR from the oracle means the
# page changed too much for it to drive: read it, don't count it.

set -uo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
fx="$repo/evals/agents/mokugeki-tester/e2e"
arm= runs=1 model=sonnet budget=3 max_turns=120 out=
while [ $# -gt 0 ]; do
  case $1 in
    --arm) arm=$2; shift 2;;
    --runs) runs=$2; shift 2;;
    --model) model=$2; shift 2;;
    --budget-usd) budget=$2; shift 2;;
    --max-turns) max_turns=$2; shift 2;;
    --out) out=$2; shift 2;;
    -h|--help) sed -n '2,/^set -uo pipefail/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
case $arm in inline|tester) ;; *) echo "--arm: inline or tester" >&2; exit 2;; esac
out=${out:-$(mktemp -d)}
mkdir -p "$out"

plugin="$out/plugin"
if [ ! -d "$plugin" ]; then
  mkdir -p "$plugin/.claude-plugin" "$plugin/skills"
  printf '{"name":"aixlper-agent-eval","version":"0.0.0","description":"skills for agent evals"}\n' \
    > "$plugin/.claude-plugin/plugin.json"
  cp -r "$repo/skills/shoko-playwright" "$plugin/skills/"
fi
python3 -I "$repo/scripts/agent_to_json.py" "$repo/global/agents/mokugeki-tester.md" > "$out/agents.json"

for i in $(seq 1 "$runs"); do
  dir="$out/e2e-$arm-$i"; rm -rf "$dir"; mkdir -p "$dir"
  cp -r "$fx/work" "$dir/work"; cp -r "$fx/site" "$dir/site"
  port=$(python3 -I -c "import socket; s=socket.socket(); s.bind(('127.0.0.1',0)); print(s.getsockname()[1])")
  python3 -I -m http.server "$port" --bind 127.0.0.1 -d "$dir/site" > /dev/null 2>&1 &
  server=$!
  (cd "$dir/work" && node -e "require('playwright/test')" 2> /dev/null) ||
    { echo "eval_ui_e2e: node cannot load playwright from $dir/work" >&2; kill "$server"; exit 2; }
  prompt=$(sed -e "s|{{BASE_URL}}|http://127.0.0.1:$port|g" -e "s|{{SITE}}|$dir/site|g" "$fx/prompt.md")
  tools="Read Grep Glob Bash Skill Edit Write"
  extra=()
  if [ "$arm" = tester ]; then
    prompt="$prompt
$(cat "$fx/tester.md")"
    tools="$tools Agent Task SendMessage"
    extra=(--agents "$(cat "$out/agents.json")")
  fi
  (cd "$dir/work" && claude -p "$prompt" "${extra[@]}" --plugin-dir "$plugin" --model "$model" \
      --allowedTools "$tools" --disallowedTools "NotebookEdit" \
      --max-turns "$max_turns" --max-budget-usd "$budget" \
      --output-format stream-json --verbose > "$dir/transcript.jsonl" 2> "$dir/stderr.txt")
  cp "$fx/oracle.js" "$dir/work/.oracle.js"
  (cd "$dir/work" && node .oracle.js "http://127.0.0.1:$port" > "$dir/oracle.txt" 2>&1)
  rm -f "$dir/work/.oracle.js"
  kill "$server" 2> /dev/null
  python3 -I - "$dir" "$arm" "$i" <<'PY'
import json, re, sys
d, arm, i = sys.argv[1:]
answer, cost, spawned = '', '?', 0
for line in open(f'{d}/transcript.jsonl'):
    try:
        ev = json.loads(line)
    except ValueError:
        continue
    if ev.get('type') == 'result':
        answer, cost = ev.get('result', ''), round(ev.get('total_cost_usd', 0), 3)
    for part in (ev.get('message') or {}).get('content') or []:
        if isinstance(part, dict) and part.get('type') == 'tool_use' and \
                part.get('input', {}).get('subagent_type') == 'mokugeki-tester':
            spawned += 1
open(f'{d}/answer.md', 'w').write(answer)
claim = dict(re.findall(r'(?m)^[\s*#-]*AC([1-4])\b[^:\n]*:\s*\**\s*(PASS|FAIL|ENV|HUMAN)', answer))
oracle = dict(re.findall(r'(?m)^O([1-4]) (PASS|FAIL|ERROR)', open(f'{d}/oracle.txt').read()))
cells, shipped, false_proof = [], 0, 0
for n in '1234':
    c, o = claim.get(n, '?'), oracle.get(n, '?')
    shipped += o == 'FAIL'
    false_proof += c == 'PASS' and o == 'FAIL'
    cells.append(f'AC{n} {c}/{o}')
spawn = f'  tester-spawns {spawned}' if arm == 'tester' else ''
print(f'e2e {arm} #{i}  cost ${cost}  ' + '  '.join(cells) +
      f'  shipped {shipped}  false-proofs {false_proof}{spawn}')
PY
done
