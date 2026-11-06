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
| `mokugeki-tester` | `fixture/`: a static Documents screen served on a local port, four ACs (M1–M3 traps, M4 control) | M1 `HUMAN` (native tooltip), M2 and M3 `FAIL`, M4 `PASS`; no fixed sleeps; nothing changed outside `checks/`. Not run yet |
| `tantei-inspector` | `fixture/project/`: decision logs, a retro, process notes (T1–T4 planted, X1–X2 decoys) | A proposal per planted item, with quoted evidence; none from a decoy; no deletion; nothing changed on disk |

`shonin-dev` is measured differently, by the kata it writes greens for:
`scripts/kata_super_green.sh --orchestrator dev|nodev` (results in
`katas/igiari-tdd/README.md`).

## Results

### 2026-11-02, Sonnet, 2 runs each

**`kenji-reviewer`: 4/4 planted defects, both runs, all `blocking`**
(about $0.27 a fixture). Each finding named the right skill rule: D1 and D2
as rule 5 (over-built green, so red 3 never failed, confirmed by running the
audit), D3 as rule 6 plus "no AC asked for it", D4 as objection-conception's
"a test that passed on arrival is not evidence". Nothing changed on disk.

On `clean` it raised one `blocking` finding both times, and **it was
right**: the fixture's green 3 answered `add("1,2")` with a split-and-sum
pipeline, which is `igiari-tdd`'s own "Over-built" rung for that exact
moment. The fixture was wrong, not the reviewer; `clean` now uses the
skill's "Super" rung (two operands, no loop).

The next two clean re-runs found two more real flaws, each time correctly:
AC2 said "one or more numbers" while its interpretation and code stopped at
two (`add("1,2,3")` returned 3), and then, once the fixture said "one or
two", the runner's prompt still quoted the old wording (a misquoted source).
Test names outside `igiari-tdd`'s `should…_when…` rule and a field-built test
object (the author's `@BeforeEach` rule) were rightly flagged as minor. All
fixed.

**Final clean run (2 runs): 0 blocking.** One `AC2: PASS`; one with a single
`minor`, also correct (`igiari-tdd`'s own ladder names extracting
`parseOperand()` as honest refactor work there, and no refactor ran).

So across 8 reviews: every planted defect found as `blocking` (4 runs), and
no false alarm once the control really was clean. The lesson is for whoever
builds the next fixture: a control written by hand is not clean until the
reviewer agrees, and it took four tries.

**`tantei-inspector`: 4/4 planted items, both runs, 0 decoys proposed**
(about $0.22 a run). Each proposal quoted its evidence and gave exact
old → new wording; both decoys were named as one-offs and explicitly not
proposed; no deletion; nothing changed on disk. Both runs also made a fifth,
unplanted proposal that holds: `igiari-tdd` (44KB) and `chottomatte-archi`
(33KB) are far past the repo's ~20KB line, with a token audit left to the
author.

One real flaw, both runs: **line numbers in the evidence are wrong** when it
read several files at once (`login-lock.md:43` in a 17-line file); within a
single file they are right. The quotes are exact. The first summary also
counted both decoys as hits: keyword noise from the "not proposed" lines,
fixed in the runner (a decoy now counts only when a proposal is about it).

### 2026-11-02, tantei-inspector line numbers

Fix: one line in `tantei-inspector.md` (cite by each file's own numbering,
never a concatenation). Checked over 4 runs: 3 cited every line correctly;
one still read all the evidence with a single `cat` and numbered the
combined output. So `improve.md`'s report shape now makes the verbatim
quote the evidence, and a line number optional, only from that one file.
That second change is not re-run yet. All 4 runs still found T1–T4 and
proposed nothing from the decoys.
