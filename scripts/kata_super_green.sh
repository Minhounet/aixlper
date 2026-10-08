#!/usr/bin/env bash
# Runs an igiari-tdd kata headless and measures super green on its history.
# For each run: a throwaway Maven project, a fresh `claude -p` with the Java
# skills loaded and the kata's plan pre-approved, then audit-tdd-history.sh
# with PMD on the commits it left. Costs real money: bound it with --budget-usd.
#
# usage: kata_super_green.sh --kata <name> [--runs 1] [--model sonnet]
#          [--budget-usd 2] [--max-turns 150] [--out <dir>] [--pmd <pmd bin>]
#   --kata        a file name in katas/igiari-tdd/ without .md
#   --budget-usd  per run, passed to claude --max-budget-usd
#   --pmd         the PMD 7 launcher (default: pmd on PATH)
# Prints one summary line per run; details stay in <out>/<kata>-<n>/.
set -uo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
kata= runs=1 model=sonnet budget=2 max_turns=150 out= pmd=${PMD:-pmd}
while [ $# -gt 0 ]; do
  case $1 in
    --kata) kata=$2; shift 2;;
    --runs) runs=$2; shift 2;;
    --model) model=$2; shift 2;;
    --budget-usd) budget=$2; shift 2;;
    --max-turns) max_turns=$2; shift 2;;
    --out) out=$2; shift 2;;
    --pmd) pmd=$2; shift 2;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
plan="$repo/katas/igiari-tdd/$kata.md"
[ -f "$plan" ] || { echo "no kata: $plan" >&2; exit 2; }
command -v "$pmd" >/dev/null || { echo "PMD not found: $pmd (use --pmd)" >&2; exit 2; }
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

for i in $(seq 1 "$runs"); do
  dir="$out/$kata-$i"
  rm -rf "$dir"; new_project "$dir/work"
  base=$(git -C "$dir/work" rev-parse HEAD)
  prompt="Use the igiari-tdd skill to implement this kata in Java, in the Maven
project in the current directory. JUnit 5 and Vavr are already in the pom.

$(cat "$plan")

The test plan above is approved as-is: do not wait for approval, run every
cycle straight through to the end, then the final full build and the audit
the skill describes (the task started at commit $base). Commit each step as
the skill says. There is no IDE attached; use Maven."
  (cd "$dir/work" && git config user.email kata@example.com && git config user.name kata &&
    claude -p "$prompt" --plugin-dir "$plugin" --model "$model" \
      --allowedTools "Bash Edit Write Read Glob Grep Skill" \
      --max-turns "$max_turns" --max-budget-usd "$budget" \
      --output-format json > "$dir/result.json" 2> "$dir/stderr.txt")
  cost=$(python3 -I -c "import json,sys; print(round(json.load(open(sys.argv[1])).get('total_cost_usd',0),3))" "$dir/result.json" 2>/dev/null || echo "?")
  (cd "$dir/work" && bash "$repo/skills/igiari-tdd/scripts/audit-tdd-history.sh" --base "$base" \
    --test-cmd "mvn -o -B -q --no-transfer-progress test" \
    --lint-cmd "$pmd check -d src/main -R $repo/skills/igiari-tdd/scripts/super-green-pmd.xml -f text --no-progress --no-cache") \
    > "$dir/audit.txt" 2>&1
  audit=$?
  greens=$(grep -cE '^green [0-9]+ +prod' "$dir/audit.txt")
  lint=$(grep '^lint total' "$dir/audit.txt" | sed 's/^lint total: //')
  blame=$(sed -n '/possible super-green misses/{n;p}' "$dir/audit.txt")
  echo "$kata #$i  cost \$$cost  greens $greens  audit exit $audit  lint: ${lint:-n/a}  blame:$blame"
done
