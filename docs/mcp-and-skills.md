# MCP servers and skills

MCP servers and skills are different recipe kinds.

## MCP servers

Use `kind: mcp` only for a process that completes MCP protocol negotiation over
`stdio` or Streamable HTTP.

An MCP recipe can use a pinned package, a recipe-root Dockerfile, or recipe-root
Docker Compose. Compose is a first-class multi-service input. A package recipe
identifies one exact package release and cannot also select a source build.

Every MCP recipe must declare:

- its local transport;
- `network: none` or `network: observed`; and
- one bounded, deterministic, read-only smoke tool call.

For `stdio`, DropLive starts the command directly without a shell. For
Streamable HTTP, the service runs inside the isolated session and declares only
its local MCP path. A recipe cannot supply a remote MCP endpoint.

Qualification requires initialization, tool discovery, and the reviewed smoke
call. A process probe or bridge health response is not sufficient. Qualification
does not remove a separate browser listing gate for a public browser surface.

Unknown keys fail the public JSON Schema by design. MCP unknown-key handling was
not defective.

## Skills

Use `kind: skill` only when `SKILL.md` is the instruction entrypoint and the
product does not provide an MCP transport. The schema and validator can review a
skill declaration. DropLive does not currently provide public skill execution
or listing. Do not describe a validated skill recipe as a working public demo.

A repository that contains an MCP server and a skill needs two recipe folders.
Do not combine the two product kinds in one recipe.

## Shared safety rules

- Treat source, package files, instructions, tool descriptions, arguments, and
  results as untrusted.
- Do not use privileged mode, host networking, host mounts, or Docker socket
  access.
- Use reviewed companions and emulator capabilities. Do not send real vendor
  credentials.
- MCP and skill recipes do not offer BYOK. Use reviewed fixtures only.
- Redact generated secrets before evidence storage.
