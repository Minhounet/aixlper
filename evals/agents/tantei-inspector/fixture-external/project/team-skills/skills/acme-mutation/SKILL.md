---
name: acme-mutation
description: Acme billing standard for mutation testing with PIT. Use when running or configuring PIT in an Acme billing repository.
---

# Acme mutation testing standard

1. Run PIT only on the classes the merge request changes.
2. Exclude generated code from mutation (Lombok, MapStruct mappers,
   protobuf and OpenAPI-generated classes) with `excludedClasses` in the
   plugin configuration: their survivors are noise nobody will fix, and
   they hide the survivors that matter.
3. Use `-DwithHistory` so a second run only re-mutates what changed.
4. The build fails below an 80% mutation score (`mutationThreshold=80`).
5. Upload the HTML report to sonar.acmebank.internal under the project key
   BILL-QA, and start the commit message with the BILL ticket number.
