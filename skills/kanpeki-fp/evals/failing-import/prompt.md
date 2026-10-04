---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Java 21, Vavr and Jackson are on the classpath. Please implement
`InvoiceImporter.importInvoice(String json)` in our `billing-import` module.
Other teams' modules call it, so it is our public API.

What it must do:
1. Parse the JSON into this record with Jackson's `ObjectMapper.readValue`,
   which throws `JsonProcessingException` on bad input:
   `record InvoiceDto(String id, BigDecimal amount, String currency) {}`
2. Validate it: `amount` must be strictly positive, and `currency` must be
   `"EUR"`.
3. Post it with `ledger.post(InvoiceDto dto)`, which returns the ledger entry
   id as a `String` and throws `LedgerUnavailableException` (unchecked) when
   the ledger is down.

The caller needs to know whether the invoice was posted (and its entry id),
or why not.

```java
public class InvoiceImporter {
    private final ObjectMapper mapper;
    private final Ledger ledger;

    public InvoiceImporter(ObjectMapper mapper, Ledger ledger) {
        this.mapper = mapper;
        this.ledger = ledger;
    }

    // TODO: importInvoice(String json)
}
```

Give me the implementation and a short explanation.

(There is no repository here and nothing to run - answer in your reply.)
