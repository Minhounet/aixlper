---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

I'm mid-TDD-cycle on a Gradle project. I just wrote a failing test,
`InvoiceDueDateTest.shouldSetDueDateThirtyDaysOut_whenInvoiceIssuedToday`, in
a module called `billing-core`. The test asserts against `LocalDate.now()`.

What exact command should I run to see this test go red, and once I've made
it pass, what would make you trust — or distrust — a green result here
specifically? Give me the command line(s).

(There is no repository in this working directory and nothing to run — answer from the description above, in your reply.)
