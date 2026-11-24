# Delegated run

> Reference for the `igiari-tdd` skill. Read only when the author asks for
> a delegated run and the client can spawn a subagent, after the plan is
> approved.

Off by default. Use it when the author asks for it and the client can spawn
a subagent; otherwise run the cycle inline. It starts only **after**
the plan is approved: hand one agent the path to SKILL.md and the approved
plan verbatim, and it runs every cycle and the final build. Run it in the
**foreground** (the author waits, your context stays clean) or the
**background** (the author keeps working meanwhile).

- **Same commits as inline:** one per step, as in SKILL.md's "The cycle".
- **A deviation stops the run:** the agent returns `DEVIATION: <cycle, what,
  proposal>`, you put it to the author, and you resume the same agent.
- **You run the audit yourself before reporting done**, because the
  report is never the evidence: `scripts/audit-tdd-history.sh` (see SKILL.md's "The cycle"),
  then read each green diff against rule 5.

