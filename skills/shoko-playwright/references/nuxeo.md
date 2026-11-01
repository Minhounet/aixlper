# Nuxeo Web UI under Playwright

Read this when the app under test is Nuxeo Web UI (URLs under `/nuxeo/ui/`,
`nuxeo-*` elements in the page), and above all when the change is a custom
page the project adds to the Web UI, including making one responsive.

## Status: not checked against a real setup

There is no reference Nuxeo setup behind this file, and none is coming: the
specifics differ per project and per server. So this file holds no answers,
only the questions a check needs answered, each with why. Answer them each
time from the project being worked on (its source, its config, its existing
specs), and ask the user only what the project doesn't show. Never answer
them from general Nuxeo knowledge.

## What the scope is: the project's custom pages

The usual case is a custom page: an element, a layout or a slot contribution
that the project's own Web UI addon adds. The ACs are about that page, not
the stock Web UI. So the checks open that page, and assert only on it:

- **Find the page in the project's source** before writing a check: the
  custom element, where it is contributed (route, menu, slot, tab), and what
  data it needs to show something. The check reaches it the way a user
  would, through that entry point.
- **Leave the stock Web UI out of the assertions.** If the surrounding Web
  UI breaks at some size, that is a finding to report, not a failure of the
  custom page's AC.

## Questions to answer before the first check

- **Base URL and Web UI path.** Where the server under test runs (the
  `tonosaman-deploy` container, or whatever the project uses). A check
  against the wrong instance proves nothing.
- **Login.** How a check logs in (form, basic auth, saved session state),
  which test user, and where the password comes from (environment variable
  name only, never the value). Log in once and reuse the session state when
  the project allows it, so each check doesn't pay for the form.
- **Test data.** How a check creates the documents the page needs and cleans
  them up (REST API, a seeding script, an imported package), so checks stay
  independent.
- **Ready signal.** What tells the custom page has finished loading (a
  visible element, a URL), so the first assertion waits for the right thing
  and not for a fixed sleep.
- **Locators that hold.** Which parts of the custom page expose roles,
  labels or test ids. The project owns this element, so when a locator is
  missing, adding a test id or an accessible label to it is a valid change.

### Responsive custom pages

- **Breakpoints.** Read them from the custom page's own styles (its media
  queries or the theme values it uses) and from the AC. If they disagree,
  that is a question for the user, not a choice to make.
- **Where it scrolls.** A custom page can sit inside a container that does
  the scrolling, not the page itself. Find which element scrolls, so "no
  horizontal scroll" is asserted where it can actually happen.
- **Narrow-screen entry.** How a user reaches the custom page at a small
  width (a toggle, a menu), so the check follows the same path instead of
  jumping straight to the URL, unless the AC is only about the page itself.
