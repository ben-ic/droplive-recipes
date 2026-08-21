# Recipe reference

The file name is always `droplive.yaml`.

Unknown fields fail validation. An app or API needs `version`, `kind`, and a
`run` block with a port; add optional fields only when the application asks for
them.

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

> **Not read.** The schema accepts it and nothing acts on it. No recipe uses it.

```yaml
interfaces: [web, api]
```

## Build discovery

A recipe builds the `Dockerfile` beside its `droplive.yaml`, or the
recipe-owned `docker-compose.yaml` when there is one. That is the whole of it:
every application in this repository is a recipe-owned `Dockerfile` extending a
digest-pinned upstream image.

> **`build` is not read.** The schema accepts the field, the linter validates
> it, and nothing acts on it — no recipe uses it. The subsections below describe
> the intended selection syntax, not behaviour you can rely on today. Put the
> Dockerfile at the recipe root instead.

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

Required for an app or API. `run.port` in particular: a recipe without it is
refused, whatever the Dockerfile says.

```yaml
run:
  port: 3000
  health: /health
  data:
    - /app/data
```

- `port` is the main container port. **Required.**
- `health` is an HTTP path. HTTP 200 means ready by default.
- `data` lists the directories the application writes at runtime. The root
  filesystem is read-only, so an unlisted path is not writable.
- `working-directory` overrides a broken image working directory.

`data` is about writability first and persistence second. A demo lasts fifteen
minutes and keeps nothing afterwards, so list a directory because the
application writes to it, not because the data matters.

Each listed path is mounted **empty**. Nothing is copied from the image, so a
directory the image ships is hidden rather than extended, and a directory the
image merely expects to exist will not. If startup needs files there, restore
them from a template in an entrypoint — see
[entrypoint declarations](#entrypoint-declarations).

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

DropLive managed volumes start empty. Unlike Docker named volumes, they do not
copy existing files from the image. Do not mount one over files that the
application needs to start. If the application must change image files at
runtime, keep a template copy in the image and use a small entrypoint to copy it
into the empty writable mount before startup.

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

`format`, `length`, and `pattern` are the recipe stating the shape its
application requires. Declare them when the application genuinely constrains the
value, and leave them out otherwise so the default applies.

`login` names the username shown beside a generated password on the demo's
sign-in card. The username has to be a literal the visitor can read, so only the
password is generated:

```yaml
environment:
  APP_ADMIN_PASSWORD:
    owner: droplive
    login:
      username: admin
```

An entrypoint annotation does the same job for a credential the application
itself bootstraps — see [entrypoint declarations](#entrypoint-declarations).

An entrypoint that checks the shape of a value it was given should check what it
actually needs. Asserting an exact length is the common mistake: it fails on any
value that is longer and still perfectly usable. Check a minimum length and the
character set.

DropLive injects values declared in `environment` when it starts the service.
Do not repeat them in Docker Compose. A plain `docker compose up` does not
generate these values; the DropLive recipe test supplies them.

Never put the generated value in Docker Compose, a Dockerfile, a script, or
`droplive.yaml`.

Vendor credentials and vendor base URLs do not belong in `environment`. Use a
reviewed emulator capability and map its outputs through `emulators.bindings`.

## The public origin

Do not declare the demo's own URL. DropLive recognises an origin-shaped variable
name and supplies the session origin automatically. These names are recognised:

- exactly `APP_URL`, `AUTH_URL`, `NEXTAUTH_URL`, or `ROOT_URL`; and
- any name ending in `_ROOT_URL`, `_SITE_URL`, `_BASE_URL`, or `_PUBLIC_URL`.

So `WAKAPI_PUBLIC_URL`, `APP_BASE_URL`, and `NTFY_BASE_URL` all resolve without
a declaration. Require the name where the application reads it and stop there:

```sh
: "${APP_BASE_URL:?DropLive supplies the public origin}"
```

A name that no file requires is never supplied. Requiring it is what asks for
it.

> **Do not declare an origin variable as `owner: droplive`.** That marks it as a
> value to generate, which wins over the origin rule, and the application
> receives a random secret where its URL should be. The application then starts
> and fails in confusing ways instead of failing at boot.

A name carrying a database or cache word is never treated as an origin, so a
connection URL still comes from its companion.

## Entrypoint declarations

A recipe-owned entrypoint script is a declaration surface, not only code.
DropLive reads the script that the image's `ENTRYPOINT` or `CMD` names, when
that script is `COPY`ed from the recipe folder.

### Requiring a value

The POSIX "fail if unset" form declares a required runtime value:

```sh
: "${SESSION_SECRET:?DropLive must generate SESSION_SECRET}"
```

DropLive collects every `${NAME:?message}` in that script and treats each name
as required. This is why most recipes need no `environment` section: the
entrypoint already says what the application cannot start without.

### Declaring a generated bootstrap credential

A credential the application owns and DropLive mints per demo needs a
machine-readable line in the same script, directly above its guard:

```sh
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=none name=ADMIN_PASSWORD capability=owner-login username=admin
: "${ADMIN_PASSWORD:?DropLive must generate the initial owner password}"
```

The fields are fixed and ordered:

| Field | Accepted values |
|---|---|
| `generate` | `hex64` or `hex96` |
| `ownership` | `app` |
| `purpose` | `owner-bootstrap` or `admin-bootstrap` |
| `lifecycle` | `stable` |
| `rotation` | `app` if the application can change it after sign-in, else `none` |
| `name` | The variable name |
| `capability` | Optional. `owner-login` or `admin-login` |
| `username` | Optional. The fixed username shown beside the password |

`hex64` and `hex96` are the number of characters, so `hex96` is 96 bytes. Many
applications hash a password with bcrypt, which refuses anything over 72 bytes.
Fusion exits at boot with `bcrypt: password length exceeds 72 bytes` when it is
given `hex96`, and starts with `hex64`. Check how the application hashes the
value before choosing.

Leave `username` out when the application signs in with a password alone. The
card then shows only the password, which is all Fusion has.

Rules that decide whether the line counts:

- The same script must also require `name` with a `${NAME:?…}` guard. An
  annotation alone declares nothing.
- `name` must read as a credential: it needs `PASSWORD`, `PASS`, `SECRET`, or
  `TOKEN` as a whole word. A connection password and a recognised third-party
  credential are refused even when annotated.
- `capability` must agree with `purpose`: `owner-bootstrap` pairs with
  `owner-login`.
- **At most one `capability=` line per script.** A second one silently removes
  the sign-in card. Annotate other generated secrets without `capability`.

`capability` is what puts the credential on the visitor's sign-in card, so add
it only for the credential a person actually signs in with. Omit it for machine
keys:

```sh
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=none name=SESSION_SECRET
: "${SESSION_SECRET:?DropLive must generate SESSION_SECRET}"
```

### Where DropLive looks

Only the first statically resolvable absolute path in the image's `ENTRYPOINT`
or `CMD` is read, and only when a `COPY` in the recipe Dockerfile maps it back
into the recipe folder. Arbitrary scripts are not scanned, so a build helper
cannot become a runtime requirement.

DropLive reads that script relative to the recipe folder root. If a recipe
Compose file points its build at another directory or another Dockerfile name,
the entrypoint is not found there and its declarations are missed. Keep the
Dockerfile and the entrypoint at the recipe root.

## `sign_in`

Some images arrive with a sign-in already set. File Browser writes `admin` /
`admin` into a fresh database and prints nothing, so a demo of it starts
perfectly and the visitor cannot get past the login page. DropLive can neither
mint that credential nor discover it — the recipe is the only thing that knows.

> **Check for an environment variable first.** Most applications take their
> admin password from one, and then minting is the right answer: declare it
> `owner: droplive` with `login.username` and the visitor gets a credential
> belonging to their session alone. `sign_in` is for a credential DropLive
> cannot change, not one nobody has changed yet. Stating a published default
> because it is simpler puts a credential from the project's own documentation
> on a live demo.

```yaml
sign_in:
  username: admin
  password: admin
  note: Upstream default for a fresh database. Change it from Settings.
```

DropLive shows this on the demo's sign-in card, the same place it shows a
credential it generated.

| Key | Meaning |
|---|---|
| `username` | Required. The username the image already accepts |
| `password` | Required. The password the image already accepts |
| `note` | Optional. One line of context shown with it |

Use this **only** for a credential the published image genuinely ships with.
A published default is public already, and writing it here tells the visitor
what the image would have told them if it printed anything.

Never record a value DropLive generates. A generated credential belongs to one
demo, and committing it would publish it. If the application lets an entrypoint
set the owner password, prefer that: a value minted per demo beats a default
everyone knows, and `sign_in` exists for the images that give you no such hook.
See [entrypoint declarations](#entrypoint-declarations).

## `companions`

Optional. A companion is a reviewed service that runs with the project.

```yaml
companions:
  database: postgres
  cache: redis
```

The short form supports `postgres`, `mysql`, `mariadb`, `mongodb`, `redis`, and
`upstash`. Use the expanded form when the recipe needs a reviewed dataset and
environment bindings:

```yaml
companions:
  database:
    type: postgres
    dataset: postgres.store.v1
    bindings:
      DATABASE_URI: url
```

Allowed companion datasets and outputs are registered in
[`companions/v1.yaml`](../companions/v1.yaml). A type, dataset, or binding that
is not in this registry fails validation.

Use the short form whenever the application can read a single connection URL,
which is most of them. Reach for the expanded form when it cannot: Joomla wants
its connection in parts and halts with "Missing JOOMLA_DB_HOST and
MYSQL_PORT_3306_TCP environment variables" if it does not get them.

A declared binding is emitted alongside the usual `DATABASE_URL` or
`REDIS_URL`, so an application reading either shape finds what it needs. A name something
else already binds is left alone.

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
  package:
    manager: npm
    name: "@example/server"
    version: "1.2.3"
    integrity: "sha512-..."
  command: ["example-server"]
  network: observed
  expected_hosts:
    - api.example.com
  tools:
    examples:
      read_item: {id: "example-1"}
    smoke:
      name: read_item
      arguments: {id: "example-1"}
```

For Streamable HTTP:

```yaml
version: 1
kind: mcp
mcp:
  transport: streamable-http
  path: /mcp
  network: none
  tools:
    smoke:
      name: read_status
      arguments: {}
```

Build discovery works the same way as it does for apps.

`package` is one optional build path. It identifies one exact package release.
An MCP recipe can instead use upstream source, a recipe Dockerfile, Compose, or
a pinned image. A source recipe builds the exact Git commit that the user
requests. A recipe cannot contain both `mcp.package` and `build`. When `package`
is present, `command` names its resolved executable without a shell or
downloader. For a source build, the selected image provides the declared
standard-input and standard-output command.

A Streamable HTTP recipe declares only its local `path`. It must start the
server in the DropLive sandbox and use an internally derived endpoint. A public
recipe cannot supply a remote endpoint.

When one repository contains several MCP products, add a product folder and a
matching slug:

```text
recipes/mcp/modelcontextprotocol/servers/filesystem/droplive.yaml
```

```yaml
product: filesystem
```

Every MCP recipe declares `network: observed` or `network: none`. Observed mode
allows traffic and records actual destinations. None mode blocks traffic and
tests that the server does not need it. `expected_hosts` is optional review
documentation for observed mode. It accepts hostnames and wildcard hostnames.
It does not control traffic.

Tool `examples` are optional and should include only useful starting arguments.
DropLive uses each live tool's `tools/list` JSON Schema to help the user create
other arguments. `smoke` is required. It is one read-only, bounded call that
qualification runs with public or disposable fixture data.

Command arguments can contain a complete `{{NAME}}` runtime-value token when
`NAME` is declared by `environment`, an emulator binding, or a companion
binding. DropLive replaces the token without a shell before it starts the
command.

The package integrity value pins the top-level archive. During qualification,
DropLive resolves and hashes the complete dependency closure and attaches that
closure to the tested artifact identity. A later dependency resolution produces
a different artifact identity even when the top-level package version is the same.

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

> **Not in use.** No recipe seeds data yet, and `seed` is not read. Treat this
> section and [seeding.md](seeding.md) as the intended design.

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
