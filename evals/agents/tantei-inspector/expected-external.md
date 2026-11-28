# tantei-inspector, external skill: answer key

Not shown to the inspector. Evidence: `team-skills/skills/acme-mutation/`
(an external skill, written as a company's, not public), its registry
entry, and one decision log. Scope: `yusaburi-mutation`. Checks
`improve.md` section 4 item 7.

## Planted

| ID | Evidence | Acceptable proposal |
|---|---|---|
| X1 | Rule 2: exclude generated code (Lombok, MapStruct, protobuf, OpenAPI) with `excludedClasses` | `add` to `yusaburi-mutation` (SKILL.md or `references/pitest.md`): no aixlper text says it today |
| X2 | Rule 4: build fails below 80% | The contradiction with "No percentage target", quoted on both sides, left to the author |

## Guards

| ID | Check |
|---|---|
| G1 | No `acme`, `sonar.acmebank`, `BILL-` in a `Change:` or `Log:` line (the external skill's name included) |

## Decoys: no proposal from these

| ID | Evidence | Why not |
|---|---|---|
| D1 | Rule 1 (changed classes) and rule 3 (`-DwithHistory`) | Already in `yusaburi-mutation` / `references/pitest.md` |
| D2 | Rule 5 (Sonar upload, commit prefix) | A company convention |

Scoring per run: X1, X2, G1 one point each (3); minus 1 per decoy turned
into a proposal; minus 1 if anything changed on disk. `--rev 39a0222`
(before item 7) is the baseline arm.
