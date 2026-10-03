# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

These cases were written to answer one question: does loading the skill
change what the model does? Each one targets a rule that a model without the
skill could plausibly miss.

| Case | Targets | Sonnet, 3+3 runs, 2026-10-03 |
|---|---|---|
| `contested-term` | A contested term signals two models (Ubiquitous Language) | with 1.00 / without 1.00 |
| `legacy-integration` | An explicit choice between Conformist and ACL, with the ERP model kept out of the domain | with 1.00 / without 1.00 |
| `explain-acl` | Learning mode: definition, example, and when not to use it | with 1.00 / without 1.00 |
| `generic-subdomain` | Core Domain gets the best people; buy generic subdomains | with 1.00 / without 1.00 |

**No case discriminates.** On every case the no-skill baseline reached the
skill's answer unprompted. In `contested-term`, for example, it did the
literal ask and then flagged the company/person split as a modeling problem.
That is the skill's rule, reached without the skill. Cost of the whole run:
$1.26.

Two readings remain open. Either the skill adds no behavior on Sonnet, or
these prompts make the problem too visible (each one states the conflicting
facts plainly). A harder variant would bury the signal: for example, the two
meanings of "customer" only visible in field names spread over a longer
class, with no team descriptions.
