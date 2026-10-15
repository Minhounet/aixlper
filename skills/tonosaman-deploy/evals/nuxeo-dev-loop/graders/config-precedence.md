---
type: llm
weight: 2
---

Judge only `myapp.sync.enabled`, the key `NUXEOCONF` already sets. Both parts must hold for PASS.

Background: in this stack the entrypoint appends the `conf.d` files first
and then applies the `NUXEOCONF` JSON, so a key that `NUXEOCONF` also sets
is replaced by its value. A `conf.d` file can add keys but cannot override
one already in `NUXEOCONF`. The user's plan (put `myapp.sync.enabled=true`
in `90-local.conf`) therefore does nothing, because `NUXEOCONF` sets
`"myapp.sync.enabled": "false"`.

1. **The plan is corrected.** PASS this part if the answer says the
   `90-local.conf` approach won't work for this key (because the key is
   already in `NUXEOCONF`, which wins), and proposes changing the value
   where `NUXEOCONF` is defined without committing the change: for example
   parameterising it as `"${SYNC_ENABLED:-false}"` and setting the variable
   in a gitignored `.env`, or an uncommitted compose override. FAIL if the
   answer tells the user to put the key in `90-local.conf` and expect it to
   take effect.

2. **The right refresh.** PASS this part if the answer says the change needs
   the container recreated (for example `podman-compose up -d
   --force-recreate nuxeo`, or `down` then `up`), and that the script's
   in-place restart of Nuxeo is not enough to pick it up. FAIL if it says
   running the script, or `podman restart`, applies the new configuration.
