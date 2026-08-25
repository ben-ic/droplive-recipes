# Troubleshooting recipes

Start with the first failing step. Do not add fields before an error asks for
them.

## DropLive found several build files

Recipe import sends only the recipe folder to the build. Put the selected
Dockerfile or `docker-compose.yaml` at the recipe root. When Compose has several
services, name the visitor-facing service `app`.

## The image builds but the application does not start

Run it the way a demo runs it: a writable root filesystem, no volumes and no
tmpfs.

```bash
docker run --rm -p 8080:<port> <your-image>
```

Adding a volume is almost never the fix, and used to be the cause. A declared
path arrived as a fresh empty filesystem and hid whatever the image had put
there, so an application looking for its own shipped files found none.

If the container exits at once, read its first ten lines. A missing required
variable, not the filesystem, is the usual answer.

## The application starts but never becomes ready

Check the main port and health path:

```yaml
run:
  port: 3000
  health: /health
```

Use response text when HTTP 200 is not enough:

```yaml
run:
  health:
    path: /api/status
    contains:
      - '"ready":true'
```

## A required environment variable is missing

First decide who supplies it:

- Put a public literal or default in Docker Compose when the recipe supplies it.
- Make it optional in Docker Compose when the application can run without it.
- Add `owner: droplive` to `droplive.yaml` when DropLive must generate it.
- Add `owner: user` only when a human must supply it.
- Use a companion for a database or cache connection.
- Use an emulator binding for a supported external service.

A recipe entrypoint declares required values too. `: "${NAME:?message}"` marks
`NAME` as required, and DropLive reads those guards. Most recipes need no
`environment` section for that reason.

For a generated value, `format` defaults to `url-safe`. Supported formats are
`hex`, `url-safe`, `alphanumeric`, `password`, `base64`, and
`laravel-base64`. See [the recipe reference](recipe-format.md) for length and
pattern rules. Use `login` when this generated value is the visitor sign-in
credential. An entrypoint annotation can also declare a bootstrap credential.

Never add a real secret to Git.

## The demo shows no sign-in credential

The sign-in card can come from `environment.<name>.login` or a `# droplive:`
annotation on the recipe entrypoint. For an annotation, check:

- the annotated variable is also required in the same script with
  `${NAME:?…}`;
- the line carries `capability=owner-login` or `capability=admin-login`, and
  that value agrees with its `purpose`;
- **only one** line in that script carries `capability=`, because a second one
  removes the card; and
- the variable name contains `PASSWORD`, `PASS`, `SECRET`, or `TOKEN` as a whole
  word, and is not a connection or third-party credential.

See [entrypoint declarations](recipe-format.md#entrypoint-declarations).

## The application got a random string instead of its URL

The recipe declared an origin variable as `owner: droplive`. That asks DropLive
to generate a value, and generating wins over the rule that supplies the session
origin.

Remove it from `environment`. Require the name in the entrypoint instead and let
DropLive recognise its shape. See
[the public origin](recipe-format.md#the-public-origin).

## An external API is required

Check [`capabilities/v1.yaml`](../capabilities/v1.yaml). If the capability is
present, declare an emulator binding. If it is absent, state the missing
capability in the pull request. Do not point the recipe at your own server.

BYOK is not an automatic fallback. Use `byok: true` only when the reviewed
capability supports it. The default launch must continue to use the emulator.

## The repository contains both an MCP server and a skill

Create two recipe folders for the same source: one under `recipes/mcp/` and one
under `recipes/skill/`. Each recipe has its own entrypoint, sandbox, evidence,
and admission result. Do not put both sections in one recipe.

Use the behavior test in [MCP servers and skills](mcp-and-skills.md). A process
that completes supported MCP protocol negotiation is an MCP server. A
`SKILL.md` file that an agent loads as instructions is a skill.

## An MCP server starts but the test cannot use it

For `stdio`, confirm that the command writes only MCP messages to standard
output. Send diagnostics to standard error. Do not wrap the command in a shell.

For Streamable HTTP, confirm that `mcp.path` is the exact endpoint and that the
service listens on the allocated container port. The endpoint is not made
public during the test.

The server must complete protocol negotiation, list its advertised primitives,
and run at least one reviewed operation. For Streamable HTTP, a successful HTTP
health check without an MCP operation is not a passing MCP test.

## A skill asks for a tool or credential that the test does not provide

Declare the needed fixture through a reviewed emulator capability or companion.
The scenario must allow each tool that the skill needs. Do not expand the
allowlist to every installed tool.

If the dependency has no reviewed capability, report it as unsupported. Do not
give the skill a real vendor credential or unrestricted network access.

## The project needs a database or cache

Declare a named companion:

```yaml
companions:
  database: postgres
```

For a platform-managed database or cache, use the short form and do not add an
arbitrary service image. If the application requires an exact Compose image,
keep that image and use the expanded form with the same service name, an
explicit `type`, and the required environment `bindings`. The image name does
not select the companion type.

## The project needs privileged mode, host networking, or a writable root

These modes are not supported. Change the build or entrypoint so the project can
run without them. If the software fundamentally requires one of these modes, it
cannot run as a DropLive recipe.

## The validator rejects a base image

Pin the image by digest:

```dockerfile
FROM ghcr.io/example/image@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

Tags are mutable and are not accepted in recipe-owned Dockerfiles.

## The pinned image registry returns a rate limit

Do not remove the digest pin or retry a failed import in a loop. First resolve an
alternate public registry for the same upstream image, inspect its manifest, and
replace the `FROM` value with that registry's immutable index digest. Commit the
recipe change, rebuild it, and verify the resulting public demo before listing it.
