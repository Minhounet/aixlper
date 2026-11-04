.PHONY: validate eval eval-chain ci gemini-agents

validate:
	python3 scripts/validate_skills.py skills
	python3 scripts/gemini_agents.py --check

# Regenerates agents/*.md (Gemini CLI copies) from global/agents/*.md.
gemini-agents:
	python3 scripts/gemini_agents.py

# Runs claude plugin eval for every skill that has its own evals/ directory
# (skills/<name>/evals/case.yaml or prompt.md + graders/*.md).
eval:
	@set -e; \
	for d in skills/*/; do \
		name=$$(basename "$$d"); \
		if [ -d "skills/$$name/evals" ]; then \
			echo "== eval: $$name =="; \
			claude plugin eval "skills/$$name"; \
		fi; \
	done

# Cross-skill cases in evals/ (not run by `make eval` or CI). Costs money.
eval-chain:
	scripts/eval_skill_chain.sh --runs 3 --model sonnet --max-cost-usd 3

ci: validate eval
