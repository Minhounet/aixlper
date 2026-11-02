# Nuxeo + Podman setup files (genericized)

Read this folder when a Nuxeo project runs locally with Podman and you need
the concrete files: the compose stack, the start and build scripts, the
per-developer config, or the dev-deploy loop. Open only the file you need.

Genericized copies of one real, working local stack. Names are replaced
(`myapp`, `com.example`), dev passwords are `change-me`, and the proxy
address is a documentation address. The files have not been run from this
repo, and some are not complete:

- `build-local.sh` and `manager.sh` expect files that are not here: the
  `myapp_nuxeo_docker` Dockerfile and its config directory, `settings.xml`,
  and `addons_artifacts.yml`.
- `dev-deploy.sh` expects the `log4j2-myapp.xml` config from that config
  directory.
- The compose file reads `.env` for `VOLUMES_DIR` and the `EXTSYNC_*`
  variables.

Use them as a reference for a project's own setup, not as files to copy
unchanged.

| File | Read it when |
|---|---|
| `docker-compose.yaml` | You need the service layout, the network anchor, the wait loop, or the `NUXEOCONF` keys |
| `manager.sh` | You need the start, stop, restart, destroy or seed commands and their order |
| `build-local.sh` | You need how the image is built, including local addon builds |
| `dev-deploy.sh` | You need the copy-into-running-container loop for one addon (see `../nuxeo.md`) |
| `90-local.conf.example` | You need the per-developer override file and its precedence limit |
| `setup-guide.md` | You need the human setup steps: tokens, the first build, ports, troubleshooting |
