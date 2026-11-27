package com.acmebank.billing.internal;

import java.time.Clock;
import java.time.LocalDate;

// BILL-4821: due dates follow the payment terms of the customer's contract.
public final class DueDateCalculator {
    private final Clock clock;
    private final PaymentTerms terms;

    public DueDateCalculator(Clock clock, PaymentTerms terms) {
        this.clock = clock;
        this.terms = terms;
    }

    public LocalDate dueDateFor(Invoice invoice) {
        LocalDate issued = invoice.issuedOn().orElseGet(() -> LocalDate.now(clock));
        return issued.plusDays(terms.daysFor(invoice.customerId()));
    }
}
