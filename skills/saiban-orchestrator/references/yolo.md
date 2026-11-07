# Yolo: you take the decisions, the process stays whole

Read this when the user says "yolo" (at the start or at any time), or when a
`Resume` block says `Yolo: on`.

Yolo is not a mode and not a shortcut. The mode, its skills, its order, its
helper agents and every skill's own checks run exactly as without it. Only
**who answers** the gates changes: you take the decision you would have
recommended, log it, and go on. The user reviews the decisions afterwards,
in the report, instead of one by one during the run.

It applies to fix, build and UI modes, and to think mode (you approve the
design yourself). Not to improve mode: a change to the skills is always the
user's. Direct mode has no gates, so it changes nothing there.

## What stays exactly the same

- **The pipeline.** Same skills, loaded at the same moments. A plan is still
  written in full, against the same rules, and committed or logged before
  code follows it. Never skip a step because nobody is watching.
- **The helpers, on their usual rules.** `kenji-reviewer` on by default in
  build and UI modes, `shonin-dev` by its per-run rule, `mokugeki-tester` on
  in UI mode. "no review" and the like still come only from the user, never
  from yolo.
- **The proof.** Every AC is verified with evidence, the green gate and Super
  Green still apply, the verdict is given from evidence as always.
- **The agent's working rules** (no force-push, no secret, ask before
  anything destructive): yolo does not lift them, with one exception below.

## Pushing: a feature branch only

Saying "yolo" is the user asking you to push, to a **feature branch** only:
the branch you work on, never the default branch (`main`, `master`,
`develop`) or a branch someone else works on. If you are on one of those,
create a feature branch first (named after the topic or ticket) and log it.
Push after each verified AC or step is committed, with a plain push: never
force, never rewrite history already pushed, never open or merge a pull
request. A push the remote refuses is parked, not retried another way.

## Gates you answer yourself

Take the option you would have recommended, the one most faithful to the
ticket's text and the approved plan, and log it.

- **A skill's own approval gate** (structural plan, AC trace, TDD plan, a
  re-approved deviation): run the skill's checks, then approve it yourself.
- **A real fork:** take your recommendation.
- **A deviation** from an approved plan: take the smallest change that keeps
  the plan's intent; write it as a deviation in the log, as the skill asks.
- **A `kenji-reviewer` finding:** fix every `blocking` one; fix a `minor` one
  when it is cheap, otherwise log it as open. Never dismiss a blocking
  finding as wrong on your own: if you think it is, log it as open and
  leave the AC unverified.
- **A discrepancy** between ticket, ACs and design: choose the reading
  closest to the ticket's own words, record it in `acceptance.md` as the
  skill says, and carry it as open for the user.

## Gates you never answer yourself

You do not stop the run for these: **park** the step, go on with every step
that does not depend on it, and ask them all together at the next pause or
at Finish.

- **Hard to reverse or outward-facing:** any push other than the
  feature-branch push above, a pull request, deleting, a schema or
  public API change, a shared or remote system. If a reversible way reaches
  the same result, take it instead and log why.
- **A change only the user can make** (a vendor designer, Studio Modeler).
- **Waiving an AC or a blocking finding:** only the user waives.
- **Out of scope:** never widen the scope agreed at the start; write the
  extra work under `Next`.
- **A check written by `mokugeki-tester` that you think is wrong:** never
  edit it; log it as open with your reason.

## Pauses

Yolo implies "no pauses": you do not stop at break points. The user can say
"with pauses" to keep them. Still update and commit the `Resume` block at
each break point, so a crash or a `/clear` loses nothing.

## Log and report

- The `Resume` block carries `- Yolo: on`.
- Every gate you answered gets its normal log entry with
  `Asked user: no (yolo)`, so they can all be found with one search.
- At Finish, before **Done**, add **Decided for you:** one line per gate you
  answered (the decision and its log entry), the reversible decisions first
  to undo. Then **Waiting for you:** every parked question, with the options
  and your recommendation, short enough to answer from a phone.
- The verdict is unchanged: an open discrepancy, an unverified AC or a parked
  step is a count, and GUILTY is the honest answer.

"yolo off" returns to normal gates at once; record it in the `Resume` block.
