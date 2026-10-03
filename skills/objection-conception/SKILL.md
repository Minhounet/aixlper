---
name: objection-conception
description: Use whenever the user is working from a Jira ticket (or any ticket-based task) and wants to think through the design/conception together before or during implementation - phrases like "let's design TICKET-123", "resume the thinking on PROJ-42", "I have a new ticket, let's figure out the approach", or any mention of a ticket folder under .claude/ticket/<ticketId>/. Also trigger when picking work back up on a ticket that was discussed in an earlier session, and when the user wants to check, clarify, trace or verify a ticket's acceptance criteria ("critères d'acceptation", "AC", "definition of done") at any point - before design, during it, or after implementation. Persists the design conversation and the difficulties hit along the way to disk, inside the ticket's own folder, so that thinking survives past the current session instead of being lost when it ends.
---

# Objection Conception

## Why this exists

A design conversation that only lives in the current session disappears the
moment the session ends or gets compacted. This skill exists to make that
thinking durable: everything decided, and everything that went wrong along
the way, gets written to disk inside the ticket's own folder, incrementally,
as it happens - not reconstructed from memory at the end.

It also keeps the ticket honest against its acceptance criteria: they're
checked before anything is designed, traced through the design, and proven
against the built code before the ticket can be closed.

## Get the ticket ID

Everything below is keyed off a ticket ID (e.g. `TICKET-123`, `PROJ-42`).
Extract it from what the user typed when invoking this skill. Don't rely on
a client-specific argument-passing mechanism to do this for you - this skill
needs to behave the same way regardless of which client is reading it, so
read the ticket ID out of the plain text the same way you'd read any other
detail from a request. If no ticket ID appears anywhere, ask for it before
doing anything else.

## Read what's already there before saying anything

Look in `.claude/ticket/<ticketId>/` before starting any design discussion:

- **Ticket context/requirements** the user has already dropped in that
  folder - read all of it; it's the source of truth for what's being asked.
- **`conception.md`** - if it exists, it's prior design work on this exact
  ticket, possibly from an earlier session. Read it in full and treat it as
  the current state of the design to build on, never as a stale draft to
  discard or silently overwrite.
- **`retro.md`** - if it exists, read it too; a difficulty logged earlier
  may already be relevant to what you're about to discuss.
- **`acceptance.md`** - if it exists, it's the current state of every
  acceptance criterion (see below). Read it in full; a criterion still
  `unclear` there blocks design work that depends on it.

None of these files existing yet just means this is a fresh start for the ticket -
you'll create them as the conversation produces something worth recording.

## Check whether the ticket is already closed

`conception.md` carries a small frontmatter block:

```yaml
---
status: in-progress
---
```

- `status: in-progress`, or the field is missing (including on a
  freshly-created file) - proceed normally.
- `status: done` - stop before changing anything. Tell the user plainly
  that this ticket is marked done, and ask whether you're reopening it or
  this is new follow-up work that deserves its own ticket folder. `done` is
  a deliberate signal that a past session (or the user) considered the
  design work finished; resuming edits without asking would erase that
  signal silently.

## Think it through together

The point of this skill is doing the thinking *with* the user, not for
them. Propose options, surface tradeoffs, ask what they'd prefer - the same
way you would in any real design discussion - rather than disappearing for
a while and returning with a finished conception to approve. Bring in
whatever else is actually relevant (existing architecture rules, related
code, prior tickets) instead of treating the ticket folder as the only
input worth considering.

## Write conception.md incrementally

`conception.md` lives at `.claude/ticket/<ticketId>/conception.md` and
captures the design decisions actually reached - the shape being built,
the approach chosen and why, open questions still unresolved, and
approaches that were considered and ruled out (with the reason).

Write to it as decisions are made, not once at the end of the
conversation. A decision that exists only in the conversation and not yet
on disk is one context-compaction or session-end away from being lost -
avoiding exactly that is the reason this skill exists. The user may also
edit this file by hand between your own writes, since it's meant to be
edited together rather than owned by either side alone - re-read it before
your next edit rather than trusting your last in-memory version of it.

Keep `status: in-progress` while work continues; set it to `status: done`
only once the user confirms the ticket's design (and, typically, its
implementation) is actually finished **and** the acceptance gate below
passes.

**Shape to follow:**

```markdown
---
status: in-progress
---

# TICKET-123: <short title>

## Context
<what the ticket is actually asking for, in your own words>

## Decisions
- <decision>: <why>

## Open questions
- <question still unresolved>

## Ruled out
- <approach considered>: <why it was rejected>
```

## Write retro.md incrementally

`retro.md` lives alongside `conception.md` in the same folder and captures
difficulties, surprises, and friction hit while working the ticket - a
rough spot in the existing code, a requirement that turned out ambiguous
once you dug in, an approach that had to be abandoned partway through,
anything a future reader (including a future session on this same ticket)
would want to know before hitting the same wall.

Add to it as friction actually happens, in the moment - not as a single
summary reconstructed at the end. A difficulty is easiest to describe
accurately right when it happens; a "let me remember everything that went
wrong" pass written afterward tends to lose exactly the details that would
have helped next time.

**Shape to follow:**

```markdown
# TICKET-123: retro

- <what happened>: <why it was a problem, and how it got resolved (or didn't)>
```

## Acceptance criteria: acceptance.md

`acceptance.md` lives alongside `conception.md` and tracks every acceptance
criterion (AC) through three checks: is it clear, is it designed for, is
it proven. Create it on the first trigger for a ticket that has ACs - or
that should have them - and update it as each AC's state changes, like
the other two files.

**Shape to follow:**

```markdown
# TICKET-123: acceptance criteria

## AC1: <short name>
- Source: "<the ticket's own wording, verbatim>"
- Interpretation: <the observable outcome that means it's met>
- Questions: <ambiguity, who must answer it, the answer once given>
- Covered by: <decision(s) in conception.md>
- Evidence: <test name and result / command and result / manual check, by whom>
- Status: unclear | ready | designed | verified | failed | waived (<reason, decided by>)
```

### 1. Before design: check the criteria themselves

Extract every AC from the ticket material, numbered, with its **source
wording kept verbatim** - your reformulation goes in `Interpretation`,
never in place of the original, so a later reader can tell what was asked
from what was understood. Then check each one:

- **Observable** - can you state what would show it passing or failing?
  "The page is fast" isn't; "the search returns in under 2s for 10k
  documents" is.
- **Unambiguous** - does it have exactly one reasonable reading? If two
  readings would lead to different code, it's ambiguous.
- **Testable** - can it be checked by a test, a command, or a concrete
  manual step someone can actually perform?

An AC failing any check is `unclear`: write the question down, say who has
to answer it (the user, the PO, another team), and don't design against it
yet. The user may choose to proceed on an explicit assumption - record it
in `Interpretation` marked as an assumption, and keep the question open.

Then check the set as a whole for **gaps**: error cases, edge cases,
permissions, existing behavior that must not change, non-functional needs
the ticket implies but doesn't state. Propose those as candidate ACs and
let the user decide - never add one silently, since an AC nobody asked for
is scope the ticket never agreed to. A ticket with no ACs at all is itself
the first gap: say so, propose a set, and get it confirmed before design.

### 2. During design: trace every AC to the design

Each `ready` AC must end up covered by at least one decision in
`conception.md`; record which in `Covered by` and move it to `designed`.
Before treating the design as complete, show the trace both ways:

- an AC with no covering decision is a **hole** in the design;
- a decision serving no AC is either necessary plumbing (say why) or
  **scope creep** - raise it, don't absorb it.

If a TDD skill is also loaded, every AC becomes at least one test in its
test plan, named so the link back to the AC is obvious.

If the ticket's ACs change mid-way, update `Source`, drop the affected AC
back to `unclear` or `ready`, re-check what it was covered by, and log the
change in `retro.md`.

### 3. After implementation: prove each AC

For each AC, produce evidence that matches its `Interpretation` - not a
nearby, easier property:

- **Automated** (preferred): a test or command that exercises the AC.
  Actually run it now and record its name and result; a test that exists
  but wasn't run this time isn't evidence. Run only what the ACs need, and
  report failures plus a one-line total rather than the full log.
- **Manual**, when automation isn't reasonable: state the exact steps, and
  have the user perform or confirm them - record who checked and what was
  observed. Don't mark a manual check verified on your own say-so.

Passing evidence → `verified`. Failing → `failed`, with what was observed;
fix it or take it back to the design. A criterion that turned out wrong or
impossible is a conversation with the user, not a quiet reinterpretation -
log it in `retro.md`.

### The done gate

`conception.md` may move to `status: done` only when **every** AC is
`verified` or `waived`. Waiving is the user's decision alone, with the
reason and who decided recorded on the AC - never inferred from silence or
from "good enough". If the user asks to close with anything still
`unclear`, `ready`, `designed` or `failed`, list those ACs and their state
and ask for each to be verified or explicitly waived first.

## Token self-audit

This file loads **in full** whenever the skill triggers and stays resident
for the rest of the session; `references/` files load only if the body
points at one. When asked to reduce token cost — or before adding anything
here — audit in this order and report what you would move, and why:

- **Needed only sometimes?** Material for one framework, one tool's exact
  commands, or a section about extending the skill itself → move to
  `references/` behind a pointer that names the condition precisely.
- **A reference opened on almost every trigger?** Then it costs *more*
  there than inline — a tool call, an extra assistant turn, and a lost
  prefix cache. Bring it back inline.
- **Does a step here run a command?** Its output is tokens too, charged
  every run and kept for the session. Suppress progress/debug noise and
  bound what gets echoed.

Never split a rule from its own statement: a reference shows how to satisfy
a rule in one environment, it never holds the rule. **Relocate, never
delete** — removing guidance to save tokens is a regression, not a saving.
