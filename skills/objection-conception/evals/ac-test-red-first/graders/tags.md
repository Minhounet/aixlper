---
type: llm
weight: 1
---

Judge only the tagging. PASS if every planned test is tagged either as
proving AC1 (`[AC1]`) or as only supporting it (`(supports AC1)` or
equivalent), and helper-level tests on `UserAccount` alone are tagged as
supporting rather than proving AC1. FAIL if tests are untagged, or a test
that touches only `UserAccount` is tagged as proving AC1.
