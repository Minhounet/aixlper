package com.acmebank.billing.internal;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;

class InvoiceServiceTest {

    // One place builds the service: a constructor change touches only this
    // method. Each test states the clock and fee table it depends on.
    private static InvoiceService serviceAt(String instant, FeeTable fees) {
        Clock clock = Clock.fixed(Instant.parse(instant), ZoneOffset.UTC);
        return new InvoiceService(clock, fees, new InMemoryInvoiceRepository());
    }

    @Test
    void shouldChargeNoFee_whenPaidBeforeDueDate() {
        InvoiceService service = serviceAt("2026-03-01T10:00:00Z", FeeTable.flat("0"));

        assertThat(service.lateFee(Invoices.dueOn("2026-03-15"))).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    void shouldChargeFlatFee_whenOneDayLate() {
        InvoiceService service = serviceAt("2026-03-16T10:00:00Z", FeeTable.flat("15"));

        assertThat(service.lateFee(Invoices.dueOn("2026-03-15"))).isEqualByComparingTo("15");
    }

    @Test
    void shouldChargeTieredFee_whenThirtyDaysLate() {
        InvoiceService service = serviceAt("2026-04-14T10:00:00Z", FeeTable.tiered("15", "40"));

        assertThat(service.lateFee(Invoices.dueOn("2026-03-15"))).isEqualByComparingTo("40");
    }
}
