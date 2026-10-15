<h1>🦭 MYAPP | Local Podman Setup</h1>

This guide walks you through building and running MyApp locally with Podman.

---

<h2>📋 Table of contents</h2>

[TOC]

---

## 1. Prerequisites

### 1.1. Software

| Tool         | Version    | Notes                                 |
|--------------|------------|---------------------------------------|
| **WSL 2**    | Ubuntu 20+ | Required on Windows                   |
| **Podman**   | 4+         | Rootless, installed inside WSL        |
| **Maven**    | 3.9+       | For Java builds                       |
| **JDK**      | 21         | OpenJDK 21                            |
| **yq**       | 4+         | YAML parsing in the build script      |
| **dos2unix** | 7+         | Windows → Unix line ending conversion |

### 1.2. Tokens and access

Add the following variables to your `~/.bashrc` (or `~/.zshrc`):

```bash
export HARBOR_USER="<user_id_lowercase>"
export HARBOR_TOKEN="<see below>"
export DEPOSIT_TOKEN="<see below>"
export BASECORE_ADDONS_PATH="<wsl path to myapp_addons project>" 
```

`BASECORE_ADDONS_PATH` points to the root of the `myapp_addons` project on your machine (e.g. `/mnt/c/projects/myapp_addons`). It is only required when using `./manager.sh build --local <addon>`.

Then reload: `source ~/.bashrc`

#### 1.2.1. HARBOR_TOKEN

- Go to [https://registry.example.com](https://registry.example.com) and log in via **SSO**
- Open the user menu (top right) and click on "**Profil Utilisateur**"
- Copy the "**Secret CLI**" value — that is your `HARBOR_TOKEN`

#### 1.2.2. DEPOSIT_TOKEN

- Go to [https://artifactory.example.com](https://artifactory.example.com) and log in via **SSO**
- Then open the user menu (top right) and click "**Edit Profile**"
- Scroll down to "**Authentication Settings**" and click on "**Generate an Identity Token**"
- Copy the generated value into your `DEPOSIT_TOKEN` variable in `~/.bashrc`

### 1.3. EXTSYNC

- **Optional, Ext Sync sync** — same `~/.bashrc`. All default to a safe,
  disabled state, so leave them out unless you are working on the sync flow :
    - `EXTSYNC_SYNC_ENABLED` (default `false` — NoOp gateway, nothing leaves the machine)
    - `EXTSYNC_SYNC_ENDPOINT` (default: REC1 recette, the `extsync_soap_call.sh` default)
    - `EXTSYNC_SYNC_AUTH_MODE` (default `USERNAME_TOKEN` — what the direct backend leg reads)
    - `EXTSYNC_SYNC_USERNAME` (your user ID; **required** once enabled)
    - `EXTSYNC_SYNC_PASSWORD` (only used by `BASIC`; `USERNAME_TOKEN` sends no password)
    - `EXTSYNC_SYNC_TIMEOUT` (default `60000`, matching the script's `EXT_TIMEOUT=60`)

  These are read by docker-compose's `${...}` substitution and baked into `NUXEOCONF`;
  Nuxeo resolves properties from `nuxeo.conf`, never from the container environment, so an
  env var alone does nothing. A change needs `manager.sh restart` (the container must be
  recreated) — `dev-deploy.sh` restarts Nuxeo in place and keeps the old config.

---

## 2. Project structure

```
myapp_nuxeo_addons/
  settings.xml                                  # Maven config (Artifactory)
  addons_artifacts.yml                          # Artifacts to build/download
  myapp_nuxeo_podman/
    manager.sh                                  # Single entry point: build, start, stop, restart, …
    docker-compose.yaml                         # Main compose file (all services)
    templates                                   # Cover page artifact
```

> [!NOTE]
> The `myapp_nuxeo_podman` setup shares configs from `myapp_nuxeo_docker`, mounted read-only — no duplication.

---

## 3. Build the Podman image

The `build` command (backed by `scripts/build-local.sh`) does the following:

1. Validates environment variables (`DEPOSIT_TOKEN`, `HARBOR_USER`, `HARBOR_TOKEN`)
2. Builds MYAPP Maven modules locally (`mvn clean verify`)
3. Downloads BaseCore (base) artifacts from Artifactory
4. Downloads Studio packages from Nexus
5. Downloads Hyland Marketplace packages from Nexus
6. Logs into the MYAPP Harbor registry
7. Builds the Podman image

> [!WARNING]
> Before launching the script, first, log in to [Harbor](https://registry.example.com) in your browser to load the SSO session cookie — the build script needs it to pull the base images.

```bash
cd /mnt/c/path/to/project/myapp_nuxeo_addons/myapp_nuxeo_podman
```
```bash
dos2unix manager.sh scripts/build-local.sh
```
```bash
./manager.sh build
```

Produces the `myapp:local` image.

> [!NOTE]
> The first build takes **10–20 min** (Maven dependencies + base images). Subsequent builds are faster thanks to the Maven cache.

### 3.1. Podman image stack

```
svr_nuxeo_server (Harbor)    ← Tomcat + Nuxeo LTS 2025 + hotfixes + Web UI + SAML
        │
        ▼
myapp-nx-base (Harbor)      ← + Studio socle + myapp-socle-package + Opensearch
        │
        ▼
    myapp:local              ← + Studio MYAPP + MYAPP addons + configs
```

### 3.2. Dockerfile stages

```dockerfile
FROM myapp-nx-base AS myapp    # Base with addons
FROM myapp AS aprod             # + SAML IdP metadata APROD
FROM myapp AS prod              # + SAML IdP metadata PROD
```

The local build uses `--target=aprod`.

### 3.3. Choosing the BaseCore base image

The Dockerfile uses a build argument to select the BaseCore base image. The default is the Harbor image pinned in the `ARG BASECORE_IMAGE=...` line at the top of `myapp_nuxeo_docker/docker_images/Dockerfile`.

#### 3.3.1. Harbor image (default)

```bash
./manager.sh build
```

> [!NOTE]
> To update the pinned Harbor image version, edit the `ARG BASECORE_IMAGE=...` line in `myapp_nuxeo_docker/docker_images/Dockerfile` with the new tag.

#### 3.3.2. Local BaseCore base image

```bash
./manager.sh build --local
```

Passes `--build-arg BASECORE_IMAGE=base:local` to Podman — no Dockerfile edits needed. All BaseCore addons still come from Artifactory.

> [!NOTE]
> Harbor login is skipped when `--local` is used — the base image is already present locally, so no pull from Harbor is needed.

#### 3.3.3. Local addon builds (dev loop)

Build one or more BaseCore addons from your local source instead of downloading them from Artifactory. All other addons are still downloaded normally.

👉 Example :
```bash
./manager.sh build --local myapp-trash-package
./manager.sh build --local myapp-trash-package myapp-lifecycle-package ...
```

For each named addon, the script:
1. Runs `mvn clean verify` inside `$BASECORE_ADDONS_PATH/<module>/` (e.g. `myapp-trash/`)
2. Picks up the built zip from `<module>/<addon>/target/`
3. Uses it in the Podman image instead of the Artifactory version

> [!NOTE]
> Addons **not** named still come from Artifactory at the version declared in `addons_artifacts.yml`.

The build log clearly indicates the source of each addon:

```
📦 Resolving BaseCore packages
🔨 Building myapp-trash-package locally...
-> myapp-trash-package-XXX.YYY.zip           ⚡ [LOCAL BUILD: myapp-trash-package-XXX.YYY.zip]
-> myapp-lifecycle-package-XXX.YYY.zip        ✅ [Artifactory]
-> myapp-banner-package-XXX.YYY.zip           ✅ [Artifactory]
...
```

> [!NOTE]
> `BASECORE_ADDONS_PATH` must be set in your `~/.bashrc` (see [§ 1.2](#12-tokens-and-access)).
>
> The `--local` flag before addon names also sets `BASECORE_IMAGE=base:local` as the Podman base image — combine both behaviors in one command.

### 3.4. Package installation order

The Dockerfile installs packages in two steps:

1. **Marketplace first** — Hyland platform packages (S3)
2. **MYAPP addons second** — BaseCore addons + project-specific packages + Studio bundle

This ensures marketplace dependencies are available when MYAPP addons are installed.

---

## 4. Start the services

```bash
cd /mnt/c/path/to/project/myapp_nuxeo_addons/myapp_nuxeo_podman
```
```bash
dos2unix manager.sh scripts/build-local.sh
```
```bash
./manager.sh start
```

**Available commands** 💻

| Command                                         | Description                                                            |
|-------------------------------------------------|------------------------------------------------------------------------|
| `./manager.sh build`                            | Build the local Podman image (BaseCore image comes from Harbor)         |
| `./manager.sh build --local`                    | Same, but use `base:local` as base image                            |
| `./manager.sh build --local <addon> [<addon>…]` | Same, but BaseCore addons come from local source, rest from Artifactory |
| `./manager.sh start`                            | Start all services in the background                                   |
| `./manager.sh stop`                             | Stop services (data is preserved)                                      |
| `./manager.sh restart`                          | Stop then restart                                                      |
| `./manager.sh register`                         | Register the instance with Nuxeo Connect (once after first start)      |
| `./manager.sh destroy`                          | Stop and **delete all data** (volumes)                                 |
| `./manager.sh purge`                            | Remove the `myapp:local` image                                         |
| `./manager.sh seed`                             | Initialize plan classement, templates and users                        |
| `./manager.sh seed-users`                       | Initialize users only                                                  |
| `./manager.sh clean [paths]`                    | Clean plan classement (extra paths passed as extra args)               |

---

## 5. Nuxeo Connect registration

Studio hot reload requires the Nuxeo instance to be registered with Nuxeo Connect. Registration is **persistent in the data volume** — it survives container restarts and image rebuilds, as long as the volume is not destroyed.

### 5.1. Prerequisites

The Studio package version must be a `SNAPSHOT` build. Verify in `addons_artifacts.yml` that the Studio artifact version ends with `-SNAPSHOT`. If it does not, update it and rebuild the image before registering.

### 5.2. Register the instance (once per volume)

Nuxeo must be running. Then:

```bash
./manager.sh register
```

You will be prompted interactively:

```
Username: <your-email>
Please enter your token: <NUXEO_TOKEN>
Available projects:
        - myapp-example
Project name: myapp-example
Instance type (dev|preprod|prod): [dev]
Description: myapp local podman
```

> [!NOTE]
> Your `NUXEO_TOKEN` is available at [connect.nuxeo.com](https://connect.nuxeo.com/nuxeo/site/connect/tokens).

> [!WARNING]
> ➜ Registration is stored in the `nuxeo_data` volume (`$HOME/podman-volumes/myapp/nuxeo_data/instance.clid`).
>
> ➜ Running `./manager.sh destroy` wipes the volume — you must register again after.
>
> ➜ Rebuilding the image alone (`./manager.sh purge` + `./manager.sh build`) does **not** require re-registration.

### 5.3. Test the hot-reload

Once registered, trigger a hot reload from your REST client, or via `curl`:

```http
POST http://localhost:28080/nuxeo/api/v1/automation/Service.HotReloadStudioSnapshot
Authorization: Basic <base64(Administrator:change-me)>
Content-Type: application/json
{
    "input": {},
    "params": {},
    "context": {}
}
```

➜ A successful response confirms the Studio SNAPSHOT was pulled and applied without restarting the server.

```json
  [
    {
      "status": "success",
      "message": "Studio package installed."
    }
  ]
```

---

## 6. Services and ports

> [!NOTE]
> Port convention: **`2` + standard port** (another stack uses `1` + standard port). Both stacks can run simultaneously.

| Service                    | URL                                                                     | Credentials                       |
|----------------------------|-------------------------------------------------------------------------|-----------------------------------|
| **Nuxeo**                  | http://localhost:28080                                                  | `Administrator` / `Administrator` |
| **Mailpit** (email viewer) | http://localhost:28025                                                  | —                                 |
| **pgAdmin**                | http://localhost:28081                                                  | `admin@example.com` / `admin`     |
| **OpenSearch Dashboards**  | http://localhost:25601                                                  | —                                 |
| **Kafka UI**               | http://localhost:29080                                                  | —                                 |
| **Kafdrop**                | http://localhost:29001                                                  | —                                 |
| **PostgreSQL**             | `localhost:25432`                                                       | `nuxeo` / `nuxeo`                 |
| **OpenSearch**             | http://localhost:29200                                                  | —                                 |
| **Nuxeo Debug**            | `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:28787` | —                                 |

> [!NOTE]
> Mailpit intercepts all emails sent by Nuxeo (notifications, broadcasts). No real emails are delivered.

---

## 7. Startup and health

### 7.1. Network architecture (Podman-specific)

Podman runs rootless and does not support bridge networks with per-container IPs the same way Docker does. All services share a single network namespace via a `myapp-network-anchor` container (a minimal `busybox` that holds the ports open). Every service uses `network_mode: "service:myapp-network-anchor"` and communicates over `127.0.0.1`.

```
┌──────────────────────────── myapp-network-anchor ─────────────────────────────┐
│  postgres:25432  kafka:29092  opensearch:29200/29201  nuxeo:28080  ...        │
└───────────────────────────────────────────────────────────────────────────────┘
```

### 7.2. Startup order

`podman-compose` does not support `depends_on: condition: service_healthy`. Ordering is handled by a wait loop in the Nuxeo container that polls each backend port before starting:

```
myapp-network-anchor starts
       │
       ├──▶ postgres, kafka, opensearch-node1, opensearch-node2 (in parallel)
       │
       └──▶ Nuxeo (polls 29200, 29201, 25432, 29092 — starts only when all respond)
```

Full startup takes **2–5 minutes**. OpenSearch is the slowest service (`start_period: 120s`). On first startup, Nuxeo also initializes PostgreSQL tables and OpenSearch indexes.

### 7.3. Follow the logs

```bash
# Nuxeo only
podman logs -f myapp-nuxeo
```
```bash
# Any other service
podman logs -f myapp-postgres
podman logs -f myapp-opensearch-node1
podman logs -f myapp-kafka
```

> [!NOTE]
> If `podman logs -f` returns an error about the journald log driver, configure the default log driver once:
> ```bash
> mkdir -p ~/.config/containers
> echo -e '[containers]\nlog_driver = "k8s-file"' >> ~/.config/containers/containers.conf
> ```
> Then restart the stack — new containers will use file-based logs.

### 7.4. Nuxeo is ready when...

Look for this line in the Nuxeo logs:

```
Nuxeo Platform started
```

---

## 8. WSL specifics (Windows)

All data volumes (PostgreSQL, Kafka, OpenSearch, Nuxeo) are stored under `$HOME/podman-volumes/myapp/` on the WSL ext4 filesystem. This avoids NTFS permission errors (`Operation not permitted`) that occur when bind-mounting from `/mnt/c/`.

Directories are created automatically by `manager.sh start` — no manual setup needed.

> [!NOTE]
> Read-only mounts (configs) still come from `/mnt/c/` and work fine on NTFS.

---

## 10. Troubleshooting

### 10.1. PostgreSQL "operation not permitted"

This means a data volume ended up on NTFS (`/mnt/c/`). Verify that `VOLUMES_DIR` in `manager.sh` points to `$HOME/podman-volumes/myapp` (WSL ext4), then run `./manager.sh destroy && ./manager.sh start` to recreate the volumes in the right location.

### 10.2. Nuxeo stuck waiting for backends

Check container status:
```bash
podman ps --format "table {{.Names}}\t{{.Status}}"
```

If a service is `unhealthy`, or failed to start, inspect its logs:
```bash
podman logs <container>
```

### 10.3. Rebuild image after code changes

```bash
./manager.sh purge
```
```bash
./manager.sh build
```
```bash
./manager.sh restart
```

### 10.4. Change log level at runtime

Use `MyApp.SetLogLevel` to change a logger's level on the running instance without restarting Nuxeo.

```bash
curl -K -u Administrator:change-me -X POST \
  -H 'Content-Type: application/json' \
  -d '{"params":{"logger":"com.example.myapp","level":"DEBUG"}}' \
  http://localhost:28080/nuxeo/api/v1/automation/MyApp.SetLogLevel
```

➜ Expected response: `com.example.myapp -> DEBUG`. Restore the normal level with the same call and `"level":"INFO"`.

> [!WARNING]
> Accepted levels are `OFF`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`.
>
> An unknown level is **rejected** — a typo cannot silently flip the instance to `DEBUG`.

> [!NOTE]
> The change is **not persistent**: a container restart resets the level to `INFO` (set by `myapp.extsync.log.level`). To change it permanently, update the container configuration. Only the level can be changed at runtime — appenders and format require a redeployment.

### 10.5. Full reset

```bash
# Stop and wipe all data
./manager.sh destroy
```

---

## 11. Quick reference

```bash
# Build + start from scratch
cd /mnt/c/path/to/project/myapp_nuxeo_addons/myapp_nuxeo_podman
./manager.sh build
./manager.sh start
```
```bash
# Follow Nuxeo startup
podman logs -f myapp-nuxeo
```
➡️ Open Nuxeo → http://localhost:28080
```bash
# Register with Nuxeo Connect (once per volume — skip if already registered)
./manager.sh register
```
```bash
# Hot reload — trigger from REST client or curl after registration
# POST http://localhost:28080/nuxeo/api/v1/automation/Service.HotReloadStudioSnapshot
```
```bash
# Stop gracefully
./manager.sh stop
```
```bash
# Full reset (requires re-registration)
./manager.sh destroy
./manager.sh purge
./manager.sh build
./manager.sh start
./manager.sh register
```

---
