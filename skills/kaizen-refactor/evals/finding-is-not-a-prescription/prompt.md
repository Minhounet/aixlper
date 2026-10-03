---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Cleanup pass on `InvoiceSender` before the sprint ends. I ran the IntelliJ
inspections on it; here's what came back. Please apply the fixes and give me
the full patched class so I can paste it in.

Background in case it matters: since Monday's incident, sending to the tax
authority's gateway gives up after the first failure instead of retrying up
to the configured limit. Still investigating that one.

Inspection results:

```
InvoiceSender.java:14  Field can be converted to a local variable / unused: 'Method 'getMaxRetries()' is never used'
InvoiceSender.java:9   HTTP links are not secure: "http://www.example-tax.gov/schemas/invoice/v2"
InvoiceSender.java:31  'collect(toList())' can be replaced with 'toList()'
InvoiceSender.java:38  'instanceof' followed by cast can be replaced with pattern variable
InvoiceSender.java:44  Chain of 'if' statements on 'invoice.channel()' can be replaced with polymorphism
```

```java
package com.example.billing;

import java.util.List;
import java.util.stream.Collectors;

public class InvoiceSender {

    private static final String INVOICE_NAMESPACE =
            "http://www.example-tax.gov/schemas/invoice/v2";

    private final GatewayClient gateway;
    private final int maxRetries;

    public int getMaxRetries() {
        return maxRetries;
    }

    public InvoiceSender(GatewayClient gateway, int maxRetries) {
        this.gateway = gateway;
        this.maxRetries = maxRetries;
    }

    public void sendAll(List<Invoice> invoices) {
        for (Invoice invoice : invoices) {
            send(invoice);
        }
    }

    List<String> ids(List<Invoice> invoices) {
        return invoices.stream().map(Invoice::id).collect(Collectors.toList());
    }

    void send(Invoice invoice) {
        Object payload = Envelope.wrap(INVOICE_NAMESPACE, invoice);
        try {
            gateway.post(payload);
        } catch (GatewayException e) {
            if (e.getCause() instanceof java.net.SocketTimeoutException) {
                java.net.SocketTimeoutException timeout = (java.net.SocketTimeoutException) e.getCause();
                throw new SendFailedException(invoice.id(), timeout);
            }
            throw e;
        }
        if (invoice.channel().equals("EMAIL")) {
            gateway.notifyByEmail(invoice);
        } else if (invoice.channel().equals("PORTAL")) {
            gateway.publishToPortal(invoice);
        } else if (invoice.channel().equals("PAPER")) {
            gateway.queueForPrint(invoice);
        }
    }
}
```

There are no tests for this class yet. (There is no repository in this
working directory and nothing to run — answer from the description above, in
your reply.)
