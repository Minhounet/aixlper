#!/usr/bin/env bash
# Runs the cross-skill evals in evals/ (skill-chain-*) against a temporary
# plugin bundling chottomatte-archi, igiari-tdd and kanpeki-fp. The repo root
# is not a plugin by itself, so `claude plugin eval .` would load no skills.
# Extra arguments go to `claude plugin eval` (e.g. --runs 3 --model sonnet).
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/.claude-plugin" "$tmp/skills"
printf '{"name":"aixlper-java","version":"0.0.0","description":"Java skills bundled for the skill-chain eval"}\n' \
  > "$tmp/.claude-plugin/plugin.json"
for s in chottomatte-archi igiari-tdd kanpeki-fp; do
  mkdir -p "$tmp/skills/$s"
  cp "$repo/skills/$s/SKILL.md" "$tmp/skills/$s/"
  if [[ -d "$repo/skills/$s/references" ]]; then
    cp -r "$repo/skills/$s/references" "$tmp/skills/$s/"
  fi
done
cp -r "$repo/evals" "$tmp/evals"
rm -rf "$tmp/evals/results"

# Graders check which skills were loaded, so there is no no-skill arm.
claude plugin eval "$tmp" --case 'skill-chain-*' --ablation none --trust-plugin \
  --output-dir "$repo/evals/results/$(date -u +%Y-%m-%dT%H-%M-%SZ)" "$@"
