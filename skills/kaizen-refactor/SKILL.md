---
name: kaizen-refactor
description: Safely restructures existing Java code outside a TDD cycle — triaging IDE inspection findings (IntelliJ IDEA) into IDE-verified mechanical refactorings (applied directly, no judgment gate) versus judgment-call refactors (gated by concrete triggers and a passing-test safety net). Use when refactoring code that already exists — cleaning up a class, working through an IDE inspection report, modernizing legacy code — as opposed to the refactor step inside a red/green TDD cycle (see igiari-tdd) or deciding which FP style to express new logic in (see kanpeki-fp).
---

# Kaizen Refactor — Safe Restructuring of Existing Code

**Related skills:** `igiari-tdd` covers the refactor step *inside* a
red/green cycle, on code you just wrote test-first this cycle — this skill
covers refactoring code that already exists, with no new test being added,
typically surfaced by an IDE inspection pass rather than a failing test.
Also owns the mechanical-syntax checklist igiari-tdd's refactor step
applies (see "IDE-verified mechanical refactorings" below) — load this
skill for that list regardless of which workflow you're in.
`kanpeki-fp` covers *which* style a finding should become when the safe
next step is actually a style change (`null` → `Option`, exception-driven
control flow → `Either`) rather than a mechanical one — defer to it for
that judgment, don't re-derive it here.

## The one principle that matters most

**A refactor changes structure, never behavior.** Every change made under
this skill must be verifiable as behavior-preserving — either because the
IDE guarantees it mechanically, or because a passing test proves it before
and after. A restructuring you can't verify either way isn't a refactor
yet; it's a rewrite wearing a refactor's name.

## Two tiers, gated differently

**Tier 1 — IDE-verified mechanical refactorings.** Apply these directly,
with no trigger-threshold gate and no test run required first, because the
IDE's own transformation is semantics-preserving by construction (rename,
extract method/variable/constant, inline, move method/class, safe delete,
change method signature with every call site auto-updated, convert
anonymous class to lambda). The same holds for the fixed syntax-level set
below — these are mechanical, not judgment calls:

- `.stream()...collect(Collectors.toList())` → `.stream()...toList()`
- a lambda with `{ }` braces around a single expression → drop the braces
  (and the `return`, if any): `s -> { System.out.println(s); }` →
  `s -> System.out.println(s)`
- a lambda that only calls one method on its argument → a method
  reference: `s -> System.out.println(s)` → `System.out::println`
- a local variable whose type is already obvious from its initializer,
  **and whose declaration sits close to its use** → `var`. Keep the
  explicit type when declaration and use are far apart (a long method, a
  variable threaded through many lines) — making the reader scroll back to
  learn the type is a cost `var` shouldn't add. This proximity constraint
  has a useful side effect: with no explicit type nearby to lean on, the
  variable name is what has to carry the meaning, which pushes toward
  better naming rather than away from it.
- a generic constructor call already inferable from a `var` or field
  declaration → the diamond operator: `new Foo<Bar>()` → `new Foo<>()`
- `instanceof` followed by a manual cast → pattern-matching `instanceof`:
  `if (o instanceof String) { String s = (String) o; }` →
  `if (o instanceof String s) { ... }`
- a line that exceeds 121 characters → break at a natural boundary: stream
  chains get one operation per line (dot leading); long method calls get
  one argument per line. See java.md for the full convention and examples.

These are safe enough to apply in a batch — fix every Tier 1 finding
across the file/class under review, run the existing test suite once at
the end to confirm nothing broke, and move on.

**Tier 2 — judgment-call refactors.** Anything that changes shape rather
than syntax — replacing a conditional with polymorphism, promoting a
primitive to a value object, extracting a Strategy, splitting a class on
SRP, or any style-level move `kanpeki-fp` governs — is not mechanically
guaranteed safe, so it doesn't get applied on sight. Gate it the same way
igiari-tdd's refactor step gates its own advanced refinements: only act
when a concrete trigger is actually met by the code in front of you (see
igiari-tdd's "Advanced refinement — triggered, not anticipated" section
for the current threshold list — same triggers, same discipline, not
duplicated here). A candidate that doesn't meet a trigger gets logged, not
applied and not asked about — same "log, don't ask" rule as igiari-tdd.

One difference from igiari-tdd's version of this gate: there, the trigger
list is checked against code just written this cycle. Here it's checked
against a whole file or class you're reviewing, so triggers like "3rd
same-type conditional" or "3rd reason to change" are far more likely to
already be met — don't let the higher hit rate become a reason to loosen
the gate itself.

## The safety net: test coverage before Tier 2

Before making a Tier 2 change, confirm the code being touched is actually
covered:

1. Identify the tests that exercise this code. Run them and confirm a
   green baseline *before* touching anything.
2. Make one Tier 2 change at a time. Re-run the same tests. Still green →
   move to the next change. Red → the "refactor" changed behavior; revert
   or fix before continuing, never carry a red change into the next step.
3. If no test covers the code you're about to restructure, say so
   explicitly — don't apply the change anyway on the strength of manual
   reading. Either scope the pass down to Tier 1 only, or propose adding
   characterization tests first (tests that pin today's actual behavior,
   not the behavior you're about to introduce) before any Tier 2 move.

Tier 2 changes go one at a time, each with its own green check — never
batch several judgment-call refactors before running tests, even when
each one individually looks obviously safe. That's exactly the
over-trusting-your-own-read failure mode the test run exists to catch.

## Workflow: triage before touching anything

1. Run IntelliJ IDEA's inspection pass over the code in scope (Analyze →
   Inspect Code, or a targeted profile) rather than fixing findings as
   they're noticed ad hoc — the inspection report is the insight source
   this skill is built around.
2. Triage every finding into Tier 1 or Tier 2 before applying any of
   them. Don't act on a finding while still triaging the next one.
3. Apply all Tier 1 findings, then run the test suite once.
4. Work through Tier 2 findings one at a time, per the safety-net rule
   above — trigger-gated, one change, one green check, repeat.
5. If a finding is really an FP-style opportunity (a nullable read that
   should return `Option`, exception-based control flow that should
   return `Either`, a mutated collection that should be Vavr's immutable
   one), hand it to `kanpeki-fp`'s rules rather than deciding the shape of
   the fix here.

## When this skill doesn't cover the case

If you hit a situation these rules don't clearly address — an edge case,
an ambiguous rule, a step that doesn't produce the right behavior — don't
silently improvise a one-off judgment call and move on. Make the best call
you can for the situation at hand, then flag the gap explicitly, in this
format, so it can be reviewed and folded back into this file later:

```
## Skill improvement proposal
- Skill: kaizen-refactor
- Situation: <what you were doing>
- Gap: <what these rules don't cover, or got wrong>
- Proposed rule: <the addition, worded as a rule, ready to paste in>
- Suggested location: <the section of this file it belongs in>
```

This is for gaps in the rules themselves, not violations of them — a rule
you understood but chose to break is not a gap.
