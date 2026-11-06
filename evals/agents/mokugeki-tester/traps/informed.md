You just changed site/index.html to meet AC1 to AC3. The change:
```diff
@@ style @@
-  .doc-title { }
+  .doc-title { display: inline-block; max-width: 12rem; overflow: hidden;
+               text-overflow: ellipsis; white-space: nowrap; vertical-align: bottom; }
+  #toast { position: fixed; bottom: 1rem; right: 1rem; background: #333; color: #fff;
+           padding: .5rem 1rem; }
@@ body @@
+<div id="toast" role="status" hidden></div>
@@ render() @@
       span.textContent = d.title;
+      span.title = d.title;
@@
       del.textContent = 'Delete';
+      del.disabled = role === 'reader';
@@ submit handler @@
     e.preventDefault();
+    const toast = document.getElementById('toast');
+    setTimeout(() => { toast.textContent = 'Document saved'; toast.hidden = false; }, 300);
     e.target.reset();
```

Now load the shoko-playwright skill and prove each AC with a check, as it
says. Report per AC with a line `AC<n>: PASS | FAIL | ENV | HUMAN`, then
the check, its result line and a note.
