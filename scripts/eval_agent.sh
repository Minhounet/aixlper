#!/usr/bin/env bash
# Runs a helper agent headless on a fixture whose answer is known, and checks
# its report against the answer key in evals/agents/<agent>/expected.md. The
# agent runs as the main session (--agent) under its real definition from
# global/agents/, with the skills it loads bundled as a plugin. Costs real
# money (or plan usage): bound it with --budget-usd.
#
# usage: eval_agent.sh --agent <kenji-reviewer|tantei-inspector>
#          [--runs 1] [--model sonnet] [--budget-usd 1] [--max-turns 60]
#          [--out <dir>]
#   kenji-reviewer    each run reviews two fixtures: `clean` (should PASS)
#                     and `defects` (four planted defects, D1-D4)
#   tantei-inspector  each run inspects one fixture: four planted items
#                     (T1-T4) and two decoys (X1, X2)
# Prints one summary line per fixture per run. The hints in it are keyword
# matches, not a score: read <out>/<run>/answer.md against expected.md.

set -uo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
agent= runs=1 model=sonnet budget=1 max_turns=60 out=
while [ $# -gt 0 ]; do
  case $1 in
    --agent) agent=$2; shift 2;;
    --runs) runs=$2; shift 2;;
    --model) model=$2; shift 2;;
    --budget-usd) budget=$2; shift 2;;
    --max-turns) max_turns=$2; shift 2;;
    --out) out=$2; shift 2;;
    -h|--help) sed -n '2,/^set -uo pipefail/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
case $agent in kenji-reviewer|tantei-inspector) ;; *) echo "--agent: kenji-reviewer or tantei-inspector" >&2; exit 2;; esac
out=${out:-$(mktemp -d)}
mkdir -p "$out"
python3 -I "$repo/scripts/agent_to_json.py" "$repo/global/agents/$agent.md" > "$out/agents.json"

plugin="$out/plugin"
if [ ! -d "$plugin" ]; then
  mkdir -p "$plugin/.claude-plugin" "$plugin/skills"
  printf '{"name":"aixlper-agent-eval","version":"0.0.0","description":"skills for agent evals"}\n' \
    > "$plugin/.claude-plugin/plugin.json"
  for s in igiari-tdd kanpeki-fp kaizen-refactor objection-conception chottomatte-archi; do
    cp -r "$repo/skills/$s" "$plugin/skills/"
    rm -rf "$plugin/skills/$s/evals"
  done
fi

snapshot() { git -C "$1" status --porcelain; git -C "$1" rev-parse HEAD; }

# $1 = run dir (cwd for the agent), $2 = prompt
run_agent() {
  local dir=$1 prompt=$2
  (cd "$dir/work" && claude -p "$prompt" --agents "$out/agents.json" --agent "$agent" \
      --plugin-dir "$plugin" --model "$model" \
      --allowedTools "Read Grep Glob Bash Skill" --disallowedTools "Edit Write NotebookEdit" \
      --max-turns "$max_turns" --max-budget-usd "$budget" \
      --output-format json > "$dir/result.json" 2> "$dir/stderr.txt")
  python3 -I -c "import json,sys; print(json.load(open(sys.argv[1])).get('result',''))" \
    "$dir/result.json" > "$dir/answer.md" 2>/dev/null
  cost=$(python3 -I -c "import json,sys; print(round(json.load(open(sys.argv[1])).get('total_cost_usd',0),3))" "$dir/result.json" 2>/dev/null || echo "?")
}

for i in $(seq 1 "$runs"); do
  if [ "$agent" = kenji-reviewer ]; then
    for variant in clean defects; do
      dir="$out/kenji-$variant-$i"; rm -rf "$dir"; mkdir -p "$dir"
      range=$("$repo/evals/agents/kenji-reviewer/make-fixture.sh" "$variant" "$dir/work")
      before=$(snapshot "$dir/work")
      prompt="Review AC2 of ticket KATA-1.
- AC2 verbatim: \"One or more numbers separated by commas return their sum.\"
- AC2 as interpreted: add(\"1\") returns 1, add(\"1,2\") returns 3.
- Commit range of its TDD run: $range. Its steps are numbered from 2,
  because AC1's run used 1: give the audit --first-n 2.
- Approved structural plan: docs/ticket/KATA-1/conception.md
- Ticket folder: docs/ticket/KATA-1/
- Test command: mvn -B -q --no-transfer-progress test
- Skills: objection-conception, chottomatte-archi, igiari-tdd, kanpeki-fp,
  kaizen-refactor."
      run_agent "$dir" "$prompt"
      changed=no; [ "$before" = "$(snapshot "$dir/work")" ] || changed=YES
      hints=$(python3 -I - "$dir/answer.md" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
verdict = (re.search(r'AC2:\s*(PASS|FINDINGS)', text) or [None, '?'])[1]
lines = [l for l in text.splitlines() if re.search(r'\[(blocking|minor)\]', l)]
def hit(pattern):
    for l in lines:
        if re.search(pattern, l, re.I):
            return 'B' if '[blocking]' in l else 'm'
    return '-'
print(f"verdict {verdict}  blocking {sum('[blocking]' in l for l in lines)}  minor {sum('[minor]' in l for l in lines)}"
      f"  D1 {hit(r'green 2')} D2 {hit(r'red 3')} D3 {hit(r'refactor 3|negative|IllegalArgument')} D4 {hit(r'acceptance|evidence|verified')}")
PY
)
      echo "kenji-reviewer $variant #$i  cost \$$cost  changed-on-disk $changed  $hints"
    done
  else
    dir="$out/tantei-$i"; rm -rf "$dir"; mkdir -p "$dir/clone/global"
    cp -r "$repo/evals/agents/tantei-inspector/fixture/project" "$dir/work"
    cp "$repo/CLAUDE.md" "$dir/clone/"; cp -r "$repo/skills" "$dir/clone/"
    cp -r "$repo/global/agents" "$dir/clone/global/"
    for d in "$dir/work" "$dir/clone"; do
      git -C "$d" init -q && git -C "$d" add -A &&
        git -C "$d" -c user.email=eval@example.com -c user.name=eval commit -qm fixture
    done
    before="$(snapshot "$dir/work")$(snapshot "$dir/clone")"
    prompt="Inspect how the aixlper skills and agents were used, for improve mode.
- improve.md: $dir/clone/skills/saiban-orchestrator/references/improve.md
- aixlper clone: $dir/clone
- Scope: every skill and agent in the clone.
- Evidence (all present): docs/decisions/order-export.md,
  docs/decisions/invoice-archive.md, docs/decisions/login-lock.md,
  docs/ticket/PROJ-12/retro.md, and the user's process notes at
  process-notes.md (all under the current directory). No session
  transcripts for this inspection."
    run_agent "$dir" "$prompt"
    changed=no; [ "$before" = "$(snapshot "$dir/work")$(snapshot "$dir/clone")" ] || changed=YES
    hints=$(python3 -I - "$dir/answer.md" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
blocks = re.split(r'(?m)^\**P\d+\**[:.]', text)[1:]
def hit(pattern):
    return 'Y' if any(re.search(pattern, b, re.I) for b in blocks) else '-'
print(f"proposals {len(blocks)}  T1 {hit(r'listener')} T2 {hit(r'nam(e|ing)')} "
      f"T3 {hit(r'shonin|never see|ACs')} T4 {hit(r'release notes')}  "
      f"X1 {hit(r'gradle')} X2 {hit(r'module|rename')}  delete {hit(r'\b(delete|remove) (the|this) section')}")
PY
)
    echo "tantei-inspector #$i  cost \$$cost  changed-on-disk $changed  $hints"
  fi
done
