---
name: shoko-playwright
description: Validates a web UI change against its acceptance criteria with Playwright - one check per criterion, run against the app actually running the current code, its result recorded as evidence. A check that already passes means the criterion is already met; one that fails drives the change until it passes. Evidence-driven validation, not TDD. Use when working on a web front end (for example a Nuxeo UI) where acceptance criteria are proven by browser checks rather than unit tests, or when asked to validate, check or prove UI behavior with Playwright.
---

# Shōko: evidence for each acceptance criterion

*Shōko* (証拠) is evidence. In UI work the proof of an acceptance criterion
(AC) is a browser check that a person could watch: open the page, do what
the AC says, see what it promises. This skill turns each AC into such a
check, runs it, and keeps the result as evidence.

This is **not TDD**. A check may pass the first time it runs: that means
the behavior already exists and the AC is met, which is a valid result
here. Don't apply `igiari-tdd`'s red-first rule to these checks. If the
ticket is tracked with `objection-conception`, it owns the AC records; this
skill only produces what goes into them.

## The loop, one AC at a time

1. **Derive the check from the AC.** Write down, before any code, the
   user-visible steps and the observable outcome the AC promises, taken
   from its interpretation. One check per AC, named after it and tagged
   with it (`[AC2]`). If the AC promises nothing a browser can observe, it
   can't be proven this way: say so and ask, don't invent a proxy.
2. **Make sure the running app is the current code.** If code changed since
   the last deploy, redeploy first (with `tonosaman-deploy` when the app
   runs in a local container), then check the app is actually up before
   running anything. A check against stale code proves nothing.
3. **Run the check.**
   - **Passes:** the AC is already met. Record the evidence (step 4) and
     move on. No code change.
   - **Fails on its assertion:** the behavior is missing or wrong. Make the
     change, redeploy, run again, until it passes.
   - **Fails before reaching its assertion** (app down, login failed,
     missing test data, a timeout on page load): that is the environment,
     not the AC. Fix or report it; never count it either way.
4. **Record the evidence:** the check's name, the command that ran it, its
   result line, and the path to a trace or screenshot when one was kept.
   Record only a pass you actually saw in this run.

Keep every check: commit it with the change. Together they become the
regression suite for the screens they cover.

## Checks that don't lie

A check that passes for the wrong reason is worse than none. Write it so a
pass means the AC holds:

- **Assert on what the user sees**, with assertions that wait by themselves
  for the condition (visible, has text, has count, has URL). Never a fixed
  sleep: it is either too short (flaky) or too long (slow), and it hides
  the real condition.
- **Find elements the way a user would:** by role and accessible name, by
  label, by visible text, or by a test id the app provides. Avoid CSS paths
  and XPath tied to layout; they break on any redesign and say nothing
  about the AC.
- **Web components:** Playwright's locators reach into open shadow roots,
  so locate by role, label or text as above. Never walk a component's
  internal structure to reach an element.
- **Independent checks:** each one sets up the data it needs and doesn't
  rely on another having run first.
- **No retries to get green.** A check that passes only on a retry is
  flaky; that is a finding to fix (usually a missing wait condition), not a
  pass.
- **Assert the outcome the AC states, not a side detail.** If the AC says
  "the document appears in the list", check the list, not a toast that
  says "saved".

## Project specifics

The base URL, how to log in, which test user and which test data to use
come from the project (its config, its existing specs, the user). Read the
existing Playwright config and specs first and follow their conventions.
Never guess credentials and never write a real password into a check:
read it from the environment or the project's existing mechanism, and ask
if there is none.

## Running it

Run one check, or one file, at a time while working on an AC, with a
terse reporter, and keep traces only for failures:

```
npx playwright test <spec-file> --grep "AC2" --reporter=line --trace retain-on-failure
```

Run the whole relevant suite once at the end, before reporting. Quote the
result line and the failing assertion when there is one, not the full
log.

## Token self-audit

This file loads **in full** whenever the skill triggers and stays resident
for the rest of the session; `references/` files load only if the body
points at one. When asked to reduce token cost — or before adding anything
here — audit in this order and report what you would move, and why:

- **Needed only sometimes?** Material for one framework, one tool's exact
  commands, or a section about extending the skill itself → move to
  `references/` behind a pointer that names the condition precisely.
- **A reference opened on almost every trigger?** Then it costs *more*
  there than inline — a tool call, an extra assistant turn, and a lost
  prefix cache. Bring it back inline.
- **Does a step here run a command?** Its output is tokens too, charged
  every run and kept for the session. Suppress progress/debug noise and
  bound what gets echoed.

Never split a rule from its own statement: a reference shows how to satisfy
a rule in one environment, it never holds the rule. **Relocate, never
delete** — removing guidance to save tokens is a regression, not a saving.

## When this skill doesn't cover the case

If you hit a situation these rules don't clearly address — an edge case,
an ambiguous rule, a step that doesn't produce the right behavior — don't
silently improvise a one-off judgment call and move on. Make the best call
you can for the situation at hand, then flag the gap explicitly, in this
format, so it can be reviewed and folded back into this file later:

```
## Skill improvement proposal
- Skill: shoko-playwright
- Situation: <what you were doing>
- Gap: <what these rules don't cover, or got wrong>
- Proposed rule: <the addition, worded as a rule, ready to paste in>
```
