---
name: ddd-strategic-design
description: Guidance and reference for Domain-Driven Design's strategic patterns — Ubiquitous Language, Bounded Context, Context Map, and the model/team relationship patterns (Shared Kernel, Customer-Supplier, Conformist, Anticorruption Layer, Open Host Service, Separate Ways), plus Core Domain / Generic Subdomain distillation. Language-agnostic. Use when defining or reasoning about the boundary between two or more models, teams, services, or systems — including integrating with a legacy or third-party system — not for structuring dependencies inside a single model (see java-clean-architecture, Java-specific) or for the test-writing workflow (see java-tdd-baby-steps). Also use to explain any of these DDD terms on request, e.g. "what's a bounded context", "explain the anticorruption layer".
---

# DDD Strategic Design

**Related skills:** `java-clean-architecture` governs dependency direction
*inside* one model/codebase, and already covers DDD's tactical patterns
(Entity, Value Object, Aggregate) as what lives inside the domain layer that
direction protects — Java-specific. This skill is one level up and
language-agnostic: it's about the boundary *between* models — where one
model ends and another begins, and how two models talk to each other.
Orthogonal, not a dependency: a single-model Java feature only needs
`java-clean-architecture`; load this skill too once a second model, team,
service, or external system enters the picture.

## Scope: strategic vs. tactical

DDD has two halves. This skill is the strategic half only:

- **Tactical** (Entity, Value Object, Aggregate, Repository, Factory,
  Service, Module) — patterns for structuring *one* model. Already covered,
  for Java, in `java-clean-architecture`.
- **Strategic** (this skill) — patterns for structuring a *system of
  models*: where the boundaries are, what crosses them, and how the teams
  on either side relate to each other.

Don't reach for this skill to decide whether something is an Entity or a
Value Object — that's tactical. Reach for this skill when the question is
"does this belong in the same model as that?", "who owns this concept?", or
"how do these two systems talk without corrupting each other?"

## Ubiquitous Language

A model and the language used to describe it are the same artifact, not two
things kept in sync:

- Every concept in a Bounded Context should have exactly one name, used the
  same way in conversation, in code (class/method names), and in any
  diagrams or docs for that context — not a "business term" translated into
  a different "technical term" in code.
- An ambiguous or contested term isn't a naming detail to smooth over — it's
  a signal of either a missing distinction in the model or two Bounded
  Contexts hiding inside what's being treated as one. Resolve it by
  refining the model (often splitting a class, or splitting a context), not
  by picking a synonym and moving on.
- A domain expert should be able to read the class/method names relevant to
  a story and follow what's happening; if they can't, the code has drifted
  from the language.

## Bounded Context

A Bounded Context is the boundary within which a model is unified — one
consistent set of terms, no internal contradictions. It's the primary unit
this skill works in.

When helping design or evolve a system:

- **Don't default to one model for the whole system.** A single unified
  model across a large domain is a trap, not a goal — it becomes either
  contradictory or so watered-down it says nothing useful. Prefer several
  small, sharp models with explicit boundaries over one big blurry one.
- **A context should be small enough for one team to own.** If ownership is
  split awkwardly across a context's boundary, that's a signal the boundary
  is in the wrong place.
- **Name every Bounded Context**, and make that name part of the Ubiquitous
  Language — "the Billing context", "the Shipping context" — so it's a real
  conversational unit, not just an implicit code-organization detail.
- **Draw the boundary in concrete terms**, not just conceptually: which
  team, which codebase/module, which database schema, which deployable. A
  context with a fuzzy answer to "where does the code for this live" isn't
  actually bounded yet.
- Inside a context, keep the model internally consistent via **Continuous
  Integration**: merge and re-test frequently (daily, for a small team) so
  drift is caught immediately, not after several people have quietly built
  on an inconsistency.

Do **not** confuse a Bounded Context with a code Module (package/namespace).
A Module organizes what's inside one model; a Bounded Context is the
boundary the model itself lives inside. A context typically contains
several modules.

## Context Map: naming what's between the boundaries

Once more than one Bounded Context exists, the relationships between them
need to be explicit — left implicit, they rot silently. A Context Map (a
diagram or a written doc, kept wherever the team will actually look at it)
names every context and the pattern connecting it to its neighbors. Pick one
pattern per relationship, deliberately — don't leave a context's connection
to its neighbor unstated.

| Pattern | Use when | Cost / risk |
|---|---|---|
| **Shared Kernel** | Two teams get real, ongoing value from sharing a subset of the model (and its code/schema), and can coordinate closely. | Either team can break the other; needs frequent joint integration and a test suite covering the shared part. Don't reach for this just to avoid writing a translation layer. |
| **Customer-Supplier** | One context depends heavily on another, no shared code makes sense, but the supplying team can prioritize the customer's needs. | Needs real organizational buy-in (ideally shared management) — otherwise it silently degrades into Conformist. Back it with automated acceptance tests the customer defines and the supplier runs in their own CI. |
| **Conformist** | You depend on an upstream team/model with no incentive to accommodate you (no shared management, a vendor, an indifferent team). | You take their model as-is, with no local translation. Cheapest to build, but their model's flaws become yours — only choose this when the upstream model is actually good enough to live with. |
| **Anticorruption Layer** | You must integrate with an external or legacy system whose model is poor, or different enough that letting it leak in would corrupt your own. | An explicit translation layer (a Service, built as a Facade with an Adapter/Translator underneath) between your model and theirs. Costs a layer to build and maintain; buys your model total isolation from theirs. |
| **Open Host Service** | Your context is a supplier to *several* other contexts, and hand-rolling a translator per consumer is duplicating work. | Define one shared protocol/API for your context, evolve it for the common case; give a consumer with truly one-off needs its own small translator on top rather than distorting the shared protocol. |
| **Separate Ways** | Two contexts have little or no real overlap; forcing an integration costs more (translation code, coordination overhead) than it returns. | Cheapest of all: no integration at all. Confirm first that you won't need to re-merge later — independently-evolved models are expensive to re-integrate. |

Two extra notes worth keeping in mind:

- **Conformist vs. Anticorruption Layer is the same situation** (an
  upstream you don't control) with the opposite answer: conform when their
  model is good enough to absorb as-is; wrap it when it isn't, or when the
  cost of corruption to your own model is too high.
- **Customer-Supplier needs organizational teeth**, not just goodwill. A
  supplier team under its own separate deadlines will quietly under-serve a
  customer team unless something (shared management, contractual priority)
  actually backs the relationship — otherwise expect it to degrade into a
  de facto Conformist relationship, and plan accordingly rather than
  assuming best intentions will hold.

## Core Domain and Generic Subdomain (Distillation)

Even inside one large system, not all of it deserves equal attention:

- **Core Domain**: the part that captures the system's actual
  competitive/business advantage — the reason it exists. Put the best
  people here; invest in a genuinely deep model, and justify spend on
  everything else by what it buys the Core.
- **Generic Subdomain**: a coherent piece of the model that isn't the
  differentiator (currency/money handling, routing, generic auth) even
  though the system can't function without it. Keep it out of the Core
  Domain's way: a separate module, lower priority for the best developers'
  time, and a real candidate for a bought/open-source solution, an
  existing published model, or a smaller/simpler home-grown
  implementation — not necessarily the deepest design effort available.
- Which part is "core" is relative to the system, not universal — a
  routing engine is the Core Domain for a logistics company and a Generic
  Subdomain for an air-traffic-monitoring system that merely uses routing
  as an input. Don't assume a concept's status carries over from one
  project to the next.

## When there's no second team yet

Most of this still applies to a single team working alone, in two common
situations:

- **Splitting a monolith, or planning to.** Identifying Bounded Context
  boundaries and naming the Context Map relationships between the
  candidate pieces is exactly the design work that precedes an extraction —
  do it before splitting code, not after.
- **Integrating a legacy or third-party system.** Even a lone developer
  hitting an external API or an old database is choosing (usually
  implicitly) between Conformist and Anticorruption Layer. Make that
  choice explicit rather than accidental: look at the external model,
  decide if it's good enough to conform to or bad/foreign enough to need a
  wrapper, and say which pattern is being applied.

## Learning mode

When asked to explain a term from this list rather than apply it, answer
using the definition above plus a concrete example — don't just name-drop
the pattern. If a question sits right at the tactical/strategic boundary
(e.g. "what's the difference between a Module and a Bounded Context",
"where do Aggregates fit into a Context Map"), answer the strategic half
here and point to `java-clean-architecture` for the tactical half rather
than improvising tactical guidance in this file.

## When this skill doesn't cover the case

If a real situation doesn't map cleanly onto anything above — an
integration shape none of the Context Map patterns quite fit, a boundary
question with no clean answer — don't silently improvise and move on. Make
the best call for the situation, then flag the gap:

```
## Skill improvement proposal
- Skill: ddd-strategic-design
- Situation: <what you were doing>
- Gap: <what these rules don't cover, or got wrong>
- Proposed rule: <the addition, worded as a rule, ready to paste in>
- Suggested location: <the section of this file it belongs in>
```

This is for gaps in the rules themselves, not a judgment call that turned
out debatable.
