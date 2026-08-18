# DropLive recipes

This repository tells DropLive how to run open-source software.

Start with one small file. If the upstream project needs help, you can
also add `docker-compose.yaml`, a `Dockerfile`, and helper scripts. You do not
need to change the upstream repository.

## Add a project in five minutes

Create this file:

```text
recipes/app/<github-owner>/<github-repository>/droplive.yaml
```

Start with:

```yaml
version: 1
kind: app
```

That is enough when DropLive can find one usable upstream Docker Compose file or
Dockerfile and can discover how to start and check the project.

Run the validator:

```bash
python3 -m pip install -r requirements-dev.txt
python3 tools/lint_recipes.py
```

If the validator or build asks for more information, add only that information.

## Choose the kind

Every recipe states what it provides:

| Kind | What it provides |
|---|---|
| `app` | A user-facing application |
| `api` | An API without a primary user interface |
| `mcp` | An MCP server |
| `skill` | A skill with a `SKILL.md` entrypoint |

An app can also declare more than one interface:

```yaml
version: 1
kind: app
interfaces: [web, api]
```

## When upstream already works

Do not copy the upstream Docker Compose file or Dockerfile. Keep the two-line
recipe. DropLive applies it to the requested upstream commit.

If the repository has several build files, select one:

```yaml
version: 1
kind: app
build:
  docker-compose: deploy/docker-compose.yml
  service: web
```

Paths in `build` select files from the upstream repository.

## When upstream needs help

Add `docker-compose.yaml` beside `droplive.yaml`. This file belongs to the
recipe. DropLive uses it with the upstream source checkout.

```text
recipes/app/example/example/
├── droplive.yaml
├── docker-compose.yaml
├── Dockerfile             # optional
└── entrypoint.sh           # optional
```

Use one service named `app` when possible:

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    read_only: true
    tmpfs:
      - /tmp
      - /app/cache
    volumes:
      - data:/app/data
    expose:
      - "3000"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:3000/health"]

volumes:
  data:
```

Compose is the preferred repair tool. It can declare the command, environment,
port, health check, read-only root, temporary paths, and persistent data.

Use a recipe `Dockerfile` when you must change the image, entrypoint, installed
files, user, or startup behavior. Pin every `FROM` image by digest.

## What belongs in droplive.yaml

Only add facts that DropLive cannot discover from the build files:

```yaml
version: 1
kind: app
run:
  port: 3000
  health: /health
  data:
    - /app/data
```

The recipe does not contain a GitHub URL, branch, tag, commit, license result,
artifact digest, measurement, or secret. The folder identifies the GitHub
repository. DropLive records the requested commit separately.

## Environment ownership

Most environment variables stay in Docker Compose. Add an `environment` entry
to `droplive.yaml` only when DropLive must generate a value or ask the visitor
for it:

```yaml
environment:
  APP_SECRET:
    owner: droplive
  ADMIN_EMAIL:
    owner: user
```

Generated values can select a documented `format`, `length`, and safe
`pattern`. See the [recipe reference](docs/recipe-format.md#environment).
Never commit the value itself.

## Versions

One recipe supports many releases and commits. Do not copy the recipe for each
version. Change the recipe only when the way the project runs changes.

## Use a coding agent

Copy the prompt in [docs/agent-prompt.md](docs/agent-prompt.md). It works with a
GitHub URL or a repository on your computer.

## More help

- [Complete recipe reference](docs/recipe-format.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Add realistic sample data](docs/seeding.md)
- [Handle and test MCP servers and skills](docs/mcp-and-skills.md)
- [Contribution checklist](CONTRIBUTING.md)

This repository uses the [MIT License](LICENSE).
