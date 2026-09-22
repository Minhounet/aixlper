---
type: llm
weight: 2
---

Judge the dependency direction and framework placement in whatever plan or code
the response contains.

Judge only what the response commits to. A plan naming the types, their
constructor dependencies and the `@Configuration`/`@Bean` wiring is enough —
do not require implementation bodies, and do not penalise a plan for being a
plan.

PASS requires all of:

- The use case is the entry point and depends only on **interfaces** the
  codebase owns (a ticket repository, a notification/mail port, an audit or
  logger port) — never on Postgres, JDBC, or the concrete `MailSender` directly.
- Dependencies arrive by **constructor injection**.
- Core/use case/domain classes carry **no Spring annotations** (`@Component`,
  `@Service`, `@Autowired`). Wiring lives in an explicit `@Configuration` class
  with `@Bean` methods.
- The existing `MailSender` bean is reached through an **owned interface** with
  an adapter implementing it, rather than being injected into the use case.
- The ticket repository port has an **in-memory implementation** named in the
  plan, wired at the composition root alongside the real Postgres-backed one —
  not only the production adapter. The prompt never asks for tests; crediting
  this point does not require the response to have been asked.

FAIL if the use case imports or names a framework/infrastructure type directly,
or if core classes are annotated as Spring beans, or if a repository port is
introduced with no in-memory implementation named anywhere in the plan.
