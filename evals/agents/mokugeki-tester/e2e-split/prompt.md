You are working on the Documents screen of a small web app, in UI mode:
change the app until each AC below holds, and prove each one in the browser.

- The app is the folder {{SITE}}/ (index.html, app.css and the ES modules
  under js/), served live at {{BASE_URL}}/index.html (edits show on reload,
  no deploy needed); {{BASE_URL}}/index.html?role=reader shows it as a
  read-only user. No login.
- Checks live in checks/ (current directory); README.md says how they run,
  checks/ac0-page-title.js is the model. Desktop viewport only.
- Load the shoko-playwright skill before the first check and follow it.
- Change only the app's files and the checks. Don't ask questions: decide,
  and say what you decided in the report.

ACs:
- AC1: "A read-only user cannot delete a document."
  Interpreted: as a reader, nothing on the screen removes a document. An
  editor still can.
- AC2: "The heading shows how many documents the list shows, and stays right
  as the list changes."
  Interpreted: the number in the heading always equals the rows visible
  below it.
- AC3: "Documents are listed newest first."
  Interpreted: rows are ordered by their date, the most recent at the top.
- AC4: "Each document shows its author."
  Interpreted: every row shows its document's author.

End with one line per AC, `AC<n>: PASS | FAIL | ENV | HUMAN`, each followed
by its check file and result line.
