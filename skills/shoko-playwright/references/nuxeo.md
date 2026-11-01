# Nuxeo Web UI under Playwright

Read this when the app under test is Nuxeo Web UI (URLs under `/nuxeo/ui/`,
`nuxeo-*` elements in the page), including layout ACs checked at several
viewport sizes.

## Status: placeholder, waiting for a real setup

This file holds no answers yet, only the questions they must answer. Nuxeo
specifics that general knowledge gets wrong (the login flow, where the page
actually scrolls, the breakpoints, how test data gets in) must come from the
author's real project, then be marked as needing review. Don't fill them in
from memory.

**Until then:** follow the project's existing Playwright config and specs.
If there are none, say this reference has no checked Nuxeo setup yet, and ask
the user for each item below that the current AC needs.

## To fill in from the real setup

Each item says why the check needs it.

- **Base URL and Web UI path.** Where the server runs locally (the
  `tonosaman-deploy` container) and the path to the Web UI. A check against
  the wrong instance proves nothing.
- **Login.** How a check logs in (form, basic auth, saved session state),
  which test user it uses, and where the password comes from (environment
  variable name only, never the value). Login once and reuse the session
  state when the project allows it, so each check doesn't pay for the form.
- **Test data.** How a check creates the documents it needs and cleans them
  up (REST API, a seeding script, an imported package), so checks stay
  independent.
- **Ready signal.** What tells the page has finished loading after login or
  navigation (a visible element, a URL), so the first assertion waits for the
  right thing and not for a fixed sleep.
- **Locators that hold.** Which `nuxeo-*` elements expose roles, labels or
  test ids usable from a check, and which don't (then: which visible text to
  use, or whether the project adds test ids).

### Responsive layout

- **Breakpoints.** The widths at which the Web UI layout changes (drawer
  collapsing, menus moving behind a toggle), where they are defined (theme,
  custom element, project CSS), and which of them the project's ACs care
  about.
- **Where it scrolls.** Web UI pages can scroll inside an inner container
  rather than the page itself. Name the element that scrolls, so "no
  horizontal scroll" is asserted where it can actually happen, not on a page
  that never scrolls.
- **Narrow-screen navigation.** What a user does at a small width to reach
  the menu, the document actions and the search (which toggle, which label),
  so a check can follow the same path.
- **Custom elements in scope.** Which of the project's own elements or
  layouts the responsive ACs cover, and whether any of them has its own
  breakpoint.
