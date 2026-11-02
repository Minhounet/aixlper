# Nuxeo server in a container

Read this when the project is a Nuxeo addon or package (`nuxeo-*`
dependencies, a `*-package` module with `package.xml`, or a `Nuxeo-Component`
manifest entry), or a Nuxeo Studio project (Designer or Modeler), and it
should run on a Nuxeo server in a container.

## Status: partly filled from the author's setup

The Studio part below comes from the author's own setup, described in
conversation, and has not been run by this skill yet. Everything else
(image, services, `nuxeo.conf`) is still unknown, and must not be filled
from memory.

**For the unknown parts:** don't generate a Nuxeo `Containerfile` or
`compose.yaml` from scratch. Look for the project's existing container setup
and follow it. If there is none, say this skill has no checked Nuxeo setup
yet, and ask the user for theirs, or for permission to draft one marked as
unverified.

## Nuxeo Studio projects: Designer and Modeler

A Studio project has two halves, and they reach the running server in two
different ways. Know which half a change belongs to before making it.

- **Studio Designer (Web UI: elements, layouts, pages).** The author keeps a
  local copy of the Studio project, and that folder is synced into the
  container through a Podman volume. A file changed locally is what the
  server serves. So a Designer change is an ordinary file edit: edit it in
  the local project, reload the page, run the check. No image rebuild, no
  restart.
- **Studio Modeler (document types, schemas, vocabularies, automation,
  other configuration).** Its history is owned by Studio itself; there is no
  git you control outside it. So a Modeler change is never made by editing
  files: the user makes it in Studio, then deploys it with Studio's **hot
  reload**. Your part is to say exactly what to change in Modeler and why,
  wait until the user says it is hot-reloaded, then check the app is up and
  run the check again. Never edit Modeler's generated output in the volume or
  the repo: the next hot reload overwrites it, and Studio never sees it.

When a change needs both (a new document type and the page that shows it),
the Modeler half goes first: the Designer page can't be checked until its
type exists on the server.

Still to confirm on first real use: which folder of the local project the
volume maps, and how long a hot reload takes before the server answers.

## Questions the real setup must answer

- **Image:** which Nuxeo version and image, and how registry credentials are
  provided (never in a committed file).
- **Getting the code in:** install the marketplace package when the image is
  built, at startup, or by mounting the bundle jar directly. Which of these
  fits the main skill's "stable image, swapped artifact" rule?
- **Refreshing an addon build:** does a new build of the project's own Java
  addon need a container recreate, a Nuxeo restart, or neither? How long
  does a restart take? (Studio changes are covered above.)
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
