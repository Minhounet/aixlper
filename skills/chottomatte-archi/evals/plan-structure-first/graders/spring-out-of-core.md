---
type: llm
weight: 2
---

Judge the dependency direction and framework placement in whatever plan or code
the response contains.

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

FAIL if the use case imports or names a framework/infrastructure type directly,
or if core classes are annotated as Spring beans.
