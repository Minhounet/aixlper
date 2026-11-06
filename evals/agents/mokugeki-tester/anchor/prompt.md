Write and run the browser check for each AC of the Documents screen.
- Base URL: {{BASE_URL}} ; the screen is /index.html, and
  /index.html?role=reader shows it as a read-only user. No login.
- Checks live in checks/ (current directory); README.md says how they run,
  checks/ac0-page-title.js is the model. Desktop viewport only.
- AC1: "Documents are listed newest first."
  Interpreted: the rows are ordered by their date, the most recent at the top.
- AC2: "Searching finds documents whose title contains the text typed, whatever its case."
  Interpreted: typing any part of a title, in any mix of upper and lower
  case, shows that document.
- AC3: "A read-only user cannot delete a document."
  Interpreted: as a reader (?role=reader), nothing on the screen removes a document.
- AC4: "Each document shows its author."
  Interpreted: every row shows the document's author.
