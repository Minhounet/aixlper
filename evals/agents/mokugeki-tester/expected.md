# mokugeki-tester: answer key

Not shown to the tester. Two cases, each a folder: `site/` is the app (a
static page the runner serves, outside the tester's working directory),
`work/` the project's checks folder with one model check (`AC0`),
`prompt.md` what both arms get, `informed.md` what only the informed arm
gets, `verdicts.txt` the right verdicts the runner scores against.

## `traps` (`--case traps`, the default): traps the skill names

The tester gets the four ACs below and nothing about the app's code.

| ID | AC given to the tester | Right verdict | The trap: a check that passes for the wrong reason |
|---|---|---|---|
| M1 | "When a document's title is too long to fit, the user can read the full title by hovering over it." | `HUMAN` | The page uses a native `title` attribute: an attribute check, or a hover then an attribute check, passes, but the tooltip is drawn by the browser, outside the page, so no check can see it (`shoko-playwright`, "Checks that don't lie"). `PASS` is wrong. `FAIL` is acceptable only if the note says the tooltip can't be observed. |
| M2 | "A read-only user (`?role=reader`) does not see the Delete button." | `FAIL` | The button is still visible, only disabled. Asserting it is disabled, or not clickable, passes; the AC says *not seen*. |
| M3 | "After saving a new document, it appears in the document list." | `FAIL` | Save shows a "Document saved" toast (after a delay) but never adds the row. Asserting the toast passes; the AC is about the list. |
| M4 | "The list shows each document's author." | `PASS` | Control: met as it stands. `FAIL` here means the check is wrong. |

Scoring per run: 1 point per right verdict (M1 `FAIL` with the right note:
half a point). Max 4.

## Also checked

- One check file per AC under `checks/`, following `AC0`'s convention.
- No fixed sleep (`waitForTimeout`, `setTimeout` waits) in any check: the
  runner greps for them. M3's delayed toast tempts one.
- Locators by role, label or text; no CSS class (`.doc-title`) or XPath.
- Nothing outside `checks/` (and its evidence) changed, and `site/` is
  untouched: the runner compares both before and after.
- The report is in the agent's shape, one block per AC.

## The comparison arm

`--arm informed` runs a plain session with `shoko-playwright`, given the
same ACs and `traps/informed.md` (the change that "fixed" M1 to M3). On
2026-11-06 both arms scored 4/4 (results in `../README.md`): this fixture
tests the skill's rules, not the blindness. Don't read a blind 4/4 here as
evidence the agent helps.

## `anchor` (`--case anchor`): fixes right only for the case their notes describe

Built to separate the arms after `traps` didn't: here the skill names none
of the gaps, and only the informed arm's notes narrow the case. Both arms
get each AC verbatim and a faithful reading of it; the informed arm also
gets the diff and decision-log notes that describe each fix by the case it
handles.

| ID | AC | Right verdict | The fix, as its notes describe it | The gap, visible from the page |
|---|---|---|---|---|
| A1 | "Documents are listed newest first." | `FAIL` | Sorted on the date column, descending | Dates are `dd/mm/yyyy` compared as text: 28/02/2026 above 05/03/2026 |
| A2 | "Searching finds documents whose title contains the text typed, whatever its case." | `FAIL` | Titles lowercased, so "report" finds "Quarterly Report" | The query isn't lowercased: "Report" finds nothing |
| A3 | "A read-only user cannot delete a document." | `FAIL` | Per-row Delete hidden for readers | "Delete selected" still shown and works for a reader |
| A4 | "Each document shows its author." | `PASS` | Author column added | None: control |

An arm anchored by the notes would check the case they name and pass A1 to
A3. On 2026-11-06 neither arm was (results in `../README.md`).

## `e2e` (`scripts/eval_ui_e2e.sh`): implement, then prove

Not a verdict key: here the arm writes the fix itself, so there is no fixed
right answer per AC. `e2e/site/` is the page before any fix; its code
changes the list in five separate places (first render, add, row delete,
filter, a keyboard shortcut), so a fix in one place looks done and isn't.
Both arms get `e2e/prompt.md` (the four ACs, interpreted); `--arm tester`
also gets `e2e/tester.md` (prove through `mokugeki-tester`, never hand it
the change). `e2e/oracle.js`, never shown to either arm, then judges the
page left behind:

| Oracle | Passes only if |
|---|---|
| O1 | As a reader, neither button nor keyboard removes a row; an editor still can |
| O2 | The heading's number equals the visible rows on load, after a search, after clearing it, after a delete and after an add |
| O3 | Dates descend on load and after adding the newest document |
| O4 | Every row, including a newly added one, shows its author |

Checked before any run: the unfixed page fails all four; a reference fix
through one `render()` passes all four; a typical partial fix (each AC
fixed where it's first visible) fails O1 to O3 on the paths it missed.
Scored per run: defects shipped (oracle `FAIL`), false proofs (the arm said
`PASS`, the oracle `FAIL`). `ERROR` means the arm changed the page too much
for the oracle to drive: read it, don't count it.
