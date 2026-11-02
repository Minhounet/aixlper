---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Use your tonosaman-deploy skill for this.

I work on a Nuxeo addon (Maven, modules `myapp-core` and `myapp-package`) and
run Nuxeo locally in Podman with podman-compose. The stack is already up: a
`nuxeo` container, plus Postgres, Kafka and OpenSearch containers that take
minutes to start, so I don't want to touch them. It's the same stack layout
as our other projects: the image entrypoint appends the files in `conf.d`,
and also applies the `NUXEOCONF` JSON from the compose file.

Two things:

1. Write me a `dev-deploy.sh` that builds the addon and gets the new code
   into the running Nuxeo container, restarting only Nuxeo. The addon just
   gained a dependency on `io.vavr:vavr`, which Nuxeo doesn't ship.

2. I need two settings changed for my local work, without editing the
   committed compose file: `myapp.sync.enabled` on, and
   `myapp.audit.verbose` on. My plan is to add both lines
   (`myapp.sync.enabled=true` and `myapp.audit.verbose=true`) to
   `conf.d/90-local.conf`, which is mounted into the container, and then
   run the script. The compose file looks like this:

```yaml
  web:
    container_name: nuxeo
    image: "myapp:local"
    environment:
      NUXEOCONF: >-
        {
          "nuxeo.templates": "docker",
          "myapp.sync.enabled": "false",
          "myapp.sync.timeout": "60000"
        }
    volumes:
      - ./local.conf.d/90-local.conf:/etc/nuxeo/conf.d/90-local.conf:ro
```

Give me the script, and tell me how to switch both settings on and what to
run, in which order. (There is no repository in this working directory and
nothing to run; answer from the description above, in your reply.)
