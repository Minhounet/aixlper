---
type: llm
weight: 1
---

Judge only the order of operations.

Background: the script copies jars into the running container
(`podman cp`). Those copies live in the container's writable layer. A
container recreate (needed to apply the configuration change) rebuilds the
container from the image, so the copied jars are gone.

PASS if the answer makes the order explicit and consistent with that: the
configuration change is applied by recreating the container first, and the
deploy script is run (or rerun) after the recreate, with a reason such as
"a recreate discards the jars copied earlier" or "the recreated container
starts from the image". Giving the order alone, recreate then script, with
a clear statement that the recreate resets the container, is enough.

FAIL if the answer tells the user to run the script and then recreate, or
recreates and stops without saying the code must be deployed again, or says
the copied jars survive a recreate.
