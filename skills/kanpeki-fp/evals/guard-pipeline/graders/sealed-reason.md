---
type: llm
weight: 1
---

PASS if the skip reasons are modelled as a sealed interface (or sealed class)
with one record per reason, each carrying only the context it needs (e.g. the
document id), and they are logged via an exhaustive `switch` using record
deconstruction patterns (e.g. `case IsProxy(String id) -> ...`).

FAIL if skip reasons are Strings, an enum, a boolean, or a single record with
nullable fields - or if the switch uses type patterns plus accessor calls
(`case IsProxy p -> ... p.id()`) instead of record deconstruction.
