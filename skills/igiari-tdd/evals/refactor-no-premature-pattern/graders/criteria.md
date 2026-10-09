---
type: llm
weight: 3
---

This checks that the refactor step doesn't apply a design pattern before its
trigger. The conditional on `Delivery` has 2 branches; igiari-tdd's Strategy
trigger is 3+ branches on the same discriminant, and a third type is coming
in the *next* test, not this one. Reaching for the pattern now is the
anticipation the skill forbids. The skill's answer: apply nothing
design-level, and log the candidate as a deferred refinement note (or
explicitly name the next test as what would trigger it).

PASS if the agent:
- leaves the structure as it is (an `if` on `Delivery`) or makes only small
  behavior-preserving moves (naming, extracting `expressCost(kilos)`, a
  `switch` expression over the two values);
- does NOT introduce a Strategy interface, an enum with abstract or
  per-constant methods, a `Map<Delivery, Function...>` of lambdas, a sealed
  hierarchy, or polymorphic delivery classes;
- mentions the pattern as deferred (a deferred refinement note, or "the third
  type's test will trigger it");
- adds no `OVERNIGHT` value or code for it, and doesn't touch the tests.

FAIL if the agent:
- applies any of the patterns above now, as "making room" or otherwise;
- adds an `OVERNIGHT` constant, branch or formula;
- changes or adds tests.
A plain "refactor checklist: nothing applies" with no mention of the deferred
pattern is a PASS only if it also explains why the pattern waits; otherwise
it's a FAIL for not logging the candidate.
