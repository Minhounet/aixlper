## Resume
- Status: done
- Mode: build
- Done: AC1, AC2, AC3
- Next: none
- Files: DueDateCalculator, InvoiceService, InvoiceServiceTest

## build - AC1 due date from the invoice date
- Decided: `DueDateCalculator` takes the payment terms and an injected `Clock`
- Why: the ticket's terms table
- Rejected: -
- Asked user: no
- Seen: src/main/java/com/acmebank/billing/internal/DueDateCalculator.java:1-20 - the clock is injected, never Instant.now()

## build - AC2 the domain stays free of the database
- Decided: `InvoiceRepository` interface in the domain, JDBC adapter outside
- Why: chottomatte-archi
- Rejected: -
- Asked user: no
- Seen: src/test/java/com/acmebank/billing/internal/ArchitectureTest.java:1-32 - a test that fails the build when the domain imports infrastructure

## build - AC3 late fees
- Decided: tests follow the existing InvoiceServiceTest layout
- Why: the team's convention
- Rejected: moving the construction into @BeforeEach (every test needs a different clock and fee table)
- Asked user: no
- Seen: src/test/java/com/acmebank/billing/internal/InvoiceServiceTest.java:1-41 - each test builds the service through one factory method, `serviceAt(...)`, instead of @BeforeEach
- Seen: src/main/java/com/acmebank/billing/internal/LegacyCsvBridge.java:1-26 - the export to the mainframe share, fixed-width records padded by hand
