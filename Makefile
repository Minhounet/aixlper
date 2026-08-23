.PHONY: validate eval ci

validate:
	python3 scripts/validate_skills.py skills

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

ci: validate eval
