# External skills: use skills from outside aixlper as reinforcement

Read this when a skill that isn't an aixlper skill is about to be used in
the pipeline: one from the skill list fits a step, or the user names one.
Never at startup: the skill list already shows installed skills and their
descriptions, so nothing needs reading until one is about to be used.

An external skill is any skill not in this repo that the user wants
in the pipeline: a team or company skill, a marketplace skill, or a skill
from the user's own account (`dev-research-doc-officielle` was the first). It
reinforces the aixlper pipeline: it adds to a step or fills a gap. It never
removes a gate, a review or a proof.

## The registry is private, and read only now

Read `~/.claude/external-skills.md` now, not before: it says the skill's
role and what to do on a conflict. No entry, or no file: use the skill as
**reinforces** with **ask**, and offer the user an entry at the end.

The registry is on the user's machine, never
in the aixlper clone: this repo is public, and a company skill's name,
purpose or rules can be internal. Never copy an entry, a name or a rule from
it into the clone; improve mode learns from external skills only through its
guards (`improve.md`, item 7).

## Entry shape

One section per skill. The user writes it; you only propose entries.

```
## <skill name, as the skill list shows it>
Source: <install name or plugin, or the path of its SKILL.md>
For: <what it is for, one or two lines>
When: <the condition that loads it: a mode, a kind of work, a project path>
Role: reinforces <aixlper skill> | fills <kind of work> | replaces <aixlper skill> in <project path>
On conflict: external | aixlper | ask   (default: ask)
```

- **reinforces**: loaded together with that aixlper skill, at the same
  point in the pipeline.
- **fills**: loaded for a kind of work no aixlper skill covers. Before
  logging `No skill:`, look at the skill list (not the registry): a skill
  that fits means no `No skill:` line.
- **replaces ... in ...**: in that project only, the external skill takes
  the aixlper skill's row (a team mandates its own skill on its own code).
  The mode's gates, reviews and proofs stay; only the rules for that step
  change. Never outside the named path.

## Using one

- Load it by name like an aixlper skill, and read it in full: same rule as
  the pipeline, never paraphrased from memory. Give its name or path to every
  helper you spawn for the step, as with an aixlper skill.
- Log it in the decision entry: `External: <name> (<role>)`.
- **Conflict** (both skills give a rule for the same thing, and the rules
  differ): quote both verbatim and follow `On conflict`. With `ask`, it is a
  gate: give the two quotes and a recommendation. A project rule (naming,
  tooling, compliance, layout) usually wins over an aixlper style rule; a
  process rule of the pipeline (a gate, one test at a time, a proof)
  doesn't give way unless the user says so. Log the answer and propose an
  `On conflict` value for the entry, so the same question isn't asked twice.
- An external skill that the skill list doesn't show and whose `Source`
  path isn't readable: say so once and go on without it. Never guess its
  content.
