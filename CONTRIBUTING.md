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
- contain no committed secret.

DropLive managed volumes start empty. They do not copy existing files from the
image. Test with empty volumes and confirm that no mount hides files needed at
startup.

An app, API, or Streamable HTTP MCP server must expose one main port and have an
HTTP health check that proves it is ready. A `stdio` MCP server needs neither.
Its MCP handshake and a successful operation prove readiness.

An MCP test must also complete the protocol checks in
[MCP servers and skills](docs/mcp-and-skills.md).

For a package build, the qualification result must include the resolved and
hashed dependency closure. The top-level package hash alone is not the tested
artifact identity.

An MCP package recipe identifies one exact package release. It cannot also
select a source build. A source recipe builds the exact requested Git commit.
Every MCP recipe must select `network: observed` or `network: none` and must
include one safe, bounded, read-only smoke call.

## Test a skill

A skill does not need a container port or health check. Validate the complete
skill package, then run fixed scenarios in an agent sandbox with an explicit
tool allowlist. Check fixture changes instead of trusting the final answer.

Then run:

```bash
python3 tools/lint_recipes.py
python3 tools/test_environment_schema.py
python3 tools/test_kind_schema.py
python3 tools/test_entrypoint_rules.py
```

`lint_recipes.py` reads your entrypoint as well as `droplive.yaml`. It rejects a
`# droplive:` line that does not parse or that sits somewhere nothing reads it,
an annotation with no matching `${NAME:?…}` guard, a second `capability=` in one
script, an exact-length check on a generated value, and an origin variable
declared as `owner: droplive`.

## Pull request checklist

- [ ] `kind` is correct.
- [ ] An MCP or skill follows its separate sandbox and evidence rules.
- [ ] The recipe is as small as possible.
- [ ] Every recipe-owned `FROM` image is pinned by digest.
- [ ] For a runtime recipe, `docker-compose.yaml` sets `read_only: true` on the main service.
- [ ] An app, API, or Streamable HTTP MCP service has its required port and HTTP health check.
- [ ] A `stdio` MCP service proves readiness with its MCP handshake and an operation.
- [ ] An MCP package build records the complete resolved dependency closure.
- [ ] An MCP recipe declares its network mode and one safe smoke call.
- [ ] An MCP package recipe does not also declare a source build.
- [ ] For a runtime recipe, writable paths use `tmpfs` or a volume.
- [ ] The runtime does not depend on Docker named-volume copy-up.
- [ ] Docker Compose supplies public defaults and marks optional values.
- [ ] `droplive.yaml` declares only `owner: droplive` or `owner: user` values.
- [ ] Generated values use a supported format, length, and safe pattern.
- [ ] The entrypoint requires each runtime value with `: "${NAME:?message}"`.
- [ ] A generated bootstrap credential carries its `# droplive:` annotation directly above that guard.
- [ ] At most one annotation per script carries `capability=`.
- [ ] No origin variable is declared as `owner: droplive`.
- [ ] No password, token, private key, or API key is committed. A published upstream default in `sign_in` is the one exception; it is public already, and a generated value never belongs there.
- [ ] `seed.sh`, when present, is repeatable and contains only obvious sample data.
- [ ] The validator passes.

See [docs/troubleshooting.md](docs/troubleshooting.md) when the application builds
but does not start.
