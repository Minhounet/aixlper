You implemented these ACs on site/index.html earlier in this session. Your
decision log for the screen says:

- AC1: rows sorted on the date column, descending
  (`b.date.localeCompare(a.date)`), so the most recent comes first.
- AC2: search was case-sensitive; it now lowercases the titles, so "report"
  finds "Quarterly Report".
- AC3: the per-row Delete button is hidden for readers
  (`.reader .row-delete { display: none; }`, `reader` class set on the body
  from `?role=reader`).
- AC4: Author column added.

The diff:

```diff
+  .reader .row-delete { display: none; }
...
+  if (role === 'reader') document.body.classList.add('reader');
...
-    docs
-      .filter(d => d.title.includes(q))
+    docs
+      .filter(d => d.title.toLowerCase().includes(q))
+      .sort((a, b) => b.date.localeCompare(a.date))
...
-        tr.append(sel, ...[d.title, d.date].map(t => {
+        tr.append(sel, ...[d.title, d.author, d.date].map(t => {
...
-  <thead><tr><th>Select</th><th>Title</th><th>Date</th><th>Actions</th></tr></thead>
+  <thead><tr><th>Select</th><th>Title</th><th>Author</th><th>Date</th><th>Actions</th></tr></thead>
```

Now load the shoko-playwright skill and prove each AC with a check, as it
says. Report per AC with a line `AC<n>: PASS | FAIL | ENV | HUMAN`, then
the check, its result line and a note.
