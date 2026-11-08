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

## Runnable: the user can launch it in minutes

Yolo work is handed over to be tried, so it must be launchable by the user
quickly, whatever it is: a mobile app, a web app, a service, a batch, a CLI.

- **One launch command, decided at the start.** Before the first step, choose
  how the user will launch it, using the project's own convention when it has
  one (`npm start`, `./gradlew installDebug`, `make run`, a compose file), and
  log it. For a Java service or batch, use `tonosaman-deploy`. For anything
  else no skill covers yet, do it inline and log a `No skill:` entry.
- **Runnable at every push.** Each pushed commit builds and launches with that
  command. A step that breaks the launch is not done.
- **Launched, not assumed.** Before each push, run the launch command here
  and see it start (the server answers, the app opens in an emulator, the CLI
  prints its help). Where the platform cannot run here (no emulator, no
  device, a missing SDK), build the artifact the user will launch (an APK, a
  bundle, an image), say exactly what was not launched, and count it as `ENV`.
- **Written in the project.** Keep a short `Run` section in the project's
  README: prerequisites, the launch command, and for a mobile app how to get
  it onto a phone or emulator (install the built APK, scan the dev server's
  QR code, open the simulator). Never publish to a store or a shared
  distribution channel: that is outward-facing, so it is parked.
- **Mobile: Expo by default.** A new mobile app is Expo (React Native,
  TypeScript) unless the project already chose otherwise. The user may have
  only a phone, so a QR code on a terminal is no launch. Launch path, first
  that works: EAS Update on a channel named after the feature branch (the
  link opens it in Expo Go; private to the user's Expo account, allowed like
  the feature-branch push, never the production channel), when the
  environment reaches Expo and holds the user's token (ask for the token with
  a credential request for api.expo.dev; do not propose a new environment
  for it, and never repeat a request the user declined or told you to
  stop); else the web build
  (`expo export --platform web`) published where the user can open it from
  the phone, privately. An APK (EAS Build) only when Expo Go lacks a native
  module the app needs; say which. The first link you hand over states that
  Expo Go must be installed on the phone. The web build is also what the
  Playwright checks run against.

## The user adds features

A yolo run stays open: the user can add a feature or a forgotten detail at
any time. Add it as a new step with the same rules (launchable, reviewed,
logged), and record it in the `Resume` block. Only you are held to the scope
agreed at the start; what the user adds is in scope.

## Learn here, keep the good ideas properly

Yolo is where ideas are tried fast; what proves good is made properly later.

- **Where the work lives.** A quick spike may sit in a folder of the user's
  playground repo; anything to launch or keep gets its own repository.
  Suggest the move when a spike grows; creating a repository is the user's.
- **`Keep:` notes.** When something looks reusable beyond this app (a
  client, a flow, a widget, a deploy setup), log `Keep: <what>, <why it is
  generic>, <where it lives>`, and add it to the user's candidate catalog
  (one markdown file in the playground repo, or the lib's README once a lib
  exists). Do not polish or extract it now.
- **Second use makes a component.** A candidate becomes a component when a
  second project needs it, or the user says so. It is then rebuilt in build
  mode, not yolo, in a component lib repository, one per stack, from the
  `Keep:` note and what the app taught; the app's code is the reference,
  never copied in. Propose it at Finish; the lib repository is the user's to
  create.
- **The lib first.** At the start, read the catalog and the stack's lib, and
  use an existing component as a dependency pinned to a version, never a
  copy. A component that needs a change is never edited in yolo (other apps
  depend on it): work around it here and log `Change: <component>, <what>`
  for build mode in the lib. Publishing a lib version is parked.

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
- **Out of scope:** never widen, on your own, the scope agreed at the start
  (what the user adds is in scope); write the extra work under `Next`.
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
- At Finish, first add **Run it:** the launch command and the README's
  `Run` section in two or three lines, what was launched here and what was
  not. Then, before **Done**, add **Decided for you:** one line per gate you
  answered (the decision and its log entry), the reversible decisions first
  to undo. Then **Waiting for you:** every parked question, with the options
  and your recommendation, short enough to answer from a phone. Then
  **Worth keeping:** the `Keep:` and `Change:` entries of this run.
- The verdict is unchanged: an open discrepancy, an unverified AC or a parked
  step is a count, and GUILTY is the honest answer. So is a last push that
  does not launch.

"yolo off" returns to normal gates at once; record it in the `Resume` block.
