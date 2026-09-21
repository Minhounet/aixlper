---
type: llm
weight: 3
---

Judge against two rules about what crosses the boundary.

PASS requires both:

- The repository returns the **domain object itself** (a `Customer`), not a
  primitive, a `String`, or a narrow partial projection per caller. The
  existing `findCustomerNameById` returning `String` is called out as the
  problem, and adding a second projection method is rejected.
- The use case does **not** return the domain entity to its caller. It builds
  its own `Response` object via an explicit mapper — one mapper per domain
  type, reused in both directions as needed.

Naming the input type `Command`, `Query` or `Request` is consistent with the
skill and should be credited, not penalized.

FAIL if the answer keeps returning primitives from the repository, adds a
per-use-case projection method, or hands the `Customer` entity straight back
out of the use case as the response.
