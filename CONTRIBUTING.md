# Contributing a recipe

## Before you start

You need a public upstream repository or a local checkout, Python 3, and Docker
with Docker Compose for an app, API, or MCP service.

## Create the smallest complete recipe

1. Create `recipes/<kind>/<forge-owner>/<repository>/`.
2. Add `droplive.yaml` with `version`, `kind`, required `description`, and
   required canonical HTTPS `repository`.
3. Add the required `run` port and readiness check for a web service.
4. Add a digest-pinned recipe-root `Dockerfile`, or add a recipe-root
   `docker-compose.yaml` for a real multi-service application.
5. Run the complete topology without privileged mode, host networking, host
   mounts, or committed secrets.

The recipe owns repository identity, visitor description, and runtime intent.
Do not add stars, homepage, licence, or other changing forge facts.

## Docker Compose

Docker Compose is a first-class input. Use it when the application has more than
one required application-owned service. Keep service boundaries, commands,
dependencies, and environment defaults in Compose.

If Compose has more than one service, name the visitor-facing service `app`.
Pin every service that uses `image` without `build`. Use typed companions for
platform-managed databases and caches. Do not infer a companion type from a
service or image name.

Application demos use a private writable copy-on-write root filesystem. Do not
set `read_only: true` for an application service. MCP services keep their
documented sandbox rules.

## Credentials and setup

The launch UI must show all values and instructions that a visitor needs.

- Put public defaults in the image or Compose.
- Use `owner: droplive` for a session value that DropLive generates.
- Add login metadata for a generated value that the visitor uses to sign in.
- Use `sign_in` only for an immutable public credential that the upstream image
  already accepts and cannot replace at startup.
- Use a typed companion or reviewed emulator for supported external services.
- Never commit a password, token, private key, or API key.

BYOK is allowed only on a reviewed capability whose schema permits `byok: true`.
The normal launch must still use the emulator. Never add a real key, a custom
provider form, or an operator-input key variable to a recipe.

## Validate and verify

Run:

```sh
python3 tools/lint_recipes.py
python3 tools/test_environment_schema.py
python3 tools/test_kind_schema.py
python3 tools/test_entrypoint_rules.py
```

Unknown keys fail validation by design.

A passing validator, build, health probe, or MCP readiness check creates only a
candidate. It does not authorize listing. Before an exact version is listed, a
reviewer must complete the public browser gate in
[`docs/catalogue-verification.md`](docs/catalogue-verification.md).

## Pull request checklist

- [ ] `description` and canonical HTTPS `repository` are present and correct.
- [ ] The recipe is the smallest complete statement of runtime intent.
- [ ] Every recipe-owned base image and image-only Compose service is digest-pinned.
- [ ] Compose preserves each required application service.
- [ ] The visitor-facing service has a readiness check that proves it is ready.
- [ ] The launch metadata provides every required credential and setup value.
- [ ] No secret is committed.
- [ ] Any BYOK opt-in uses a supported capability and keeps the emulator default.
- [ ] All validators pass.
- [ ] The exact version remains unlisted until public browser verification passes.
