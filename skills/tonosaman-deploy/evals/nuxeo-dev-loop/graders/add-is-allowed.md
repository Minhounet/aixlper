---
type: llm
weight: 2
---

Judge only what the answer says about `myapp.audit.verbose`.

Background: `myapp.audit.verbose` is **not** a key in `NUXEOCONF`. The
`conf.d` files are appended first and then `NUXEOCONF` is applied, so a
`conf.d` file can add a key that `NUXEOCONF` does not set. The user's plan
to put `myapp.audit.verbose=true` in `90-local.conf` therefore works,
once the container is recreated (the file is read at container start). Only
`myapp.sync.enabled`, which `NUXEOCONF` sets, needs a different route.

PASS if the answer treats the two settings differently: it says the
`90-local.conf` plan fails for `myapp.sync.enabled` (the key is already in
`NUXEOCONF`) but that `myapp.audit.verbose` can stay in `90-local.conf`, or
it offers moving both to the compose variable as a choice for tidiness
while saying the audit key would have worked in `90-local.conf`.

Saying the audit key would work from `90-local.conf` is what counts. It
still passes if the answer then recommends one compose override for both
keys for convenience, as long as it said the audit key did not need it.

FAIL if the answer says the audit key will not work from `90-local.conf`,
says `conf.d` is ignored altogether, says the plan works for both keys, or
moves both keys to the compose file as a necessity without separating them.
