# Agent evals

`claude plugin eval` scores skills, not agents, so each helper agent in
`global/agents/` is tested here on a fixture whose right answer is known: run
it headless under its real definition, then compare its report with the
answer key. Run with `scripts/eval_agent.sh --agent <name>`; the summary line
gives keyword hints, and the score comes from reading `answer.md` against
`expected.md`.

| Agent | Fixture | What a good run does |
|---|---|---|
| `kenji-reviewer` | `make-fixture.sh`: a kata history, `clean` and `defects` (D1–D4 planted) | PASS on `clean`; all four defects `blocking` on `defects`; nothing changed on disk |
| `tantei-inspector` | `fixture/project/`: decision logs, a retro, process notes (T1–T4 planted, X1–X2 decoys) | A proposal per planted item, with quoted evidence; none from a decoy; no deletion; nothing changed on disk |

`shonin-dev` is measured differently, by the kata it writes greens for:
`scripts/kata_super_green.sh --orchestrator dev|nodev` (results in
`katas/igiari-tdd/README.md`).

## Results

None yet.
