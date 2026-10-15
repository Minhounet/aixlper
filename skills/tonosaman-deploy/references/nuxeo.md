# Nuxeo server in a container

Read this when the project is a Nuxeo addon or package (`nuxeo-*`
dependencies, a `*-package` module with `package.xml`, or a `Nuxeo-Component`
manifest entry) and it should run on a local Nuxeo server in a container.

## Status: written from one real setup, not yet checked here

This file comes from a working local stack: Podman rootless on WSL2,
`podman-compose`, a Nuxeo LTS base image with Studio and marketplace
packages, and a project with several addon modules. Names below are generic
(`myapp`, `com.example`). The stack has not been run from this repo, and
Podman is not installed in this environment. Treat the commands as the
author's proven steps, and confirm them on the first run.

**If the project already has a container setup** (a compose file plus a
`manager.sh` or `dev-deploy.sh`), follow it. The project's files win over
this reference.

## Container shape

- **Compose provider:** `podman-compose -f ./docker-compose.yaml`, not
  `podman compose`. See `SKILL.md` section 1 for the provider caveat.
- **Network anchor:** a `busybox` service runs `sleep infinity` and publishes
  every host port. Every other service sets `network_mode:
  "service:<anchor>"` and talks to the rest over `127.0.0.1`. Rootless
  Podman does not give each container its own IP the way Docker does here.
- **No `depends_on: condition: service_healthy`:** `podman-compose` ignores
  it. Ordering comes from a wait loop in the Nuxeo service's `command`, which
  polls each backend port with bash `/dev/tcp` and then runs
  `nuxeoctl console`. The author's loops have no timeout. In new work, add
  one, so a dead backend fails instead of hanging.
- **Image:** built by the project's build script under a fixed local tag
  (`myapp:local`). The start command checks the tag exists
  (`podman image inspect`) and stops with a pointer to the build if it does
  not.
- **Startup:** 2–5 minutes on first start, mostly OpenSearch. Nuxeo also
  creates its database tables and indexes on first start.

## Configuration: where a setting can go

Nuxeo reads its properties from `nuxeo.conf`. Environment variables in the
container do nothing on their own.

- **`NUXEOCONF` in the compose file** is the main configuration, as a JSON
  object. Values can be parameterised as `"${VAR:-default}"`, and compose
  fills them from the environment or from `.env`.
- **`conf.d/90-local.conf`**, mounted read-only, is for per-developer
  overrides. The entrypoint appends `conf.d/*` first and then applies
  `NUXEOCONF`, so **a `conf.d` file can add keys but cannot override a key
  that `NUXEOCONF` also sets.** To change one of those, make it a `${VAR}` in
  `NUXEOCONF` and set `VAR` in `.env`.
- **Config changes need a container recreate**, not a Nuxeo restart. The
  project's dev-deploy step restarts Nuxeo in place with the old
  configuration, so it does not pick up a changed `NUXEOCONF`.
- **Secrets:** a real credential goes in `.env` (gitignored), never in the
  compose file. The author's compose has dev-only passwords committed for a
  local stack. Those are acceptable for a local database, but not for real
  credentials, and not as a pattern to copy.

## Getting the addon into the running server

This is the one place where the main skill's "bind-mount the artifact"
rule (`SKILL.md` section 4) does not apply. Nuxeo loads bundles from its own
tree, `nxserver/bundles` and `nxserver/lib`, so the working loop copies the
jars into the running container and restarts only Nuxeo. Kafka, Postgres and
OpenSearch stay up.

1. **Build the module.** Maven is the default and the one used for release.
   A Gradle compile-only option is fine for dev speed. The project's script
   runs `mvn package -DskipTests`. That is the project's choice. The agent's
   own runs still follow `SKILL.md` section 5 and do not add `-DskipTests`
   on their own.
2. **Collect the module's own jars** from `target/` or `build/libs/`.
   Exclude `*-tests.jar`, `*-sources.jar` and `*-javadoc.jar`. **Never
   collect dependency jars this way.** Copy them into `bundles/`, and
   Nuxeo's own xerces or jackson end up duplicated and the server fails on a
   classloader clash.
3. **Stage third-party dependencies separately.** Copy the runtime scope
   into a staging directory outside `target/`, excluding the Nuxeo and
   project groups, then copy only an explicit list into `lib/`:

   ```bash
   mvn -q dependency:copy-dependencies -DincludeScope=runtime \
       -DexcludeGroupIds=org.nuxeo,com.example \
       -DoutputDirectory=<staging dir>
   ```

   Keep the list explicit. Auto-detecting "already provided by the server"
   fails, because the server ships unversioned jars (`el-api.jar`) that
   version-stripping heuristics cannot match. A missing entry fails loudly
   with `NoClassDefFoundError`. Add an entry each time the addon takes a new
   dependency. Why this matters: in a synchronous Nuxeo listener, an `Error`
   is not caught by the event service. It aborts the user operation that
   fired the event, such as a delete, and looks like a broken app.
4. **Copy the logging configuration** if the project has one, to the
   server's `lib/` directory.
5. **Restart Nuxeo:** `podman restart <nuxeo container>`.
6. **Wait for readiness** (see below), with a timeout.

**A container recreate discards the copied jars.** `podman restart` keeps
them, but `down` followed by `up` (which is what a `restart` command often
does) recreates the container from the image. After that, rerun the dev
loop. This is from reading the scripts; it has not been observed here.

## Services and volumes

- **Data volumes** are bind-backed named volumes (`driver_opts: type: none,
  o: bind`) pointing at directories under a host path. Create the directories
  before `up`. The project's start command does this with `mkdir -p`.
- **On WSL, keep data under the Linux home directory**, not `/mnt/c/`. Postgres
  fails on NTFS with "Operation not permitted". Read-only config mounts from
  `/mnt/c/` work fine.
- **The Nuxeo UI is editable from the host.** After start, the project makes
  `nuxeo.war` writable with `podman exec --user 0 ... chmod -R a+w`. The
  author's wait for `WEB-INF` has no timeout. Bound it.
- **Destroying data needs asking first.** Teardown with volume removal, or
  deleting host directories with `sudo rm -rf` (container-owned files need
  root), deletes the binary store, the database and the OpenSearch indices.
  Nuxeo Connect registration is stored in the data volume, so it is lost too.
  Ask before any of this. `SKILL.md` section 5 applies.
- **Image rebuild:** after purging the image, a rebuild does not require
  re-registering with Nuxeo Connect.

## Verify it came up

- **Ready signal:** the log line `Nuxeo Platform started`. Wait for it with a
  timeout. On timeout, or if the container exited, report failure and the
  last 50 log lines, filtered for `ERROR|Exception`
  (`podman logs --tail 50 <container>`).
- **Not checked:** an HTTP probe of the Nuxeo context path as a second
  readiness check. The author uses the log line.
- **Debugging:** a JDWP port is published (`address=*:<port>`). It is
  published only for local debugging.
- **Runtime log level:** the project may expose an automation operation that
  changes one logger's level without a restart. It resets on the next
  restart.

## Podman quirks

- **`podman logs -f` fails with a journald error** unless the default log
  driver is file-based. Set it once in `~/.config/containers/containers.conf`
  under `[containers]` as `log_driver = "k8s-file"`, then restart the stack.
  `SKILL.md` section 5 says never to stream logs with `-f` anyway. Use
  `--tail`.
- **`podman machine` on macOS and Windows** is not covered by this setup.
  Only the WSL2 rootless setup has been seen.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `NoClassDefFoundError` naming a class | A dependency missing from the `lib/` list (step 3 above) |
| Server fails after a deploy, `SchemaManager` or Tomcat refuses `/nuxeo` | A duplicated server library in `bundles/` (step 2) |
| A `conf.d` setting is ignored | The key is also in `NUXEOCONF`; parameterise it instead |
| Changed config has no effect | Container not recreated; a Nuxeo restart keeps the old config |
| Postgres "operation not permitted" | Data directory on NTFS (`/mnt/c/`) |
| Nuxeo waits for backends forever | A backend is down; check `podman ps` and that backend's logs |
| Jars gone after a restart | Container recreated; rerun the dev loop |

## What is not checked yet

- Anything with Docker instead of Podman, on this layout.
- How long a dev-loop restart takes, measured from the server log.
- An HTTP readiness probe in place of the log line.
- The `podman-docker-api.md` steps for this stack. Nothing here calls the
  Docker API directly.
