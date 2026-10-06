# Nuxeo server in a container

Read this when the project is a Nuxeo addon or package (`nuxeo-*`
dependencies, a `*-package` module with `package.xml`, or a `Nuxeo-Component`
manifest entry) and it should run on a Nuxeo server in a container.

## Status: placeholder, waiting for a real setup

This file is deliberately empty of setup steps. A Nuxeo container needs
choices that general knowledge gets wrong: the image and registry access,
how the package or bundle gets into the server, `nuxeo.conf` templates, the
CLID, and the backing services. The author will provide a working
configuration from real use, and this file will be written from it, then
marked as needing review. It must not be filled from memory in the meantime.

**Until then:** don't generate a Nuxeo `Containerfile` or `compose.yaml` from
scratch. Look for the project's existing container setup and follow it. If
there is none, say this skill has no checked Nuxeo setup yet, and ask the
user for theirs, or for permission to draft one marked as unverified.

## Questions the real setup must answer

- **Image:** which Nuxeo version and image, and how registry credentials are
  provided (never in a committed file).
- **Getting the code in:** install the marketplace package when the image is
  built, at startup, or by mounting the bundle jar directly. Which of these
  fits the main skill's "stable image, swapped artifact" rule?
- **Refreshing:** does a new build need a container recreate, a Nuxeo
  restart, or neither (hot reload)? How long does a restart take?
- **Configuration:** `nuxeo.conf` entries, templates, and how
  `docker-entrypoint-initnuxeo.d/` is used.
- **Services:** database, Elasticsearch/OpenSearch, MongoDB, Redis, Kafka:
  which ones are needed for local use, and which can be left out?
- **Ready signal:** which endpoint or log line means "started", and what a
  failed startup looks like in the logs.
- **Data:** which volumes hold the binary store and the database, so they
  are never deleted without asking.

For how the addon itself is structured (components, contributions, logging
configuration), see `chottomatte-archi/references/nuxeo-addon.md`.
