# Recipe reference

The file name is always `droplive.yaml`.

Unknown fields fail validation. Start with two fields and add optional fields
only when you need them.

## `version`

Required. The current value is `1`.

```yaml
version: 1
```

## `kind`

Required. It must match the first folder below `recipes/`.

| Kind | Use it for |
|---|---|
| `app` | A user-facing application |
| `api` | An API without a primary user interface |
| `mcp` | An MCP server |
| `skill` | A skill package |

## `interfaces`

Optional. Use it when an app has more than one public interface.

```yaml
interfaces: [web, api]
```

## Build discovery

When `build` is absent, DropLive uses this order:

1. Recipe-owned `docker-compose.yaml`
2. Recipe-owned `Dockerfile`
3. One unambiguous upstream Docker Compose file
4. One unambiguous upstream Dockerfile

If more than one upstream choice remains, select it with `build`.

### Select upstream Docker Compose

```yaml
build:
  docker-compose: deploy/docker-compose.yml
  service: web
```

`service` is optional when Compose has one service or a service named `app`.

### Select an upstream Dockerfile

```yaml
build:
  dockerfile: docker/Dockerfile
  context: .
```

The default context is the upstream repository root.

### Use an existing image

```yaml
build:
  image: ghcr.io/example/project@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

The image must be pinned by digest.

## `run`

Optional. Use it only when the selected Docker Compose file or Dockerfile does
not provide enough information.

```yaml
run:
  port: 3000
  health: /health
  data:
    - /app/data
```

- `port` is the main container port.
- `health` is an HTTP path. HTTP 200 means ready by default.
- `data` contains persistent writable paths.
- `working-directory` overrides a broken image working directory.

A health check can also require response text:

```yaml
run:
  health:
    path: /api/status
    status: [200]
    contains:
      - '"ready":true'
```

Do not add a `data` path for temporary files. Put temporary paths in the
`tmpfs` section of `docker-compose.yaml`.

## `companions`

Optional. A companion is a reviewed service that runs with the project.

```yaml
companions:
  database: postgres
  cache: redis
```

Supported values are `postgres`, `mysql`, `mariadb`, `mongodb`, `redis`, and
`upstash`.

## `emulators`

Optional. Use an emulator when the project must call a supported external
service during a demo. The recipe maps DropLive-provided outputs to the
application's environment names. It cannot provide a host or credential.

```yaml
emulators:
  mail:
    capability: mail.smtp.v1
    bindings:
      SMTP_HOST: host
      SMTP_PORT: port
      EMAIL_FROM: from_address
```

Available capabilities and outputs are listed in
[`capabilities/v1.yaml`](../capabilities/v1.yaml).

A capability may offer a reviewed `dataset`, and a recipe may layer its own content
over one with `seed`. See [seeding](seeding.md); identities and credentials always
come from the dataset.

`access: browser` means a visitor's browser reaches the emulator at its own session
hostname, which is what an OAuth redirect needs. `access: server` is reachable only
by the application.

An unsupported capability fails clearly. It never sends traffic to a real
vendor as a fallback.

## MCP servers

For a standard-input and standard-output MCP server:

```yaml
version: 1
kind: mcp
mcp:
  transport: stdio
  command: ["node", "dist/index.js"]
```

For Streamable HTTP:

```yaml
version: 1
kind: mcp
mcp:
  transport: streamable-http
  path: /mcp
```

Build discovery works the same way as it does for apps.

## Skills

```yaml
version: 1
kind: skill
skill:
  entrypoint: SKILL.md
```

`entrypoint` is relative to the upstream repository root.

## Application seed files

Use `seed.sh` for realistic application data. See
[seeding.md](seeding.md) before you add it.

An archive is also available for applications with a stable file format:

```yaml
seed:
  archive: seed.tar.zst
  target: /app/data
```

Do not use an archive to construct a private database schema by hand. Do not use
application seeds for external mailboxes, OAuth identities, tokens, or vendor
data. Use a supported emulator capability.

## Environment variables and secrets

Declare normal environment variables in `docker-compose.yaml` or the
Dockerfile. Never put a secret value in the recipe.

Use normal Compose syntax for a required value:

```yaml
environment:
  ADMIN_EMAIL: "${ADMIN_EMAIL:?an administrator email is required}"
```

For a credential that DropLive must generate, put this exact annotation in the
entrypoint script that reads the variable:

```sh
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=APP_ADMIN_PASSWORD capability=owner-login username=admin
: "${APP_ADMIN_PASSWORD:?DropLive must generate the owner password}"
```

Only `hex64` and `hex96` are valid generators. Keep the fields in this order.
The annotated script must be the script used by `ENTRYPOINT` or `CMD`.

Build keys and private package credentials must never be committed. Declare the
secret name through Docker or Compose secret syntax. A contribution that needs
a private build value requires separate review.

## Releases and commits

Do not put a branch, tag, or commit in `droplive.yaml`. One recipe describes how
the project runs. DropLive applies it to the exact release or commit requested
by the user.
