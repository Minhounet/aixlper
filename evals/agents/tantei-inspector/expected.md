# tantei-inspector: answer key

Not shown to the inspector. The evidence is `fixture/project/`; the clone is
a copy of this repo's `CLAUDE.md`, `skills/` and `global/agents/`, made by the
runner. Scope: all skills and agents.

## Planted: each should become a proposal (P<n>) with its evidence

| ID | Evidence | What it shows | An acceptable proposal |
|---|---|---|---|
| T1 | `No skill: Nuxeo listener` in `order-export.md` (AC2) and `invoice-archive.md` (AC3); the retro's 2026-10-21 line | The same gap twice: improve.md's rule 3 | A new skill, or a Nuxeo listener section in an existing reference (`chottomatte-archi/references/nuxeo-addon.md`), naming both entries |
| T2 | `Asked user: yes` on a class name (`order-export.md`) and a field name (`invoice-archive.md`); the retro's stalled AC2 | `saiban-orchestrator` broke its own "Never ask about naming" twice: rule 1 (broken, nobody noticed) | Clarify or move the rule (for example into the gate list itself), not a louder copy |
| T3 | `login-lock.md`: shonin-dev given "the ticket's ACs"; the retro: `acceptance.md` pasted in, red 4 then passed on arrival | The orchestrator gave the dev what it must never see, twice, and the bias followed: rule 1 | Clarify the spawn instruction (for example a checklist of what to pass and what never to pass), quoting both |
| T4 | `process-notes.md`, 2026-10-14 and 2026-10-28: release notes, same steps | A process done by hand twice: rule 3 | A skill or a new mode for release notes, with both dates |

## Decoys: no proposal should come from these

| ID | Evidence | Why not |
|---|---|---|
| X1 | `No skill: Gradle wrapper upgrade`, once | Once is not a pattern; rule 3 needs it twice |
| X2 | `process-notes.md`, 2026-10-30, Maven module rename, once | Same |

## Also checked

- Every proposal quotes evidence from the fixture, with its file.
- No proposal to delete a section.
- At most 7 proposals, in the report shape from `improve.md` section 4.
- The inspector edits nothing: the fixture and the clone copy are unchanged
  after the run (the runner checks with `git status`).

Scoring per run: 1 point per planted item found (T1–T4), minus 1 per decoy
turned into a proposal, minus 1 if anything changed on disk.
