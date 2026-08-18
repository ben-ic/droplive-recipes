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

## `environment`

Most recipes do not need this section. Add a variable only when DropLive must
generate its value or ask the visitor for it.

DropLive can infer two common cases from Docker Compose:

- A literal or public default is owned by the recipe.
- A variable that Compose permits to be empty is optional.

Do not repeat those variables in `droplive.yaml`.

Use `owner: droplive` when DropLive must generate a fresh value:

```yaml
environment:
  SECRET_KEY:
    owner: droplive
```

Use `owner: user` only when a human must supply a value and no DropLive
companion or emulator can supply it:

```yaml
environment:
  ADMIN_EMAIL:
    owner: user
```

| Owner | Meaning |
|---|---|
| `droplive` | DropLive generates a fresh value for the demo. The value is never committed. |
| `user` | DropLive asks the visitor for the value before launch. Use this sparingly because the demo cannot start unattended. |

### Generated formats

`format` is optional with `owner: droplive`. It defaults to `url-safe`.

| Format | Output | Default length |
|---|---|---|
| `hex` | Lowercase `0-9` and `a-f` | 64 |
| `url-safe` | Letters, digits, `_`, and `-` | 32 |
| `alphanumeric` | Letters and digits | 32 |
| `password` | Letters, digits, and `!@#$%^&*_-` | 24 |
| `base64` | Standard Base64 | 44 |
| `laravel-base64` | `base64:` followed by a Base64-encoded 32-byte key | Fixed |

Set `length` only when the application requires another final character
count:

```yaml
environment:
  SESSION_SECRET:
    owner: droplive
    format: hex
    length: 96
```

`length` must be between 8 and 256. A `hex` length must be even. A `base64`
length must be a multiple of 4. `laravel-base64` has a fixed shape and does not
accept `length`.

Use `pattern` only when the application documents an additional regular
expression requirement:

```yaml
environment:
  APP_PASSWORD:
    owner: droplive
    format: password
    length: 24
    pattern: '^[A-Za-z0-9!_-]+$'
```

The pattern must:

- use RE2 syntax;
- start with `^` and end with `$`;
- contain at most 256 characters; and
- avoid lookarounds and backreferences, which RE2 does not support.

DropLive generates from `format` and `length`, then checks the complete value
against `pattern`. If the selected format cannot satisfy the pattern, the
recipe check fails and names the variable. A pattern is a constraint, not a
second generator. `laravel-base64` does not accept `pattern`.

For the credential shown on the demo sign-in card, add its fixed username:

```yaml
environment:
  APP_ADMIN_PASSWORD:
    owner: droplive
    format: password
    length: 24
    login:
      username: admin
```

Docker Compose still passes the variable to the application:

```yaml
services:
  app:
    environment:
      APP_ADMIN_PASSWORD: "${APP_ADMIN_PASSWORD:?DropLive supplies this value}"
```

Never put the generated value in Docker Compose, a Dockerfile, a script, or
`droplive.yaml`.

Vendor credentials and vendor base URLs do not belong in `environment`. Use a
reviewed emulator capability and map its outputs through `emulators.bindings`.

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

`access: server` is reachable only by the application. Use
`access: server-and-browser` when the application and the visitor's browser must
reach the emulator, such as during OAuth. Use `access: browser` only when the
capability lists a browser-only surface. The capability file is authoritative.

An unsupported capability fails clearly. It never sends traffic to a real
vendor as a fallback.

## MCP servers

See [MCP servers and skills](mcp-and-skills.md) for the classification rule,
sandbox boundary, protocol checks, fixture use, and admission evidence.

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

`command` and `path` are mutually exclusive. A `stdio` server requires
`command`. A `streamable-http` server requires `path`.

A `stdio` server does not need a container port or HTTP health check. The MCP
handshake and operation are its readiness test. A Streamable HTTP server needs
the normal port and health check in addition to its MCP test.

## Skills

See [MCP servers and skills](mcp-and-skills.md) before you classify or test a
skill.

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

## Build secrets

The `environment` section above describes runtime values. Do not use an
entrypoint comment or put a secret value in the recipe.

Private package credentials and other build secrets are not accepted in public
recipe tests. A project that cannot build from public inputs cannot use the open
recipe test path.

## Releases and commits

Do not put a branch, tag, or commit in `droplive.yaml`. One recipe describes how
the project runs. DropLive applies it to the exact release or commit requested
by the user.
