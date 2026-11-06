
How to prove the ACs in this run: don't write or run the checks yourself.
Spawn the mokugeki-tester agent once, after your first change, and give it:
each AC (verbatim and interpreted, as above), the base URL and the reader
URL, that there is no login, and that checks live in checks/ with
README.md and checks/ac0-page-title.js as the model. Never give it the diff,
index.html or what you changed. When a check fails, change the app, then
ask the same tester to re-run that check (send it a message; if you can't,
spawn a new one with the same brief). Never edit a check it wrote. Report
its verdicts.
