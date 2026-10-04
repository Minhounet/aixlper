# Worked examples for the SKILL.md patterns

Read this when applying a pattern from `SKILL.md` and you want its worked
code. Each section is named after the `SKILL.md` section it illustrates;
the rule itself stays there — this file only shows it applied.

## Option instead of null

```java
private Option<DocumentEventContext> toDocumentContext(Event event) {
    return event.getContext() instanceof DocumentEventContext ctx
        ? Option.some(ctx)
        : Option.none();
}
```

## Known failures: Either inside the module, a sealed result for a public API

```java
// inside the module: Either
Either<SyncFailure, SyncResult> execute(CreerDocumentCommand cmd) {
    return gateway.creerDocument(cmd)
        .filterOrElse(SyncResult::isSuccess, r -> new SyncFailure.Rejected(r.errorMessage()));
}

// public API: a sealed result, built from the internal Either with one fold
sealed interface PublishResult {
    record Published(String docId)              implements PublishResult {}
    record Rejected(String docId, String cause) implements PublishResult {}
}

PublishResult publish(String docId) {
    return publishPipeline(docId)
        .fold(failure -> new PublishResult.Rejected(docId, failure.cause()),
              PublishResult.Published::new);
}
```

## 1. Loop → pipeline

```java
// before
List<String> ids = new ArrayList<>();
for (Document d : docs) {
    if (d.isPublished()) {
        ids.add(d.getId());
    }
}
return ids;

// after
return docs.stream()
    .filter(Document::isPublished)
    .map(Document::getId)
    .toList();
```

## 2. A method that builds a function

```java
private Predicate<Invoice> olderThanPredicate(Duration age) {
    return invoice -> invoice.age().compareTo(age) > 0;
}
// .filter(olderThanPredicate(Duration.ofDays(30)))
```

## 3. Expressions, not reassigned locals

```java
// before
String label;
if (status == Status.DRAFT) {
    label = "draft";
} else if (status == Status.PUBLISHED) {
    label = "live";
} else {
    label = "archived";
}

// after
String label = switch (status) {
    case DRAFT -> "draft";
    case PUBLISHED -> "live";
    case ARCHIVED -> "archived";
};
```

## 4. Switch on a sealed type to produce a value

```java
BigDecimal fee(Shipment s) {
    return switch (s) {
        case Shipment.Standard(BigDecimal weight) -> weight.multiply(RATE);
        case Shipment.Express(BigDecimal weight, int hours) -> expressFee(weight, hours);
        case Shipment.Pickup() -> BigDecimal.ZERO;
    };
}
```

## 5. Functional core, imperative shell

```java
void onEvent(Event event) {                              // shell
    Option<Document> doc = loadDocument(event);
    doc.map(publicationPolicy::decide)                   // pure core
       .forEach(this::apply);                            // shell
}
```

## The decision as data

```java
sealed interface Action {
    record Publish(String docId, String target) implements Action {}
    record Notify(String userId, String message) implements Action {}
    record Skip(SkipReason reason)              implements Action {}
}

Action decide(Document doc) { ... }                      // pure

void apply(Action action) {                              // shell
    switch (action) {
        case Action.Publish(String id, String target) -> publisher.publish(id, target);
        case Action.Notify(String user, String msg)   -> mailer.send(user, msg);
        case Action.Skip(SkipReason r)                -> logSkipReason(r);
    }
}
```
