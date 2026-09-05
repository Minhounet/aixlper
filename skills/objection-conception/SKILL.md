---
name: objection-conception
description: Use whenever the user is working from a Jira ticket (or any ticket-based task) and wants to think through the design/conception together before or during implementation - phrases like "let's design TICKET-123", "resume the thinking on PROJ-42", "I have a new ticket, let's figure out the approach", or any mention of a ticket folder under .claude/ticket/<ticketId>/. Also trigger when picking work back up on a ticket that was discussed in an earlier session. Persists the design conversation and the difficulties hit along the way to disk, inside the ticket's own folder, so that thinking survives past the current session instead of being lost when it ends.
---

# Objection Conception

## Why this exists

A design conversation that only lives in the current session disappears the
moment the session ends or gets compacted. This skill exists to make that
thinking durable: everything decided, and everything that went wrong along
the way, gets written to disk inside the ticket's own folder, incrementally,
as it happens - not reconstructed from memory at the end.

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

Neither file existing yet just means this is a fresh start for the ticket -
you'll create both as the conversation produces something worth recording.

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
implementation) is actually finished.

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
