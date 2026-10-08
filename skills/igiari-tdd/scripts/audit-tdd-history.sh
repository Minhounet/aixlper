#!/usr/bin/env bash
# Audit a TDD task from its git history, per igiari-tdd's commit-per-step rule.
#
# Each step is one commit whose subject contains "red N", "green N" or
# "refactor N" (any prefix the project's convention needs is fine).
# Checks, without touching the current checkout (uses a temporary worktree):
#   - steps come in order: red N, green N, optional refactor N, then N+1
#   - each red commit adds exactly one test and changes only test files
#     (a stub in production code is allowed and flagged for reading)
#   - no green commit touches a test file (rule 9)
#   - re-run at each red commit, the scoped test fails, and not on a
#     compile error (rule 4); the first failure line is printed to judge
#   - the final build passes at the last commit
#   - lists each refactor that rewrites production lines its own green
#     wrote: possible super-green misses, to read (not a violation)
# Rule 5 (minimal green) is a judgment: read the green diffs yourself.
#
# usage: audit-tdd-history.sh --base <rev> [--test-cmd "<scoped test cmd>"]
#          [--full-cmd "<full build cmd>"] [--test-path src/test/]
#          [--main-path src/main/] [--test-marker '@Test|@ParameterizedTest']
#   --base      the commit the task started from (its steps are base..HEAD)
#   --test-cmd  run at each red commit; omit to skip the red re-run
#   --full-cmd  run once at HEAD; omit to skip the final build
# exit 0: clean; 1: a violation; 2: usage error

set -u
base= test_cmd= full_cmd= test_path=src/test/ main_path=src/main/
marker='@Test|@ParameterizedTest'
while [ $# -gt 0 ]; do
  case $1 in
    --base) base=$2; shift 2;;
    --test-cmd) test_cmd=$2; shift 2;;
    --full-cmd) full_cmd=$2; shift 2;;
    --test-path) test_path=$2; shift 2;;
    --main-path) main_path=$2; shift 2;;
    --test-marker) marker=$2; shift 2;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
[ -n "$base" ] || { echo "--base <rev> is required" >&2; exit 2; }
git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "not a commit: $base" >&2; exit 2; }
head=$(git rev-parse HEAD)

fail=0
flag() { fail=1; }
expect_red=1 last_green=0 green_sha= misses=

# Production lines that refactor commit $1 removes or rewrites and that
# green commit $2 wrote, counted with blame on the refactor's parent.
own_green_lines() {
  local c=$1 g=$2 f start len count=0
  for f in $(git diff-tree --no-commit-id --name-only -r "$c" -- "$main_path"); do
    while read -r start len; do
      len=${len:-1}
      [ "$len" -gt 0 ] || continue
      count=$((count + $(git blame -s -l -L "$start,+$len" "$c^" -- "$f" 2>/dev/null |
        grep -c "^$g")))
    done < <(git diff -U0 "$c^" "$c" -- "$f" | sed -nE 's/^@@ -([0-9]+)(,([0-9]+))? .*/\1 \3/p')
  done
  echo "$count"
}

echo "--- steps ($base..HEAD) ---"
for c in $(git rev-list --reverse "$base..HEAD"); do
  subject=$(git log -1 --format=%s "$c")
  files=$(git diff-tree --no-commit-id --name-only -r "$c")
  tests=$(printf '%s\n' "$files" | grep -c "^$test_path")
  mains=$(printf '%s\n' "$files" | grep -c "^$main_path")
  step=$(printf '%s' "$subject" | grep -oE '(red|green|refactor) [0-9]+' | head -1)
  kind=${step% *} n=${step#* }
  verdict=ok
  case $kind in
    red)
      added=$(git show --format= "$c" -- "$test_path" | grep -cE "^\+.*($marker)")
      problems=
      [ "$n" -eq "$expect_red" ] || problems="OUT OF ORDER (expected red $expect_red); "
      [ "$added" -eq 1 ] || problems="${problems}ADDS $added TESTS, want 1; "
      if [ -n "$problems" ]; then verdict=${problems%; }; flag
      elif [ "$mains" -gt 0 ]; then verdict="ok; touches production (stub? read it)"; fi
      ;;
    green)
      problems=
      [ "$n" -eq "$expect_red" ] || problems="OUT OF ORDER (expected green $expect_red); "
      [ "$tests" -eq 0 ] || problems="${problems}RULE 9: green touches tests; "
      [ -z "$problems" ] || { verdict=${problems%; }; flag; }
      last_green=$n expect_red=$((n + 1)) green_sha=$c
      ;;
    refactor)
      [ "$n" -eq "$last_green" ] || { verdict="OUT OF ORDER (refactor $n after green $last_green)"; flag; }
      [ "$tests" -gt 0 ] && verdict="ok; changes tests (must be traced)"
      if [ -n "$green_sha" ] && [ "$mains" -gt 0 ]; then
        own=$(own_green_lines "$c" "$green_sha")
        if [ "$own" -gt 0 ]; then
          verdict="$verdict; rewrites $own line(s) green $n wrote"
          misses="$misses refactor $n ($own),"
        fi
      fi
      ;;
    *) verdict="NOT A STEP COMMIT"; flag;;
  esac
  printf '%-14s prod:%-2s test:%-2s %s\n' "${step:-?}" "$mains" "$tests" "$verdict"
done

echo "--- possible super-green misses (read each: green owns it, or make-room?) ---"
echo "${misses:- none}" | sed 's/,$//'

if [ -n "$test_cmd" ] || [ -n "$full_cmd" ]; then
  wt=$(mktemp -d) || exit 2
  trap 'git worktree remove --force "$wt" >/dev/null 2>&1; rm -rf "$wt"' EXIT
  git worktree add -q --detach "$wt" "$head" || exit 2
fi

if [ -n "$test_cmd" ]; then
  echo "--- reds, re-run at their own commit ---"
  for c in $(git rev-list --reverse "$base..HEAD"); do
    step=$(git log -1 --format=%s "$c" | grep -oE 'red [0-9]+' | head -1)
    [ -n "$step" ] || continue
    git -C "$wt" checkout -q --detach "$c"
    out=$(cd "$wt" && eval "$test_cmd" 2>&1); status=$?
    if [ $status -eq 0 ]; then
      echo "$step: PASSED, not a red"; flag
    elif printf '%s' "$out" | grep -qiE 'COMPILATION ERROR|Compilation failed|cannot find symbol'; then
      echo "$step: COMPILE ERROR, not a valid red (rule 4)"; flag
    else
      reason=$(printf '%s\n' "$out" | grep -m1 -oE 'expected:? ?<[^>]*> but was:? ?<[^>]*>')
      [ -n "$reason" ] || reason=$(printf '%s\n' "$out" |
        grep -m1 -oE '[a-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)*\.[A-Z][A-Za-z0-9_]*(Error|Exception)(: [^[:cntrl:]]{0,80})?')
      echo "$step: fails: ${reason:-<no failure line found, read the output>}"
    fi
  done
fi

if [ -n "$full_cmd" ]; then
  echo "--- final build at HEAD ---"
  git -C "$wt" checkout -q --detach "$head"
  if (cd "$wt" && eval "$full_cmd" >/dev/null 2>&1); then echo "passes"; else echo "FAILS"; flag; fi
fi

exit $fail
