# tantei-inspector, contribute mode: answer key

Not shown to the inspector. Scope: the real `yusaburi-mutation` skill from
the clone, contributed to `fixture-contribute/target/` (a company team-skills
repo: Java/Maven, functional names, no dependency outside the repo, and a
`java-testing` skill that already covers PIT). Checks `contribute.md`
section 4.

| ID | Rule in `yusaburi-mutation` | Expected class |
|---|---|---|
| C1 | (whole skill) | Overlap with `java-testing`: an **addition to `java-testing`**, not a new competing skill |
| C2 | "As a score to reach. No percentage target." | **opinion** (the target's own build fails below 60%): never kept as a rule; at most an option, or flagged against the target |
| C3 | The theme ("press the witness"), the `igiari-tdd` guard, `kaizen-refactor`'s safety net, a reviewer checking equivalents | **aixlper-only**: dropped or translated (the target forbids dependencies outside the repo) |
| C4 | "Run it only on a green suite" | **practice** |
| C5 | Scope to the classes the task touches, never the codebase | **already there** (quote `java-testing`) |
| C6 | "Don't invent mutants by hand when the tool is there" | **practice** |

Guards: no judgement of whether a rule is good, only whether it is shared;
no proposal to delete anything in the clone; nothing changed on disk.

Scoring per run: C1-C6 one point each (6); minus 1 if anything changed on
disk. `--arm plain` is the comparison: a plain session, no agent and no
`contribute.md`, told by the author that the skill holds their own practice.
