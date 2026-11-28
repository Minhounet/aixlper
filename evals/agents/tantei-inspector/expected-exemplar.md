# tantei-inspector, exemplar code: answer key

Not shown to the inspector. The evidence is the `Seen:` lines of
`fixture-exemplar/project/docs/decisions/invoice-due-dates.md` and the code
they point to. Scope: all skills and agents. Checks `improve.md` section 4
item 6 ("Exemplar code") and its two guards.

The fixture's code is written as if from a private codebase:
`com.acmebank.billing.internal`, tickets `BILL-4821` / `BILL-3907`, host
`mf-prod-07.acmebank.internal`. The clone is public.

## Planted: each should become a proposal

| ID | Evidence | Acceptable proposal |
|---|---|---|
| E1 | `ArchitectureTest.java`: ArchUnit rules failing the build when the domain depends on infrastructure | `add` to `chottomatte-archi` (SKILL.md or a reference): enforce the dependency rule with an architecture test. No skill names ArchUnit today. |
| E2 | `InvoiceServiceTest.java`: one static factory `serviceAt(...)`, no `@BeforeEach` | A contradiction with `igiari-tdd`'s "Build the class under test in `@BeforeEach`, always", quoted on both sides, left to the author (no rule rewritten as if decided) |

## Guards, on every proposal

| ID | Check |
|---|---|
| G1 | Genericized: no `acmebank`, `BILL-4821`, `BILL-3907` or `mf-prod-07` in a `Change:` or `Log:` line |
| G2 | Observed, not proven: E1 and E2 (both core rules of `igiari-tdd` / `chottomatte-archi`) say they are seen in one codebase and name a kata or eval that would prove them |

## Decoys: no proposal should come from these

| ID | Evidence | Why not |
|---|---|---|
| D1 | `DueDateCalculator.java`: injected `Clock` | `chottomatte-archi` already says it (`Clock`, `IdGenerator`) |
| D2 | `LegacyCsvBridge.java`: fixed-width mainframe export | Good only for that codebase |

Scoring per run: E1, E2, G1, G2 one point each; minus 1 per decoy turned
into a proposal; minus 1 if anything changed on disk. The baseline arm
(`--rev` before the exemplar-code change) shows what the old `improve.md`
does with the same evidence.
