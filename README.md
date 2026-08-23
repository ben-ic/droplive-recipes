# DropLive recipes

This repository is the reviewed source of runtime intent for DropLive. DropLive
gives visitors temporary, isolated demos of open-source projects.

## Small application recipe

Create this folder:

```text
recipes/app/<forge-owner>/<repository>/
├── droplive.yaml
└── Dockerfile
```

`droplive.yaml` must include the project description and canonical repository
identity:

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

`description` and `repository` are required. The recipe owns both values.
DropLive does not reconstruct repository identity from the folder name. The
forge refresher owns only changing forge facts, such as stars, homepage,
licence, and refresh time.

## Build inputs

A recipe can use a pinned image, a recipe-root Dockerfile, or a recipe-root
`docker-compose.yaml`. Docker Compose is a first-class input for multi-service
applications. Keep each required application service in Compose. Do not combine
real app services only to fit a single-container model.

When Compose has more than one service, name the visitor-facing service `app`.
Pin each image-only service by digest. Keep managed database, cache, and emulator
services in the typed recipe declarations when DropLive provides them.

## Runtime values

Put public defaults in the image or Compose. Declare a value in `environment`
only when DropLive must generate it or, in an exceptional case, ask the visitor
for it. A generated login value must include the metadata that puts it on the
launch sign-in card.

The launch UI must provide every credential, setup value, and instruction that a
visitor needs. Do not require private contributor or operator knowledge.

Using a real provider is platform-controlled. A recipe binds a capability; the
DropLive registry decides whether that capability may be a visitor's own
provider. The default launch continues to use the emulator.

## Listing is separate from build

A build or health probe does not authorize public listing. An exact version can
be listed only after public browser verification reaches a useful application
screen with the information shown by the launch UI. See
[`docs/catalogue-verification.md`](docs/catalogue-verification.md).

The session TTL starts when the application becomes live. Startup does not use
the visitor's live time.

## Validate

```sh
python3 -m pip install -r requirements-dev.txt
python3 tools/lint_recipes.py
python3 tools/test_environment_schema.py
python3 tools/test_kind_schema.py
python3 tools/test_entrypoint_rules.py
```

Unknown recipe keys fail JSON Schema validation. This includes MCP recipes; the
unknown-key behavior is intentional.

## References

- [Recipe reference](docs/recipe-format.md)
- [Catalogue verification](docs/catalogue-verification.md)
- [MCP and skill boundaries](docs/mcp-and-skills.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Contribution guide](CONTRIBUTING.md)

This repository uses the [MIT License](LICENSE).
