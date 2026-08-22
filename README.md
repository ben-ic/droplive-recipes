# DropLive recipes

This repository tells DropLive how to run open-source software.

Start with two small files. Add a script only when the application needs one.
You do not need to change the upstream repository.

## Add a project in five minutes

A recipe is a folder with two files:

```text
recipes/app/<github-owner>/<github-repository>/
├── droplive.yaml
└── Dockerfile
```

`droplive.yaml` says how to reach the application and what it writes:

```yaml
version: 1
kind: app
description: Short line saying what the application does
repository: https://github.com/example/project
run:
  port: 3000
  health: /health
```

`Dockerfile` names the published image, pinned by digest:

```dockerfile
FROM ghcr.io/example/project@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

EXPOSE 3000
```

That is the whole recipe, and it is what most of the ones here look like. The
large majority of the applications in this repository need nothing more.

A few things matter:

- `description` is required. One line, 10 to 160 characters, saying what the
  application does. It is what a visitor reads in the catalog.
- `repository` is required. The full URL of the upstream repository, on whatever
  forge it lives. GitHub is the common case, not an assumption.
- `run.port` is required.
- `health` must return 200 only when the application is ready.
- `data` lists every directory the application writes at runtime. The root
  filesystem is read-only, so a path you do not list is not writable.

Run the validator:

```bash
python3 -m pip install -r requirements-dev.txt
python3 tools/lint_recipes.py
```

Add anything else only when the application asks for it.

## Choose the kind

Every recipe states what it provides:

| Kind | What it provides |
|---|---|
| `app` | A user-facing application |
| `api` | An API without a primary user interface |
| `mcp` | An MCP server |
| `skill` | A skill with a `SKILL.md` entrypoint |

## When the image needs help

Extend the pinned image in the recipe `Dockerfile`. Most repairs are one or two
lines — a missing command, an environment default the demo needs:

```dockerfile
FROM docker.io/example/project@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

# Started bare this image prints its usage banner and exits.
CMD ["server", "/data", "--console-address", ":9001"]
```

When startup itself has to do something first, add an entrypoint script beside
`droplive.yaml`, copy it in, and hand over to the image's own command. A fair
number of recipes here do this. Keep it short and say why in a comment — the
next person reading it cannot see the failure that caused it.

Do not copy a whole upstream Dockerfile in order to change one line, and pin
every `FROM` by digest.

A recipe-owned `docker-compose.yaml` is also supported, and almost nothing here
needs one. Reach for it only when a single container genuinely cannot express
the runtime.

## What belongs in droplive.yaml

Only add facts DropLive cannot get from the image:

```yaml
version: 1
kind: app
run:
  port: 3000
  health: /health
  data:
    - /app/data
```

Beyond `repository`, the recipe does not contain a branch, tag, commit, license
result, star count, artifact digest, measurement, or secret. Those are facts
about the repository, and DropLive reads them from the forge -- a star count
committed to git is wrong the next day. DropLive records the requested commit
separately.

## Environment ownership

Public defaults belong in the `Dockerfile` as `ENV`. Add an `environment` entry
to `droplive.yaml` only when DropLive must generate a value or ask the visitor
for it:

```yaml
environment:
  APP_SECRET:
    owner: droplive
  APP_ADMIN_PASSWORD:
    owner: droplive
    login:
      username: admin
```

`login` puts the credential on the demo's sign-in card. Generated values can
also select a `format`, `length`, and safe `pattern`. See the
[recipe reference](docs/recipe-format.md#environment). Never commit the value
itself.

Few recipes need this section. Most need none of it — the entrypoint states
what it requires with `: "${NAME:?…}"` and DropLive reads that directly.

## Versions

One source recipe supports many releases and commits. Do not copy the recipe for
each version. Change the recipe only when the way the project runs changes. An
MCP package recipe is different: it identifies the one exact package release in
`mcp.package` and does not build server code from the requested Git commit.

## Use a coding agent

Copy the prompt in [docs/agent-prompt.md](docs/agent-prompt.md). It works with a
GitHub URL or a repository on your computer.

## MCP test recipes

An MCP recipe can use a pinned registry package, source, Dockerfile, Compose, or
a pinned image. It declares the local transport, one safe smoke call, and a
network mode. `observed` allows traffic and records its actual destinations.
`none` blocks traffic to test that the server does not need it. A
standard-input and standard-output server
uses the MCP handshake for readiness. DropLive applies its 15-minute session
policy without repeating that value in each recipe.

The runtime behavior is the planned DropLive test contract. See the
[complete recipe reference](docs/recipe-format.md) for its exact limits.

## More help

- [Complete recipe reference](docs/recipe-format.md)
- [Planned MCP and skills test contract](docs/mcp-and-skills.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Planned sample-data design](docs/seeding.md)
- [Contribution checklist](CONTRIBUTING.md)

This repository uses the [MIT License](LICENSE).
