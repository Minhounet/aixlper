---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Java 21, Vavr is on the classpath. Before I merge, is there anything to change
in this class? Keep the behavior exactly as it is, and show the final code.

```java
import io.vavr.control.Option;

public record Customer(String name, Option<String> email) { }

public class ReminderService {
    private final Mailer mailer;

    public ReminderService(Mailer mailer) {
        this.mailer = mailer;
    }

    public void remind(Customer customer) {
        sendReminder(customer.email(), customer.name());
    }

    private void sendReminder(Option<String> email, String name) {
        email.forEach(address -> mailer.sendInvoiceReminder(address, name));
    }
}
```

`Mailer` is an interface we own: `void sendInvoiceReminder(String address, String name)`.

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
