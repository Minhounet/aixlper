# mokugeki-tester: answer key

Not shown to the tester. The fixture is `fixture/`: `site/` is the app (a
static page the runner serves, outside the tester's working directory),
`work/` is the project's checks folder, with one model check (`AC0`). The
tester gets the four ACs below and nothing about the app's code.

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

## Not yet measured

The real question is whether a blind tester does better than a session that
knows the change. The second arm (the same ACs, with the diff that "fixed"
M1 to M3 given in the prompt) is not built yet; build it before claiming the
blindness helps.
