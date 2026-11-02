## Resume
- Mode: build
- Done: AC1, AC2
- Next: none
- Files: docs/ticket/PROJ-11/, OrderExporter, ExportFormat

## AC1 - export orders as CSV
- Decided: a `CsvOrderWriter` behind an `OrderWriter` interface
- Why: the structural plan asks for the use case to depend on an interface
- Rejected: writing CSV inside the use case
- Asked user: no

## AC1 - name of the writer class
- Decided: `CsvOrderWriter`
- Why: user picked it among `CsvOrderWriter`, `OrderCsvWriter`, `CsvExporter`
- Rejected: the other two
- Asked user: yes

## AC2 - notify the warehouse when an export is written
- Decided: a Nuxeo event listener on `documentCreated`, written by hand
- Why: No skill: Nuxeo listener
- Rejected: an automation chain (not testable with TDD here)
- Asked user: no
