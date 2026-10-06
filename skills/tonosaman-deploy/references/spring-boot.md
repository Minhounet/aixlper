# Spring Boot app in a container

Read this when the project uses `spring-boot-maven-plugin` or the
`org.springframework.boot` Gradle plugin and should run as a long-running
service in a container. The mount, Containerfile and wait steps were checked
with Docker 29, Docker Compose and Spring Boot 3.5 on a throwaway project. The
Jib and Podman notes are not checked yet.

Start with `references/jdk-batch.md` "A stable jar name" and the long-mount
rule (`create_host_path: false`). Both apply here unchanged. Spring Boot's
repackaged jar is already a fat jar: one file holds the app and its
dependencies, so a dependency change needs only a rebuild of the jar, not the
image. Ignore `app.jar.original` next to it; that is the thin jar before
repackaging.

## Containerfile

```dockerfile
FROM eclipse-temurin:21-jre
RUN useradd --system --uid 10001 app
USER app
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

The `eclipse-temurin` JRE images include `curl` (not `wget`), which the
health check below uses. On another base image, check it's there first.

## compose.yaml

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Containerfile
    image: <project>-app:dev
    ports:
      - "8080:8080"
    environment:
      JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=75"
      SPRING_PROFILES_ACTIVE: local
    env_file:
      - path: .env          # secrets; gitignored
        required: false
    volumes:
      - type: bind
        source: ./target/app.jar
        target: /app/app.jar
        read_only: true
        bind:
          create_host_path: false
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:8080/actuator/health"]
      interval: 5s
      timeout: 3s
      retries: 3
      start_period: 60s
```

- The health check needs `spring-boot-starter-actuator`. Without it, check a
  real endpoint of the app, or wait for the log line
  `Started <App> in <n> seconds`.
- Spring settings come from environment variables through relaxed binding:
  `server.port` → `SERVER_PORT`, `spring.datasource.url` →
  `SPRING_DATASOURCE_URL`.
- Remote debugging: append
  `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005` to
  `JAVA_TOOL_OPTIONS` and publish `"5005:5005"`.

## Run and verify

```bash
mvn -q package                         # or ./gradlew -q bootJar
docker compose up -d --force-recreate --wait --wait-timeout 120 app
echo "exit=$?"
```

- `--wait` blocks until the health check passes and returns non-zero if the
  container turns unhealthy or exits. That is the "verify" step of the main
  skill in one command. In the checked run, a jar swap and recreate took
  about 6 seconds.
- `--wait` is a Docker Compose feature. `podman-compose` may not support it.
  Without it, poll the health URL from the host with a timeout, e.g. try
  `curl -fsS localhost:8080/actuator/health` every 2 seconds for up to 120
  seconds, and also stop as soon as `compose ps` shows the container exited.
- On failure, filter before showing logs:
  `docker compose logs --tail 200 app | grep -A15 -E "APPLICATION FAILED TO START|ERROR"`.
  Spring Boot's failure analysis prints a `Description:` / `Action:` block
  right after `APPLICATION FAILED TO START`, and that block is usually all
  the user needs.

## Services the app needs

A database or broker goes in the same `compose.yaml`. Use a named volume for
its data, a health check, and make the app wait for it:

```yaml
  db:
    image: postgres:17
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}   # from .env
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 10
  # and under app:
  #   depends_on:
  #     db:
  #       condition: service_healthy
volumes:
  db-data:
```

Recreate only the app (`up -d --force-recreate app`), so the database is not
restarted on every build. Never remove `db-data` without asking.

## A shareable image instead of a mounted jar

The mount is for the local loop. To give someone a ready-made image, copy the
jar into the image, or use **Jib**: it builds the image from Maven/Gradle
without a Containerfile, and its layers keep rebuilds fast.

- Maven: `mvn -q compile jib:dockerBuild -Dimage=<project>:dev`; with Podman
  add `-Djib.dockerClient.executable=podman`.
- Gradle: `./gradlew -q jibDockerBuild`.

Spring Boot's own `spring-boot:build-image` (Buildpacks) also works, but it is
slower and needs the Docker API (see `podman-docker-api.md` under Podman).
Prefer Jib unless the project already uses Buildpacks.
