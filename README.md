# DropLive recipes

This repository contains the reviewed recipes that DropLive uses to start
temporary demos of open-source software.

[Try a live demo](https://droplive.io/projects) or see [every project that is
live now](LIVE_NOW.md).

## What is in this repository

- `recipes/` contains the build and run instructions for each project.
- `schema/`, `capabilities/`, and `companions/` define the recipe contract.
- `tools/` validates recipes and updates the public live list.
- [`LIVE_NOW.md`](LIVE_NOW.md) lists the current public demos. A daily workflow
  reads the public DropLive catalogue and updates this file when the list
  changes.

A recipe is runtime intent. It does not control public listing state. A passing
build creates an unlisted candidate. DropLive lists an exact version only after
a reviewer completes the [public browser gate](docs/catalogue-verification.md).

## Add an application

Create this directory:

```text
recipes/app/<forge-owner>/<repository>/
├── droplive.yaml
└── Dockerfile
```

Start with the smallest complete recipe:

```yaml
version: 1
kind: app
description: Short line that tells a visitor what the application does
repository: https://codeberg.org/example/project
run:
  port: 3000
  health: /health
```

Use a digest-pinned image:

```dockerfile
FROM ghcr.io/example/project@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

EXPOSE 3000
```

Use a recipe-root `docker-compose.yaml` when the application needs more than one
application service. Put public defaults in the image or Compose file. Declare a
runtime value only when DropLive must generate it or ask the visitor for it. The
launch page must show every value and instruction that a visitor needs.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before you add or change a recipe.

## Validate a change

```sh
python3 -m pip install -r requirements-dev.txt
python3 tools/lint_recipes.py
python3 tools/test_environment_schema.py
python3 tools/test_kind_schema.py
python3 tools/test_entrypoint_rules.py
python3 tools/test_byok_schema.py
```

Unknown recipe keys fail JSON Schema validation. This also applies to MCP
recipes.

## Refresh the live list

```sh
python3 tools/update_live_now.py
```

The command reads `https://droplive.io/projects`. Do not edit `LIVE_NOW.md` by
hand. GitHub Actions runs this command each day and commits a change only when
the public catalogue changes.

## References

- [Recipe reference](docs/recipe-format.md)
- [Seeding a demo with the shared world](docs/seeding.md)
- [Catalogue verification](docs/catalogue-verification.md)
- [MCP and skill boundaries](docs/mcp-and-skills.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Coding-agent prompt](docs/agent-prompt.md)
- [Contribution guide](CONTRIBUTING.md)

This repository uses the [MIT License](LICENSE).
