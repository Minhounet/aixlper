#!/usr/bin/env bash
# Runs an igiari-tdd kata headless and measures super green on its history.
# For each run: a throwaway Maven project, a fresh `claude -p` with the Java
# skills loaded and the kata's plan pre-approved, then audit-tdd-history.sh
# with PMD on the commits it left. Costs real money: bound it with --budget-usd.
#
# usage: kata_super_green.sh --kata <name> [--runs 1] [--model sonnet]
#          [--budget-usd 2] [--max-turns 150] [--out <dir>] [--pmd <pmd bin>]
#          [--baseline | --orchestrator dev|nodev]
#   --kata        a file name in katas/igiari-tdd/ without .md
#   --budget-usd  per run, passed to claude --max-budget-usd
#   --pmd         the PMD 7 launcher (default: pmd on PATH)
#   --baseline    no skill loaded: plain TDD with the same commit format,
#                 the comparison arm (run dirs are named <kata>-base-<n>)
#   --orchestrator  run through saiban-orchestrator in fix mode (plan
#                 pre-approved, no review, no pauses) instead of igiari-tdd
#                 alone. `dev`: "with dev", shonin-dev writes the greens;
#                 `nodev`: the same with "no dev". The pair measures the dev
#                 agent and nothing else (run dirs <kata>-dev-<n>, -nodev-<n>).
#                 The summary adds `subagents`, counted from the session's
#                 subagent transcripts: 0 in a dev run means the dev never ran
#                 and the run is invalid; above 0 in a nodev run, check which.
# Prints one summary line per run; details stay in <out>/<kata>-<n>/.
set -uo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
kata= baseline= orch= runs=1 model=sonnet budget=2 max_turns=150 out= pmd=${PMD:-pmd}
while [ $# -gt 0 ]; do
  case $1 in
    --kata) kata=$2; shift 2;;
    --runs) runs=$2; shift 2;;
    --model) model=$2; shift 2;;
    --budget-usd) budget=$2; shift 2;;
    --max-turns) max_turns=$2; shift 2;;
    --out) out=$2; shift 2;;
    --pmd) pmd=$2; shift 2;;
    --baseline) baseline=1; shift;;
    --orchestrator) orch=$2; shift 2
      case $orch in dev|nodev) ;; *) echo "--orchestrator takes dev or nodev" >&2; exit 2;; esac;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
plan="$repo/katas/igiari-tdd/$kata.md"
# Optional sidecar, never shown to the agent: GENERALIZE_FROM=<first green
# the plan allows to loop/stream/recurse>, checked by the audit (rule 5).
gen_from=
[ -f "$repo/katas/igiari-tdd/$kata.audit" ] &&
  gen_from=$(sed -n 's/^GENERALIZE_FROM=\([0-9][0-9]*\)$/\1/p' "$repo/katas/igiari-tdd/$kata.audit")
[ -f "$plan" ] || { echo "no kata: $plan" >&2; exit 2; }
command -v "$pmd" >/dev/null || { echo "PMD not found: $pmd (use --pmd)" >&2; exit 2; }
[ -z "$baseline" ] || [ -z "$orch" ] || { echo "--baseline and --orchestrator are separate arms" >&2; exit 2; }
out=${out:-$(mktemp -d)}
mkdir -p "$out"

# Plugin bundling the skills igiari-tdd loads in practice.
plugin="$out/plugin"
if [ ! -d "$plugin" ]; then
  mkdir -p "$plugin/.claude-plugin" "$plugin/skills"
  printf '{"name":"aixlper-kata","version":"0.0.0","description":"Java skills for kata runs"}\n' \
    > "$plugin/.claude-plugin/plugin.json"
  for s in igiari-tdd kanpeki-fp kaizen-refactor; do
    mkdir -p "$plugin/skills/$s"
    cp "$repo/skills/$s/SKILL.md" "$plugin/skills/$s/"
    for d in references scripts; do
      [ -d "$repo/skills/$s/$d" ] && cp -r "$repo/skills/$s/$d" "$plugin/skills/$s/"
    done
  done
fi

# The orchestrator arms need its skill, every skill the dev loads, and the dev
# agent itself under its plain name (a plugin agent would get a prefix the
# skill doesn't use), so the agent goes in through --agents instead.
orch_plugin="$out/plugin-orchestrator"
if [ -n "$orch" ] && [ ! -d "$orch_plugin" ]; then
  cp -r "$plugin" "$orch_plugin"
  for s in saiban-orchestrator chottomatte-archi; do
    cp -r "$repo/skills/$s" "$orch_plugin/skills/"
    rm -rf "$orch_plugin/skills/$s/evals"
  done
  python3 -I "$repo/scripts/agent_to_json.py" "$repo/global/agents/shonin-dev.md" > "$out/agents.json"
fi

new_project() {
  mkdir -p "$1/src/main/java/com/example" "$1/src/test/java/com/example"
  cat > "$1/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>kata</artifactId>
  <version>1.0-SNAPSHOT</version>
  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>
  <dependencies>
    <dependency><groupId>io.vavr</groupId><artifactId>vavr</artifactId><version>0.10.4</version></dependency>
    <dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter</artifactId><version>5.11.3</version><scope>test</scope></dependency>
    <dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter-params</artifactId><version>5.11.3</version><scope>test</scope></dependency>
  </dependencies>
  <build><plugins>
    <plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-surefire-plugin</artifactId><version>3.5.2</version></plugin>
  </plugins></build>
</project>
EOF
  printf 'target/\n' > "$1/.gitignore"
  git -C "$1" init -q
  git -C "$1" -c user.email=kata@example.com -c user.name=kata add -A
  git -C "$1" -c user.email=kata@example.com -c user.name=kata commit -qm "init"
}

arm=${baseline:+-base}${orch:+-$orch}
for i in $(seq 1 "$runs"); do
  dir="$out/$kata$arm-$i"
  rm -rf "$dir"; new_project "$dir/work"
  base=$(git -C "$dir/work" rev-parse HEAD)
  if [ -n "$baseline" ]; then
    prompt="Implement this kata in Java with test-driven development, in the
Maven project in the current directory. JUnit 5 and Vavr are already in the pom.

$(cat "$plan")

Work one test at a time: red, then green, then refactor. Commit each step:
subject \"red N: ...\" for the failing test, \"green N: ...\" for the code
that makes it pass, and \"refactor N: ...\" only when you change something.
Run every planned test straight through to the end without waiting for
approval, then run mvn verify. There is no IDE attached; use Maven."
    plugin_args=()
  elif [ -n "$orch" ]; then
    opts="no review, no pauses, plan pre-approved"
    if [ "$orch" = nodev ]; then opts="$opts, no dev"; else opts="$opts, with dev"; fi
    prompt="Use the saiban-orchestrator skill in fix mode ($opts) to implement
this kata in Java, in the Maven project in the current directory. JUnit 5 and
Vavr are already in the pom. Scope: this kata only; nothing outside this
directory may change.

$(cat "$plan")

The test plan above is the igiari-tdd plan, approved as-is: do not wait for
approval, run every cycle straight through to the end, then the final full
build and the audit igiari-tdd describes (the task started at commit $base).
Commit each step as igiari-tdd says. There is no IDE attached; use Maven."
    plugin_args=(--plugin-dir "$orch_plugin" --agents "$out/agents.json")
  else
    prompt="Use the igiari-tdd skill to implement this kata in Java, in the Maven
project in the current directory. JUnit 5 and Vavr are already in the pom.

$(cat "$plan")

The test plan above is approved as-is: do not wait for approval, run every
cycle straight through to the end, then the final full build and the audit
the skill describes (the task started at commit $base). Commit each step as
the skill says. There is no IDE attached; use Maven."
    plugin_args=(--plugin-dir "$plugin")
  fi
  (cd "$dir/work" && git config user.email kata@example.com && git config user.name kata &&
    claude -p "$prompt" "${plugin_args[@]}" --model "$model" \
      --allowedTools "Bash Edit Write Read Glob Grep Skill${orch:+ Agent Task}" \
      --max-turns "$max_turns" --max-budget-usd "$budget" \
      --output-format json > "$dir/result.json" 2> "$dir/stderr.txt")
  cost=$(python3 -I -c "import json,sys; print(round(json.load(open(sys.argv[1])).get('total_cost_usd',0),3))" "$dir/result.json" 2>/dev/null || echo "?")
  spawns=
  if [ -n "$orch" ]; then
    # By the run's own project folder, not its session id: a run started from
    # inside a Claude Code session inherits that session's id, so two runs
    # share one id and an id-based glob counts the first run's agents twice.
    proj=$(python3 -I -c "import re,sys; print(re.sub(r'[^A-Za-z0-9]', '-', sys.argv[1]))" "$(cd "$dir/work" && pwd -P)")
    spawns=$(ls "$HOME/.claude/projects/$proj"/*/subagents/*.jsonl 2>/dev/null | wc -l)
  fi
  ahead_args=()
  [ -z "$gen_from" ] || ahead_args=(--generalize-from "$gen_from"
    --ahead-cmd "$pmd check -d src/main -R $repo/skills/igiari-tdd/scripts/generalization-pmd.xml -f text --no-progress --no-cache")
  (cd "$dir/work" && bash "$repo/skills/igiari-tdd/scripts/audit-tdd-history.sh" --base "$base" \
    --test-cmd "mvn -o -B -q --no-transfer-progress test" \
    --lint-cmd "$pmd check -d src/main -R $repo/skills/igiari-tdd/scripts/super-green-pmd.xml -f text --no-progress --no-cache" \
    --sites-cmd "$pmd check -d src/main -R $repo/skills/igiari-tdd/scripts/iterating-methods-pmd.xml -f text --no-progress --no-cache" \
    "${ahead_args[@]}") > "$dir/audit.txt" 2>&1
  audit=$?
  greens=$(grep -cE '^green [0-9]+ +prod' "$dir/audit.txt")
  lint=$(grep '^lint total' "$dir/audit.txt" | sed 's/^lint total: //')
  blame=$(sed -n '/possible super-green misses/{n;p}' "$dir/audit.txt")
  ahead=$(grep '^ahead total' "$dir/audit.txt" | sed 's/^ahead total: //')
  sites=$(grep '^sites total' "$dir/audit.txt" | sed 's/^sites total: //')
  echo "$kata${baseline:+ (baseline)}${orch:+ ($orch)} #$i${orch:+  subagents $spawns}  cost \$$cost  greens $greens  audit exit $audit  lint: ${lint:-n/a}  ahead: ${ahead:-n/a}  refactor-adds: ${sites:-n/a}  blame:$blame"
done
