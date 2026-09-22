# Eval suite status

Cases are discovered by `prompt.md`, so this file is not a case.

## `plan-then-one-test` — confounded, do not read as a model signal

This case scores ~0.25 on **both** Sonnet and Opus, identically. That is the
signature of a case defect, not a capability gap.

The cause is structural: the eval sandbox is an empty directory, so no build
can run. The skill's approval gate exists to stop work *before doing it* — but
with nothing to run, the honest response is to present the test plan and then
narrate all the cycles in one reply, which is exactly what both models do.
They are not ignoring the gate; the gate has nothing to hold back.

Fixing it properly needs a `scaffold_script` that lays down a minimal Maven
project, run with `--scaffold`, plus `Write`/`Edit`/`Bash` in `allowed_tools`
so a real red/green cycle is possible. Until then, exclude this case when
comparing models — the other two in this suite are sound.
