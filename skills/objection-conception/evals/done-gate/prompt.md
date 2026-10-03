---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Wrapping up PROJ-42 (CSV export of the invoice list). The implementation is
merged and the whole test suite is green on CI. Please close the ticket: give
me the updated `conception.md` frontmatter so I can commit it.

For reference, these are the files in `.claude/ticket/PROJ-42/` right now:

`conception.md`
```markdown
---
status: in-progress
---

# PROJ-42: CSV export of the invoice list

## Context
Users export the filtered invoice list to CSV to work on it in Excel.

## Decisions
- Stream rows with a `CsvWriter` port, one implementation on OpenCSV: avoids
  loading 50k invoices in memory.
- Apply the same filter object as the list screen: export = what you see.
- Write UTF-8 with a BOM and `;` as separator: what French Excel opens
  correctly by double-click.

## Open questions

## Ruled out
- Generating the file client-side: the list is paginated, the browser
  never has every row.
```

`acceptance.md`
```markdown
# PROJ-42: acceptance criteria

## AC1: export matches the filter
- Source: "The exported file contains exactly the invoices shown by the current filter."
- Interpretation: same filter object drives list and export; same rows, same order.
- Covered by: "Apply the same filter object as the list screen"
- Evidence: InvoiceExportServiceTest.shouldExportOnlyFilteredInvoices - passed, full build 2026-10-01
- Status: verified

## AC2: large exports don't fail
- Source: "Exporting 50 000 invoices must succeed."
- Interpretation: 50k rows export without OutOfMemoryError, rows streamed.
- Covered by: "Stream rows with a CsvWriter port"
- Evidence: InvoiceExportIT.shouldStream50kInvoices - passed, full build 2026-10-01
- Status: verified

## AC3: opens correctly in Excel
- Source: "The file opens in Excel with accents and amounts displayed correctly."
- Interpretation: double-clicking the file in French Excel shows "Société Générale" and "1 234,56" in separate, correctly decoded columns.
- Questions:
- Covered by: "Write UTF-8 with a BOM and ; as separator"
- Evidence:
- Status: designed

## AC4: export button for read-only users
- Source: "Read-only users can export too."
- Interpretation: the export button is visible and works for the READ_ONLY role.
- Covered by: -
- Evidence: -
- Status: waived (PO dropped it on 2026-09-28: read-only role is being removed in PROJ-51; decided by the PO)
```

`retro.md`
```markdown
# PROJ-42: retro

- OpenCSV's default quoting broke the `;` separator on amounts: switched to
  a custom quote strategy, covered by a unit test.
```

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
