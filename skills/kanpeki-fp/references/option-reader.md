# A reader of external data returns Option — worked example

Read this when refactoring a nullable reader of external data (a Nuxeo
property, a header, a config entry) and the helper that mops up after it.
The rule is in `SKILL.md` under "Option instead of null".

Anything that reads a value out of a system you don't control — a Nuxeo
property, a header, a config entry — is the classic place nulls leak inward.
Have it return `Option<T>` at the point of the read, not a nullable `T` that
every caller then has to remember to check.

The tell that this is needed: a companion helper whose whole job is to clean up
after the nullable one (`nullToEmpty`, `orDefault`, `safeGet`). That helper is
absence-handling smeared across call sites. Once the reader returns `Option`,
it has nothing left to do — delete it.

```java
// before — nullable read, plus a helper to mop up after it
protected String asString(DocumentModel doc, String xpath) {
    Serializable value = doc.getPropertyValue(xpath);
    return value == null ? null : String.valueOf(value);
}
protected String nullToEmpty(String value) {
    return value == null ? "" : value;
}

// after — absence is in the type; the mop-up helper is gone
protected Option<String> asString(DocumentModel doc, String xpath) {
    return Option.of(doc.getPropertyValue(xpath)).map(String::valueOf);
}
```

Each caller then states its own intent instead of inheriting one global
default: `.getOrElse("")` where empty is meaningful, `.filter(s ->
!s.isBlank())` where blank counts as absent, `.getOrElse(() -> buildIt())` for
a computed fallback.
