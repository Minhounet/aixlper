# Plain JDK batch in a container

Read this when the project is a plain Java program with a `main` class (no
Spring Boot, no Nuxeo) and it should run in a container: it starts, does its
work, and exits. Checked with Docker 29 and Docker Compose on a throwaway
Maven project; the Podman notes are not checked yet.

## A stable jar name

The mount needs the same host path every build. Ask before changing the build:

- Maven: `<build><finalName>app</finalName></build>` gives `target/app.jar`.
- Gradle: `tasks.jar { archiveFileName = "app.jar" }` gives `build/libs/app.jar`.

The jar must be runnable with `java -jar`, so its manifest needs `Main-Class`
(`maven-jar-plugin` `<archive><manifest><mainClass>`, or
`tasks.jar { manifest { attributes("Main-Class" to "...") } }`).

**Dependencies.** A batch with no dependencies, or a shaded/fat jar
(`maven-shade-plugin`, the Gradle Shadow plugin), is one file: mount it and
you're done. A thin jar with separate dependencies also needs a mount for its
`lib/` directory (e.g. `maven-dependency-plugin:copy-dependencies` into
`target/lib`), and `ENTRYPOINT ["java", "-cp", "/app/app.jar:/app/lib/*", "<main class>"]`.

## Containerfile

```dockerfile
FROM eclipse-temurin:21-jre
RUN useradd --system --uid 10001 app
USER app
WORKDIR /app
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

- Match the JRE version to the project's `release`/toolchain version.
- No `COPY` of the jar: it is mounted, so the image survives every build.
- JVM options go in `JAVA_TOOL_OPTIONS` (the JVM reads it on its own), so the
  `ENTRYPOINT` stays in exec form and arguments pass through untouched. The
  JVM prints `Picked up JAVA_TOOL_OPTIONS: ...` on stderr for every run;
  that line is expected, not an error.

## compose.yaml

```yaml
services:
  batch:
    build:
      context: .
      dockerfile: Containerfile
    image: <project>-batch:dev
    environment:
      JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=75"
    volumes:
      - type: bind
        source: ./target/app.jar
        target: /app/app.jar
        read_only: true
        bind:
          create_host_path: false
          # selinux: Z     # Podman on an SELinux host
      - ./data:/data       # input/output files, if the batch has any
```

**Use the long mount syntax with `create_host_path: false`.** With the short
form (`./target/app.jar:/app/app.jar:ro`), if the jar doesn't exist yet Docker
silently creates a **root-owned directory** named `app.jar` in its place. The
container then fails with `Invalid or corrupt jarfile`, and the next build may
fail because a directory sits where the jar should go. With
`create_host_path: false`, Docker refuses to start and names the missing
path. If the directory was already created, remove it before building
(`rm -rf target/app.jar`; it may need `sudo` because root owns it).

## Run

```bash
mvn -q package                         # or ./gradlew -q build
docker compose run --rm batch arg1 arg2
echo "exit=$?"
```

- `run --rm` passes the arguments to the `ENTRYPOINT` and returns the
  container's exit code. That code is the batch's result: report it.
- **Bounding output must not hide that code.** `... | tail -20` returns
  `tail`'s exit code, which is always 0. Use `set -o pipefail`, or read
  `${PIPESTATUS[0]}` in bash, or redirect output to a file and read the end
  of it.
- `run` builds the image the first time if it is missing. After that, rebuild
  with `docker compose build -q batch` only when the main skill's rebuild
  rules say so.

## Files the batch writes

The container runs as uid 10001. A mounted host directory it must write to
has to be writable by that user, or the batch fails with "permission
denied". Options, from simplest:

- run as your own user: `user: "${UID}:${GID}"` in the compose file, with `UID`
  and `GID` exported or set in `.env` (bash sets `UID` but doesn't export it);
- rootless Podman: `userns_mode: keep-id`, which maps your host user into
  the container;
- make the directory writable for everyone (fine for a scratch directory,
  not for real data).
