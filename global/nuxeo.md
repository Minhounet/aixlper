# Nuxeo

## Listener event filtering

Always declare which events a listener handles in the OSGI-INF XML (`<event>` elements), not in Java.

```xml
<listener name="myListener" class="..." async="true" postCommit="true">
  <event>documentCreated</event>
</listener>
```

For `PostCommitFilteringEventListener`, `acceptEvent()` must return `true` — the XML is the single source of truth. Never re-check the event name in `acceptEvent()` or `handleEvent()` when the XML already restricts it.

## Component documentation

Always add a `<documentation>` tag inside every OSGI-INF component definition. It appears in the Nuxeo Admin Center when browsing components and makes the addon self-documenting.

```xml
<component name="com.example.myaddon.MyComponent" version="1.0">

  <documentation>
    One or two sentences describing what this component registers and why.
  </documentation>

  <extension target="..." point="...">
    ...
  </extension>

</component>
```
