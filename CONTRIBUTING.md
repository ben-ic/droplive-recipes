# Contributing a recipe

## Before you start

You need:

- A public GitHub repository or a local checkout of one
- Python 3

For an app, API, or MCP server, you also need Docker with Docker Compose.

You do not need to be the upstream maintainer. Maintainers and community members
use the same recipe format.

## Make the smallest recipe

1. Create `recipes/<kind>/<owner>/<repository>/droplive.yaml`.
2. Add `version: 1` and the correct `kind`.
3. Use the upstream Docker Compose file or Dockerfile when it works.
4. Add recipe files only when upstream needs a DropLive-specific change.
5. Add only the missing values reported by validation.

Do not copy upstream files only to make the recipe look complete.

## Test an app, API, or MCP server

The runtime must:

- build for `linux/amd64`;
- start without privileged mode or host networking;
- run with a read-only root filesystem;
- write temporary files only to declared `tmpfs` paths;
- write persistent files only to declared volumes;
- expose one main port for an app, API, or Streamable HTTP MCP server;
- have a health check that proves it is ready;
- contain no committed secret.

An MCP test must also complete the protocol checks in
[MCP servers and skills](docs/mcp-and-skills.md).

## Test a skill

A skill does not need a container port or health check. Validate the complete
skill package, then run fixed scenarios in an agent sandbox with an explicit
tool allowlist. Check fixture changes instead of trusting the final answer.

Then run:

```bash
python3 tools/lint_recipes.py
python3 tools/test_kind_schema.py
```

## Pull request checklist

- [ ] `kind` is correct.
- [ ] An MCP or skill follows its separate sandbox and evidence rules.
- [ ] The recipe is as small as possible.
- [ ] Every recipe-owned `FROM` image is pinned by digest.
- [ ] For a runtime recipe, `docker-compose.yaml` sets `read_only: true` on the main service.
- [ ] For a runtime recipe, the main service has its required port and health check.
- [ ] For a runtime recipe, writable paths use `tmpfs` or a volume.
- [ ] Docker Compose supplies public defaults and marks optional values.
- [ ] `droplive.yaml` declares only `owner: droplive` or `owner: user` values.
- [ ] Generated values use a supported format, length, and safe pattern.
- [ ] No password, token, private key, or API key is committed.
- [ ] `seed.sh`, when present, is repeatable and contains only obvious sample data.
- [ ] The validator passes.

See [docs/troubleshooting.md](docs/troubleshooting.md) when the application builds
but does not start.
