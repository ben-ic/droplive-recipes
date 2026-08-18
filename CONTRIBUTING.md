# Contributing a recipe

## Before you start

You need:

- A public GitHub repository or a local checkout of one
- Docker with Docker Compose
- Python 3

You do not need to be the upstream maintainer. Maintainers and community members
use the same recipe format.

## Make the smallest recipe

1. Create `recipes/<kind>/<owner>/<repository>/droplive.yaml`.
2. Add `version: 1` and the correct `kind`.
3. Use the upstream Docker Compose file or Dockerfile when it works.
4. Add recipe files only when upstream needs a DropLive-specific change.
5. Add only the missing values reported by validation.

Do not copy upstream files only to make the recipe look complete.

## Test it

The application must:

- build for `linux/amd64`;
- start without privileged mode or host networking;
- run with a read-only root filesystem;
- write temporary files only to declared `tmpfs` paths;
- write persistent files only to declared volumes;
- expose one main port for an app or API;
- have a health check that proves it is ready;
- contain no committed secret.

Then run:

```bash
python3 tools/lint_recipes.py
```

## Pull request checklist

- [ ] `kind` is correct.
- [ ] The recipe is as small as possible.
- [ ] Every recipe-owned `FROM` image is pinned by digest.
- [ ] `docker-compose.yaml` sets `read_only: true` on the main service.
- [ ] The main service has a port and health check.
- [ ] Writable paths use `tmpfs` or a volume.
- [ ] No password, token, private key, or API key is committed.
- [ ] `seed.sh`, when present, is repeatable and contains only obvious sample data.
- [ ] The validator passes.

See [docs/troubleshooting.md](docs/troubleshooting.md) when the application builds
but does not start.
