---
name: tantei-debug
description: Investigate a Java bug whose cause is not known yet - a webservice (Spring, Nuxeo, any server) or a plain Java batch, run locally or on a remote dev server - by bisection - set a breakpoint halfway along the suspect path, read the values that decide right or wrong, keep the half where the value goes wrong, repeat, and step line by line only once the window is a few lines wide. Logs first, a JPDA/JDWP debugger (jdb, or the IDE through MCP) on a JVM you control. Every split is written to an investigation note with a Resume block, so an interrupted session picks up where it stopped. Ends at the pinpointed cause (where, input, expected vs actual), handed to a characterization test and a TDD fix. Use when something doesn't work and nobody knows why yet, when asked to debug, attach a debugger, use jdb or JPDA, read a server's logs to find a bug, or resume an investigation note.
---

# Tantei: find where it goes wrong

*Tantei* (探偵) is the detective. This skill finds **where** a bug is, and
stops there. Fixing it is the next skill's job (`igiari-tdd`). Investigating
and fixing at the same time hides the cause under the first change that
makes the symptom go away.

## 1. Pin the symptom and a way to reproduce it

Before any breakpoint, write in the note (section 4):

- **Symptom**: the expected value and the actual value, both concrete
  ("total = 3, expected 8"), not "the total is wrong".
- **Target**: webservice or batch, local or remote (host), how it runs.
- **Reproduce**: the exact command, request (`curl`, payload) or input file
  that shows it. Run it once and see the wrong result yourself.

No reproduction yet: find one first, from the logs (section 2). Without one,
no split can be judged, so say so and ask the user for the failing case.

## 2. Evidence, cheapest first

1. **Logs and stack traces** from wherever the target runs. An exception
   with its stack often names the line and ends the investigation. Read the
   window around the failing request, filtered on the server side (`grep`
   by request id, time window, `tail -n`), never a whole log file.
2. **A temporary log line**, when the project is easy to rebuild and run.
   List each one in the note; remove them all before the fix.
3. **A debugger** (JPDA/JDWP) on a JVM you control: when the state is hard
   to log, rebuilding is slow, or several values must be read at one moment.

Never attach a debugger to production: a breakpoint stops the threads
that reach it, and the JDWP port has no authentication (anyone who reaches
it can run code in the JVM). In production: logs, a thread dump
(`jcmd <pid> Thread.print`), a JFR recording.

Before suspending a server other people use (a shared dev or test server),
ask: their requests will hang on your breakpoint too.

## 3. Bisect, don't walk

The suspect path runs from the **input** (known good: the request or file
as given) to the **observed wrong value** (known bad). Bisect it:

1. Pick a point roughly halfway along the path, at a line where a value
   that decides right or wrong is visible.
2. **Write the expected value in the note before reading it.** Reading
   first invites explaining whatever comes out as plausible.
3. Stop there, read only the values that decide it, and give a verdict:
   - **wrong** → the cause is between the last good point and here;
   - **right** → it is between here and the first bad point.
4. Record the split (section 4), then halve the remaining window again.

Step line by line (`next`, `step`) only once the window is one method or
a few lines. Stepping through a whole flow is the slow, expensive way:
each step is a round trip, where a split halves the work.

Read what decides; don't dump everything. A collection: its size and the
element in question (`list.size()`, `list.get(i)`), not its internals.
Changing a value in the debugger (`set`) to test a hypothesis is allowed:
record it as a hypothesis test, not as a finding.

**No code change while investigating**, except the temporary log lines in
section 2. A "quick fix to see if it helps" is a fix without a test.

## 4. The investigation note: written after every split

The note lets anyone (you after an interruption, another session, the
user) resume without redoing a split. Update it **after every split and
before the next action**, not at the end: the session can stop at any
moment.

Where: `docs/ticket/<id>/debug.md` when there is a ticket folder, otherwise
`docs/debug/<short-symptom>.md` in the project. Commit it along with the
project's other design notes or decision logs if those are kept in git;
otherwise keep it on disk and say where.

```markdown
# <symptom in one line>

## Resume
Symptom: <expected> vs <actual>
Target: webservice | batch — local | remote <host> (tunnel <local>:<remote>)
Reproduce: <exact command / request / input>
Debug setup: <how the JVM was started with JDWP, port, attached with what>
Window: <last good point> → <first bad point>
Next: <the next split: where, which value, what it should be>
Temporary changes: <log lines added, values set; "none">

## Splits
1. `OrderService.java:200` `order.total` expected 8, got 3 → wrong: before here
2. `PriceCalc.java:60` `prices` expected [5,1,2], got [5,1,2] → right: between 60 and 200

## Found
Where: `PriceCalc.java:88`
Input: <the smallest input that shows it>
Expected: <value> — Actual: <value>
Cause: <why, in one or two sentences: the cause, not the symptom>
```

**Resuming:** read `Resume`, re-run `Reproduce` to check the symptom still
shows, re-create the debug setup (breakpoints don't survive), then do
`Next`. Don't redo the splits already recorded.

## 5. Found: hand over to the fix

The investigation ends when `Found` is filled: one location, the input, the
expected and actual values, the cause. Then:

1. **Remove every temporary change** listed in the note.
2. **Existing code without tests around the cause**: characterization tests
   first, by `kaizen-refactor`'s rule (they pin today's behavior and pass on
   the unchanged code). The behavior at the cause itself is not pinned as it
   is: that is the bug.
3. **The RED**: a test with `Found`'s input asserting the **expected**
   value. It fails for the reason in `Cause`, or the cause is wrong: go back
   to the note.
4. **The fix**, by `igiari-tdd`.

## Debugger and access specifics

| When | Read |
|---|---|
| Attaching a debugger to a JVM: starting it with JDWP (IDE "Run", Maven, Gradle, Spring Boot, Tomcat, a batch), remote over SSH, driving `jdb` one command at a time with `scripts/jdb_session.py` | `references/jdb.md` |
| Driving the IDE's own debugger (IntelliJ) through an MCP server instead of `jdb` | `references/intellij-mcp.md` |

## Token self-audit

This file loads **in full** whenever the skill triggers and stays resident
for the rest of the session; `references/` files load only if the body
points at one. When asked to reduce token cost, or before adding anything
here, audit in this order and report what you would move, and why:

- **Needed only sometimes?** Material for one framework, one tool's exact
  commands, or a section about extending the skill itself → move to
  `references/` behind a pointer that names the condition precisely.
- **A reference opened on almost every trigger?** Then it costs *more*
  there than inline: a tool call, an extra assistant turn, and a lost
  prefix cache. Bring it back inline.
- **Does a step here run a command?** Its output is tokens too, charged
  every run and kept for the session. Logs are filtered on the server
  before they are read; a debugger reply is capped (`--max-lines`); dump
  nothing whole (a log file, an object graph, `threads` on a busy server)
  when one value decides.

Never split a rule from its own statement: a reference shows how to satisfy
a rule in one environment, it never holds the rule. **Relocate, never
delete**: removing guidance to save tokens is a regression, not a saving.

## When this skill doesn't cover the case

If you hit a situation these rules don't clearly address (an edge case,
an ambiguous rule, a step that doesn't produce the right behavior), don't
silently improvise a one-off judgment call and move on. Make the best call
you can for the situation at hand, then flag the gap explicitly, in this
format, so it can be reviewed and folded back into this file later:

```
## Skill improvement proposal
- Skill: tantei-debug
- Situation: <what you were doing>
- Gap: <what these rules don't cover, or got wrong>
- Proposed rule: <the addition, worded as a rule, ready to paste in>
```
