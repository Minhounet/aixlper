---
type: llm
weight: 1
---

Judge only what happens to the server after PROJ-2's checks.

Background: the local server runs one version at a time. After PROJ-2's
checks it runs PROJ-2's jars (and PROJ-2's Designer files, if its branch
was checked out in the served folder). Until PROJ-1 is put back, any check
of PROJ-1 tests PROJ-2's code.

PASS if, before continuing PROJ-1, the answer puts PROJ-1 back on the
server: its branch checked out again in `~/work/myapp` where needed, and
its jars redeployed (`./dev-deploy.sh` from the PROJ-1 checkout), or it says
explicitly that the server still runs PROJ-2 until that is done.

FAIL if it goes back to PROJ-1 without redeploying PROJ-1's jars and
without any warning that the server still runs PROJ-2's code.
