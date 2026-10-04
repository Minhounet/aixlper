---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Java 21, Vavr is on the classpath. Please rewrite this event listener method;
it works but it's getting hard to follow as we add conditions:

```java
public void handleEvent(Event event) {
    if (!(event.getContext() instanceof DocumentEventContext ctx)) {
        log.debug("skipping non-document event");
        return;
    }
    DocumentModel doc = ctx.getSourceDocument();
    if (!"Invoice".equals(doc.getType())) {
        log.debug("skipping non-invoice: id={}", doc.getId());
        return;
    }
    if (doc.isProxy()) {
        log.debug("skipping proxy: id={}", doc.getId());
        return;
    }
    if (doc.isVersion()) {
        log.debug("skipping version: id={}", doc.getId());
        return;
    }
    archiveService.archive(doc);
}
```

Just give me the rewritten code with a short explanation.

(There is no repository here and nothing to run - answer in your reply.)
