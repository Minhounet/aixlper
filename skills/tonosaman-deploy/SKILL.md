---
name: tonosaman-deploy
description: Builds a Java project and runs the fresh artifact in a local container with Docker or Podman — a plain JDK batch, a Spring Boot app, or a Nuxeo server. Keeps a stable runtime image and swaps the built artifact in by bind mount, rebuilds the image only when the runtime itself changes, verifies the container actually came up (or the batch's exit code), and bounds build and log output. Use when the user wants to build and run, deploy, restart or refresh a Java app or batch locally in a container, or to set up the Containerfile/compose file for that.
---

# Build and run in a container

The goal is a fast loop: **build the project, then run the new artifact in a
container**, without rebuilding an image every time. This is for a local
developer loop, not a production pipeline, a registry release, or Kubernetes.

The rules below hold for every runtime. What changes per runtime (the base
image, where the artifact goes, how to tell it is up) lives in `references/`.

## 1. Pick the engine

Use whatever the project or the user already uses: an existing
`compose.yaml`/`docker-compose.yml`, a Makefile target, a script, or what they
said. Otherwise use `podman` if installed, else `docker`. Write every file so
it works with both: name the image file `Containerfile` (Docker reads it with
`-f Containerfile`) and the compose file `compose.yaml`.

Compose is `docker compose` or `podman compose`. `podman compose` is a wrapper
that runs an external provider (`docker-compose` if installed, else
`podman-compose`), and `podman-compose` does not support every compose
feature. When a command behaves unexpectedly under Podman, check which
provider ran before blaming the project.

## 2. Detect the runtime, then read its reference

Check the build files, in this order — the first match wins:

| Marker | Runtime | Read |
|---|---|---|
| `nuxeo-*` dependencies, a `*-package` module with `package.xml`, or a `Nuxeo-Component` manifest entry | Nuxeo | `references/nuxeo.md` |
| `spring-boot-maven-plugin`, or the `org.springframework.boot` Gradle plugin | Spring Boot | `references/spring-boot.md` |
| anything else with a `main` class | Plain JDK batch | `references/jdk-batch.md` |

Several modules with different runtimes, or no clear `main`: ask which one
to run rather than guessing.

## 3. The container files belong to the project

Look for existing container files first and reuse them. The user's own setup
wins over the reference's template, even when the template looks cleaner.

When files need creating, show them (`Containerfile`, `compose.yaml`, and
any build-config change such as a stable jar name) and get one approval
before writing. They go at the project root unless the project already has
a place for them.

**Secrets never go into the image or a committed file.** Credentials,
license keys and registry tokens come from a gitignored `.env` (compose reads
it automatically) or `--env-file`. Check `.gitignore` covers it before writing
one.

## 4. Stable image, swapped artifact

The image holds what rarely changes: the JDK or server, OS packages, baked
config. The artifact is **bind-mounted read-only** at a fixed path inside the
container, so a new build only needs the container recreated, not the image
rebuilt.

- The mounted file needs a **stable name** on the host — a versioned name
  (`app-1.4.2-SNAPSHOT.jar`) breaks the mount at the next version bump. Each
  reference says how to get one.
- **Rebuild the image only when** the `Containerfile` changes, the base image
  or JDK version changes, something baked into the image changes (config,
  OS packages, a server distribution), or dependencies that are *not* inside
  the mounted artifact change. Otherwise, don't.
- **The artifact must exist before the container starts.** With the short
  mount syntax, Docker silently creates a root-owned *directory* where a
  missing file should be, and both the container and the next build then
  fail. Use the long syntax with `create_host_path: false` (each reference
  shows it), so a missing jar is an error that names the path.
- Mount the artifact read-only. On a Podman host with SELinux enforcing
  (Fedora, RHEL), also relabel it (`:Z` in short syntax, `selinux: Z` in long
  syntax), or the container gets "permission denied" reading the file.

## 5. The loop

1. **Build quietly** with the project's own package command (`mvn -q package`,
   `./gradlew -q build`). Don't add `-DskipTests`/`-x test` on your own. Skip
   tests only if the user asks, or if they just passed on the same code (for
   instance at the end of an `igiari-tdd` cycle) — and say that you skipped them.
   A failed build stops the loop: never start a container on a stale artifact.
2. **Recreate the container:**
   - a long-running service: `<compose> up -d --force-recreate <service>`;
   - a batch: `<compose> run --rm <service> [args]` — the container's exit
     code is the batch's result.
3. **Rebuild the image first** (`<compose> build <service>`, or `up --build`)
   only when step 4 says to.

Never run `<compose> down -v`, `volume rm` or `system prune` without asking:
they destroy data volumes (a database, a Nuxeo binary store) that the user
may need.

## 6. Verify it actually came up

"The container started" is not "the app works". Before reporting success:

- **Service:** wait for its readiness signal — a compose `healthcheck`, an
  HTTP endpoint, or a known log line — **with a timeout**. On timeout, or if
  the container exited, report it as failed, with the last log lines.
- **Batch:** report the exit code. Non-zero is a failure, even if the logs
  look harmless. Bounding the output must not hide it: `cmd | tail` returns
  `tail`'s code, always 0 — use `set -o pipefail` or `${PIPESTATUS[0]}`.

Show the URL or port to use when it worked.

## 7. Engines and the Docker API

Some Java tools talk to the Docker API directly rather than running the
`docker` command: Testcontainers, Spring Boot's `build-image` (Buildpacks),
some Maven/Gradle Docker plugins. Under Podman they need its API socket
enabled. If one of them fails to find Docker, read
`references/podman-docker-api.md`.

## Related skills

- **`igiari-tdd`** ends a feature with a full project build. This skill picks
  up from there: run what was just built. A test that needs a container
  (Testcontainers) is still a test in the TDD loop, not this skill's job.
- **`chottomatte-archi`** — `references/nuxeo-addon.md` covers how a Nuxeo
  addon is structured and wired. `references/nuxeo.md` here covers running it.

## Token self-audit

This file loads **in full** whenever the skill triggers and stays resident
for the rest of the session; `references/` files load only if the body
points at one. When asked to reduce token cost — or before adding anything
here — audit in this order and report what you would move, and why:

- **Needed only sometimes?** Material for one framework, one tool's exact
  commands, or a section about extending the skill itself → move to
  `references/` behind a pointer that names the condition precisely.
- **A reference opened on almost every trigger?** Then it costs *more*
  there than inline — a tool call, an extra assistant turn, and a lost
  prefix cache. Bring it back inline.
- **Does a step here run a command?** Its output is tokens too, charged
  every run and kept for the session. Here that means: build with `-q`;
  never stream logs with `-f`; read logs with `--tail` (50 lines is
  usually enough) and filter for `ERROR`/`Exception` before showing more;
  pull and build images quietly (`-q`) unless something failed.

Never split a rule from its own statement: a reference shows how to satisfy
a rule in one environment, it never holds the rule. **Relocate, never
delete** — removing guidance to save tokens is a regression, not a saving.
