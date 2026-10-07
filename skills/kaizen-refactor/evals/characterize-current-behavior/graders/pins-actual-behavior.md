---
type: llm
weight: 3
---

Judge whether the proposed characterization tests pin what `compute`
**actually does today**, quirks included, rather than what it looks like it
was meant to do.

The code has three quirks a "this is what it should do" reading tends to
smooth over:

- **Asymmetric band boundaries:** 500 g is in the first band (`<=`), but
  exactly 2000 g falls in the *third* band (12.90), because the second test
  is `< 2000` while the third is `<= 10000`.
- **Integer division in the overweight surcharge:** `(weightGrams - 10000) /
  1000` truncates, so 10 999 g costs the same as 10 000 g (12.90), and
  11 000 g costs 13.90.
- **Country is case-sensitive and `"FR"`-only:** `"fr"` is treated as
  international (×1.5, plus the extra 5 for express). A `null` country
  throws `NullPointerException`.

PASS requires that the tests include **at least two** of these three
quirks, each asserted with today's actual result (e.g. `compute(2000, "FR",
false)` → `12.90`; `compute(10999, "FR", false)` → `12.90`; `compute(500,
"fr", false)` → `7.35`), and that **no** test asserts a "corrected" value
that differs from what the current code returns (e.g. 2000 g → 7.90, or a
pro-rated 10 999 g price).

Check the arithmetic of any asserted value against the code; an assertion
whose expected value the current code would not produce is a FAIL unless the
agent explicitly marks it as a known-wrong expectation it is *not*
proposing to commit.

Do not penalise: noting that a quirk looks like a bug and proposing to raise
it separately; extra ordinary cases; parameterised tests; using a subagent
to draft the tests.
