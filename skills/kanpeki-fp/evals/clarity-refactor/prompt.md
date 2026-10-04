---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Java 21, Vavr is on the classpath. This method works but it's long and hard
to follow. Please refactor it so it's clearer. `InvoiceSummaryServiceTest`
calls `summarize(...)` directly and must stay green; other modules call it
too. `Delivery` is a sealed interface with three records: `Express(BigDecimal
weight, int hours)`, `Standard(BigDecimal weight)` and `Pickup()`.
`CustomerRepository.findById` and `loadDefaultCustomer` are remote calls.

```java
public class InvoiceSummaryService {
    private static final BigDecimal EXPRESS_RATE = new BigDecimal("2.5");
    private static final BigDecimal STANDARD_RATE = new BigDecimal("1.2");
    private static final BigDecimal LARGE = new BigDecimal("10000");
    private static final Logger log = LoggerFactory.getLogger(InvoiceSummaryService.class);

    private final CustomerRepository customers;

    public InvoiceSummaryService(CustomerRepository customers) {
        this.customers = customers;
    }

    public String summarize(List<Invoice> invoices, String customerId) {
        Customer customer = findCustomer(customerId);
        if (customer == null) {
            customer = customers.loadDefaultCustomer();
        }
        BigDecimal total = BigDecimal.ZERO;
        List<String> lines = new ArrayList<>();
        for (Invoice inv : invoices) {
            if (inv.status() != Status.CANCELLED && inv.amount().signum() > 0) {
                BigDecimal fee;
                if (inv.delivery() instanceof Delivery.Express e) {
                    fee = e.weight().multiply(EXPRESS_RATE)
                        .add(BigDecimal.valueOf(e.hours() < 24 ? 10 : 5));
                } else if (inv.delivery() instanceof Delivery.Standard s) {
                    fee = s.weight().multiply(STANDARD_RATE);
                } else {
                    fee = BigDecimal.ZERO;
                }
                BigDecimal lineTotal = inv.amount().add(fee);
                total = total.add(lineTotal);
                lines.add(inv.id() + ": " + lineTotal);
                log.debug("counted invoice " + inv.id());
            }
        }
        String label;
        if (total.compareTo(LARGE) > 0) {
            label = "large";
        } else if (total.signum() == 0) {
            label = "empty";
        } else {
            label = "normal";
        }
        return customer.name() + " [" + label + "] " + String.join(", ", lines)
            + " total=" + total;
    }

    private Customer findCustomer(String id) {
        Optional<Customer> c = customers.findById(id);
        return c.isPresent() ? c.get() : null;
    }
}
```

Give me the refactored class and a short explanation.

(There is no repository here and nothing to run - answer in your reply.)
