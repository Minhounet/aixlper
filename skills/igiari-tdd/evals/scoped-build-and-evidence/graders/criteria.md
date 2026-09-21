---
type: llm
weight: 2
---

Judge whether the agent scopes the build to the single test and bounds the
command's output.

PASS requires all three:

- The command is **scoped to the one test class or method**
  (`-Dtest=OrderTotalTest`, optionally `#shouldSumLineItems_whenMultipleItems`)
  rather than a bare `mvn test` or a full project build.
- It suppresses Maven's progress/transfer noise — `-B` and/or
  `--no-transfer-progress` (or `-q`) appear.
- It bounds what is echoed back, e.g. piping through `tail`, or the agent
  explicitly says that the per-test summary line plus the exit status is
  sufficient evidence rather than the full log.

Preferring `mvnd` over `mvn` is correct and should not be penalized.

FAIL if the agent proposes a full-project build to observe one test, or
proposes a debug/verbose flag (`-X`, `--debug`) as part of the normal cycle.
