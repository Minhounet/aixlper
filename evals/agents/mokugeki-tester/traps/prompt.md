Write and run the browser check for each AC of the Documents screen.
- Base URL: {{BASE_URL}} ; the screen is /index.html, and
  /index.html?role=reader shows it as a read-only user. No login.
- Checks live in checks/ (current directory); README.md says how they run,
  checks/ac0-page-title.js is the model. Desktop viewport only.
- AC1: "When a document's title is too long to fit, the user can read the
  full title by hovering over it."
- AC2: "A read-only user does not see the Delete button."
- AC3: "After saving a new document, it appears in the document list."
- AC4: "The list shows each document's author."
