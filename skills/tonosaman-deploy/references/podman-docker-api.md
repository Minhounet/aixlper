# Docker-API tools under Podman

Read this when a Java tool that talks to the Docker API — Testcontainers,
Spring Boot's `build-image`, a Docker Maven/Gradle plugin — fails under
Podman with "could not find a valid Docker environment", "Cannot connect to
the Docker daemon" or similar. Written from general knowledge, not yet
checked in this repo: confirm each step against the tool's own Podman
documentation if it doesn't work.

These tools don't run the `docker` command. They connect to the Docker API
socket, which Podman provides only when its API service is running.

## Linux, rootless Podman

```bash
systemctl --user enable --now podman.socket
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
```

Put the `export` in the shell profile (or the IDE's run configuration), so
builds started from the IDE see it too.

## macOS / Windows

The containers run in a Podman machine VM (`podman machine start`).
`podman machine inspect` shows the socket path. Point `DOCKER_HOST` at it,
or turn on Podman Desktop's Docker compatibility setting.

## Testcontainers specifics

- Testcontainers starts a helper container, Ryuk, to clean up after tests.
  Under rootless Podman it often fails. The usual fix is
  `TESTCONTAINERS_RYUK_DISABLED=true`. Containers are then not cleaned up if
  the JVM is killed, so remove leftovers by hand.
- If Testcontainers looks for the socket in the wrong place, set
  `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE` to the socket path seen from inside
  a container.

## Spring Boot `build-image`

Buildpacks also need the socket. Configure it in the plugin
(`<docker><host>...</host></docker>` for Maven, `docker { host = ... }` for
Gradle) or through `DOCKER_HOST`. Rootless Podman may also need
`<bindHostToBuilder>true</bindHostToBuilder>` / `bindHostToBuilder = true`.
Jib (see `spring-boot.md`) avoids all of this.
