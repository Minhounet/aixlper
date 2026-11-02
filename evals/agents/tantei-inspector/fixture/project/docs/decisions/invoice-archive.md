## Resume
- Mode: build
- Done: AC1, AC2, AC3
- Next: none
- Files: docs/ticket/PROJ-12/, InvoiceArchiver

## AC1 - archive paid invoices
- Decided: `InvoiceArchiver` use case, `ArchiveStore` interface
- Why: structural plan
- Rejected: -
- Asked user: no

## AC2 - field name for the archive date
- Decided: `archivedOn`
- Why: user chose between `archivedOn` and `archiveDate`
- Rejected: `archiveDate`
- Asked user: yes

## AC3 - archive when the invoice state changes
- Decided: a Nuxeo event listener on `lifecycle_transition_event`, by hand
- Why: No skill: Nuxeo listener
- Rejected: a scheduler polling every hour
- Asked user: no

## AC3 - upgrade the Gradle wrapper
- Decided: wrapper 8.10, by hand
- Why: No skill: Gradle wrapper upgrade
- Rejected: staying on 8.5
- Asked user: no
