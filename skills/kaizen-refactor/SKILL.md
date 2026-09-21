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
- `.get(0)` / `.get(list.size() - 1)` on a `List`, `Deque`, or any other
  `SequencedCollection` (Java 21+) → `.getFirst()` / `.getLast()` — same
  value, and one call instead of two. **Only mechanical when the collection
  is already known non-empty**: on an empty one the indexed form throws
  `IndexOutOfBoundsException` and the accessor throws
  `NoSuchElementException`, so check that nothing catches or propagates the
  specific type before swapping. Covers the first and last element only —
  an offset like `get(1)` or `get(size() - 2)` has no accessor and stays as
  it is.
- `instanceof` followed by a manual cast → pattern-matching `instanceof`:
  `if (o instanceof String) { String s = (String) o; }` →
  `if (o instanceof String s) { ... }`
- a `serialVersionUID` field, or a `readObject` / `writeObject` /
  `readResolve` / `writeReplace` method, on a `Serializable` type →
  annotate it with `@Serial` (JDK 14+), importing `java.io.Serial`. The
  annotation is `RetentionPolicy.SOURCE`: it enables a compile-time
  correctness check and has no runtime effect whatsoever.
- a `protected` member in a `final` class — or in an `enum`, which is
  implicitly final → drop the modifier. No subclass can exist, so `protected`
  already grants exactly package-private access, and removing it changes no
  call site. IntelliJ reports this as "Class member declared 'protected' in
  'final' class".
- a line that exceeds 121 characters → break at a natural boundary: stream
  chains get one operation per line (dot leading); long method calls get
  one argument per line. See java.md for the full convention and examples.

These are safe enough to apply in a batch — fix every Tier 1 finding
across the file/class under review, run the existing test suite once at
the end to confirm nothing broke, and move on.

### Extending Tier 1, and the record-class case

Two sections are kept out of this skill's always-loaded body and live in
`references/tier1-candidates.md` — read it when either applies:

- **Recognizing new Tier 1 candidates** — the three checks a proposed
  mechanical refactoring must pass before it may join the fixed list above
  (fixed input → fixed output; JDK/library-guaranteed equivalence; recurs
  across classes). Required reading before you add anything to Tier 1 —
  never promote a refactoring into Tier 1 from memory.
- **"Class can be record class"** — why the accessor shape decides whether
  that specific inspection finding is Tier 1 or Tier 2.

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

1. Get the inspection findings as a report you can read and triage, not
   a live GUI pass — run the scan headlessly rather than fixing findings
   as they're noticed ad hoc (Analyze → Inspect Code is the GUI
   equivalent, but produces nothing you can hand off or diff). Three ways
   to run it, in preference order:
   - **The JetBrains IDE MCP server** (`mcp__idea__lint_files`,
     `mcp__idea__get_file_problems`) — when the IDE is running with the
     project open and its MCP server is connected, this is the best route:
     no export step, no container, no second IDE instance, and the IDE stays
     open while it runs. It uses the *installed* IDE's inspections, so an
     Ultimate licence contributes its full set — strictly more than the
     Community linter below. `lint_files` takes an explicit file list, so a
     pass scopes cleanly to the package under review, and returns structured
     findings (severity, description, line, lineText) already shaped for
     triage. Caveats: the project must be imported in that IDE, and a large
     batch can return `timedOut: true` entries — split it and re-run.
     Note `mcp__ide__getDiagnostics` is a **different and much weaker**
     channel: it returns the editor daemon's highlighting for files already
     open in the editor, and times out on anything else. Do not mistake one
     for the other.
   - **`qodana scan`** — JetBrains' CI-oriented headless inspector, built
     on the same inspection engine, run via the `qodana` CLI or its
     Docker image (`jetbrains/qodana-jvm` for Java). Prefer this when
     it's available on the machine: it's the actively maintained path and
     produces one consolidated report (`qodana.sarif.json`, plus an HTML
     view) instead of one file per inspection.
     ```bash
     qodana scan --results-dir ./qodana-results
     ```
   - **`idea inspect`** — bundled with the IDE itself, as `inspect.sh` /
     `inspect.bat` in its `bin/` directory (or the `inspect` subcommand of
     an `idea` launcher already on PATH):
     ```bash
     idea inspect <project-path> <inspection-profile.xml> <output-path> -v2 [-d <subdirectory-path>]
     ```
     Requires a project with its SDK properly configured, and won't run
     while another instance of the same IDE is open. Results land as one
     XML file per inspection ID under `<output-path>`.
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

## A finding names a symptom; it does not prescribe the fix

An inspection reports what it can see locally, and its suggested remedy is
sometimes exactly backwards once you know why the code is shaped that way.
The case that proves it: **"Method 'getX()' is never used"** on an accessor
whose *absence from the call path is itself the open defect*. The IDE offers
to delete it; the correct action was to wire it up. Deleting would have
removed the evidence needed to diagnose a production failure that had
happened that same morning.

Triage decides the **tier**; it does not decide the **fix**. Before applying
any finding, ask whether the code is unused because it is dead, or unused
because something that should call it does not yet. Only the first is a
cleanup. When a finding lands on code you know is pending work, log it
against that work instead of actioning it.

Two other shapes recur and must never be auto-applied:

- **String constants that look like URLs** — XML namespaces, XSD
  `targetNamespace` values, SOAP envelope identifiers. "HTTP links are not
  secure" fires on them, and rewriting `http://` to `https://` silently
  breaks the contract: the string is an identifier that is never fetched.
- **Anything under generated sources.** The fix belongs in the generator or
  its configuration; edits to the output are overwritten on the next build.

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
