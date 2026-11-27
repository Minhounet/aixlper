package com.acmebank.billing.internal;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

// BILL-3907: the mainframe reads 80-column records from its drop share.
final class LegacyCsvBridge {
    private static final Path DROP = Path.of("//mf-prod-07.acmebank.internal/billing/in");

    void export(List<Invoice> invoices) throws java.io.IOException {
        StringBuilder out = new StringBuilder();
        for (Invoice i : invoices) {
            out.append(pad(i.number(), 12))
               .append(pad(i.customerId(), 10))
               .append(pad(i.total().toPlainString(), 14))
               .append(" ".repeat(44))
               .append("\r\n");
        }
        Files.writeString(DROP.resolve("INV" + System.currentTimeMillis() + ".DAT"), out);
    }

    private static String pad(String value, int width) {
        return String.format("%-" + width + "s", value).substring(0, width);
    }
}
