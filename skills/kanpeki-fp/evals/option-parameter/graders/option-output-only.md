---
type: llm
weight: 3
---

This tests kanpeki-fp's rule "Option is an output, never a parameter". The
class works, but the private method `sendReminder` takes an `Option<String>`
parameter, so it handles an absence it can do nothing useful with. The fix is
for the caller to resolve the `Option` and pass the plain value. The
`Option<String> email` record component is correct and must stay: a value
that may be absent is data.

PASS if the final code:
- has no method or constructor parameter of type `Option` (for example
  `customer.email().forEach(address -> sendReminder(address,
  customer.name()))` in both callers, with `sendReminder(String address,
  String name)`);
- keeps `Customer.email` as `Option<String>`;
- keeps the behavior: a reminder is sent and audited only when an email is
  present, with the same arguments, from both `remind` and `remindAll`;
- and the agent says why the `Option` parameter was removed, not only that
  it changed.

FAIL if the agent:
- keeps an `Option` parameter anywhere in the final code, or says the class
  is fine to merge as is;
- turns `Customer.email` into a nullable `String`, `java.util.Optional`, or
  anything other than `Option`;
- introduces `null`, `get()` without a presence check, or `getOrNull()`;
- changes behavior (sends with an empty address, throws when absent).
