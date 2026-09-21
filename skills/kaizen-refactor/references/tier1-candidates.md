# Growing the Tier 1 list, and the record-class finding

> Reference for the `kaizen-refactor` skill. Read when proposing a *new*
> mechanical refactoring for the Tier 1 list, or when an inspection reports
> "Class can be record class".

### Recognizing new Tier 1 candidates

The list above isn't closed. While triaging a report or refactoring by
hand, you'll sometimes hit a transformation that isn't listed yet but
clearly belongs there. Check it against the same bar every listed entry
already meets, all three:

- **Fixed input → fixed output.** The rewrite takes one shape to another
  with no branching judgment about the surrounding code — nothing to
  decide, only to apply.
- **Guaranteed equivalence.** The JDK or library spec guarantees the two
  forms behave identically — not "usually," not "in this codebase," not
  "as long as the collection isn't empty."
- **Recurs.** The pattern shows up across many classes, not just the one
  in front of you — a true one-off doesn't earn a permanent list entry.

A candidate that clears all three gets added to the fixed list above, used
for the rest of the current pass, and logged via the "Skill improvement
proposal" format below so the addition is recorded, not just applied and
forgotten. A candidate that fails any of them isn't Tier 1 — if it's still
worth doing, gate it as a Tier 2 judgment call instead; if the equivalence
only holds "usually" (depends on nullability, ordering, an edge case), say
so explicitly rather than promoting it.

This is exactly how the `.getFirst()`/`.getLast()` entry above was added:
`list.get(list.size() - 1)` and `list.get(0)` are a fixed rewrite, the
`SequencedCollection` contract (Java 21+) guarantees the values match on a
non-empty collection, and the first/last idiom recurs constantly. It does
*not* clear the equivalence bar unconditionally, though — on an empty
collection the two forms throw different exception types — so it went into
the fixed list with that precondition stated on the entry itself, which is
what the "say so explicitly" clause above asks for. That is the line to
hold: an entry may carry a precondition a reader can check at the call
site, but never an unstated one.

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

### "Class can be record class" — the accessor shape decides the risk

This finding recurs on any codebase with value holders, and its cost varies
enormously depending on one detail the inspection does not mention: **what
the existing accessors are called.**

- Accessors already named like record components (`statusCode()`, `body()`,
  `endpointUrl()`) → the generated accessors have identical names, so the
  conversion touches **no call site at all**. Near-mechanical; the risk is
  only the added `equals`/`hashCode`/`toString` and the fields becoming
  final. Check nothing relies on identity semantics, then convert.
- Accessors in getter style (`getEdfUuid()`) → a record **renames every
  one**, so each call site changes. That is an API change, not a cleanup,
  and it is genuinely Tier 2 however small the class is.
- Methods that are constants (`isSuccess()` always false) or whose name does
  not match a component (`isRetryable()` vs component `retryable`) have to
  be written out explicitly. Still fine, but the gain shrinks — weigh it.

**Also check the siblings before converting one class.** An inspection sees
one file at a time. Converting one of three parallel Command/Response types
leaves the family inconsistent, which costs a reader more than the record
saves. Convert the whole family deliberately, or none of it — and say which
you chose.

One difference from igiari-tdd's version of this gate: there, the trigger
list is checked against code just written this cycle. Here it's checked
against a whole file or class you're reviewing, so triggers like "3rd
same-type conditional" or "3rd reason to change" are far more likely to
already be met — don't let the higher hit rate become a reason to loosen
the gate itself.

