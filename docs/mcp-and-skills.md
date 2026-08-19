# MCP servers and skills

MCP servers and skills are different products. DropLive must classify and test
them in different ways.

> **Status: planned DropLive test contract.** DropLive does not run MCP or skill
> recipe tests yet. The schema and linter enforce the static boundaries that are
> present in this repository. The build-brain behavior, sandbox execution,
> evidence capture, and admission flow below are requirements for the future
> implementation, not claims about the current service.

## Classification rule

Use `kind: mcp` when the repository starts a process that implements the Model
Context Protocol. The process must accept MCP JSON-RPC messages through `stdio`
or Streamable HTTP.

Use `kind: skill` when the repository provides instructions in `SKILL.md` for an
agent to follow. A skill can include scripts and reference files, but the skill
itself does not provide an MCP transport.

Do not classify from the repository name, topic, or README claim. Use behavior:

| Check | MCP server | Skill |
|---|---|---|
| Has an MCP transport | Required | No |
| Completes MCP protocol negotiation | Required | No |
| Has a `SKILL.md` entrypoint | Optional documentation only | Required |
| Runs as a service | Yes | No |
| Is loaded as agent instructions | No | Yes |

A repository that contains both products needs two recipe folders. Each recipe
has one kind and one test result. A recipe cannot contain both `mcp` and `skill`.

## Common trust boundary

Treat the source, package files, instructions, scripts, tool descriptions, tool
arguments, and tool results as untrusted.

Each test gets a new sandbox with:

- no host mount, Docker socket, host network, or privileged mode;
- a read-only root filesystem and declared temporary writable paths;
- fixed CPU, memory, process, file, output, and time limits;
- no real vendor credential;
- the network mode declared by the recipe, with all allowed traffic observed
  and reviewed fixture services used in place of real vendor credentials; and
- new fixture credentials that expire with the test.

DropLive records process output, network destinations, MCP messages, tool calls,
and fixture changes. It removes generated secrets before it stores or shows the
evidence.

The first release must not add automatic retries or an agent repair loop. One
test must give one clear result. A changed source commit or recipe commit needs
a new test.

## MCP server test

### Start the server

For `stdio`, DropLive starts the declared command directly. It does not use a
shell. Standard output belongs only to MCP messages. Diagnostic output belongs
on standard error.

For `streamable-http`, DropLive starts the built service on an allocated port.
Only the declared MCP path is given to the test client. The listener stays
inside the sandbox.

A public recipe cannot provide a remote MCP endpoint. DropLive derives the
internal endpoint from the locally started service and the declared path.

An MCP server can use the same source, Dockerfile, Compose, and pinned-image
build paths as an app. A registry package is one optional build path. For a
package build, DropLive verifies the declared top-level archive, resolves and
hashes the full dependency closure, and attaches that closure to the tested
artifact identity before the user session starts.

A package recipe identifies one exact package release. It does not build server
code from the requested Git commit. A source recipe builds the exact requested
Git commit. A recipe cannot combine `mcp.package` with `build`. A future format
can permit both only when qualification can verify their exact relationship.

The repository path still identifies the product for review. For a package
recipe, a source commit is repository context only. It is not part of the MCP
server artifact. The user interface must not present another source commit as a
different server version for that package recipe.

### Network mode

Every MCP recipe selects one mode:

- `network: observed` allows network access. DropLive records the actual
  destinations in the receipt.
- `network: none` states that the server works without network access. DropLive
  blocks network access to test this statement.

An observed recipe can add `expected_hosts`. These names help review and can
explain expected public traffic. They never permit or block traffic. Each item
must be a hostname or a wildcard hostname such as `*.githubusercontent.com`.
URLs, IP addresses, ports, paths, and credentials are not valid items.

### Check the protocol

The planned test client performs this sequence:

1. Detect the protocol era. Use `server/discover` for `2026-07-28` and use the
   `initialize` and initialized exchange for a supported legacy version.
2. Check the negotiated protocol version, server identity, and advertised
   capabilities.
3. List each advertised primitive: tools, resources, prompts, and resource
   templates.
4. Reject malformed JSON-RPC, duplicate names, invalid schemas, and responses
   that do not match the advertised capability.
5. Invoke the one reviewed smoke call with fixed fixture input.
6. Close the client and confirm that the server exits or becomes idle cleanly.

Listing is not sufficient evidence. The smoke call must run. It must be
read-only, bounded, deterministic, independent of private user data, and valid
for the declared fixture values. A server with no such operation needs a
reviewed test case before it can pass.

Recipes can provide a small set of useful tool examples. They do not repeat
arguments for every advertised tool. The user interface reads each live tool's
`tools/list` JSON Schema to help create arguments that are not in the recipe.

### Test data and authentication

Recipes use the same emulator and companion declarations as applications:

- SMTP uses `mail.smtp.v1`.
- Gmail and Google OAuth use the Google capabilities and reviewed mailbox
  datasets.
- S3 uses `storage.s3.v1`. Its dependency is a DropLive-provided S3-compatible
  fixture service. DropLive owns the fixture topology, bucket, and per-test
  credentials.
- Chromium uses `browser.chromium.v1`. DropLive provides a reviewed, pinned
  browser artifact and a CDP endpoint. A recipe does not declare the browser
  service topology.
- PostgreSQL, MySQL, MariaDB, MongoDB, Redis, and Upstash use companions.
- Other vendor sign-in and API calls use reviewed emulator capabilities.

The recipe maps capability outputs to the environment names that the server
expects. A command can use a declared runtime value as `{{NAME}}`; DropLive
replaces the complete token before it starts the command directly. DropLive
never sends a real vendor credential. If no capability or
companion can satisfy a required dependency, the result is `unsupported`, not
a test against the real service.

### Evidence

The result shows:

- the source and recipe commits;
- the transport and negotiated protocol version;
- advertised tools, resources, prompts, and templates;
- each test call with redacted arguments and results;
- fixture state changes;
- attempted network destinations; and
- exit, timeout, and resource-limit events.

This evidence lets a reviewer see what the MCP server tried to send to a vendor
emulator. A passing emulator test proves the integration path ran. It does not
prove compatibility with the real vendor.

## Skill test

A skill is not started as a server. DropLive loads the declared `SKILL.md` into
a test agent that has no tools by default.

### Inspect the package

Before agent execution, DropLive:

1. Resolves `skill.entrypoint` inside the pinned source tree.
2. Rejects links and paths that escape the source tree.
3. Reads `SKILL.md` and every referenced local file under fixed file-count and
   size limits.
4. Records included scripts and executable files.
5. Rejects embedded credentials and undeclared remote downloads.

Instructions can request an action. Instructions cannot grant permission for
that action.

### Run scenarios

Each reviewed scenario contains a user prompt, fixture state, an allowed tool
set, and observable success conditions. The test agent follows the skill while
DropLive records its actions.

The test fails when the skill:

- calls a tool outside the scenario allowlist;
- reads or writes outside the sandbox;
- attempts an undeclared network destination;
- asks for a real credential when a fixture is available;
- exposes a generated fixture secret; or
- reports success when the required fixture state did not change.

A text comparison is not enough. DropLive checks observable results, such as a
message in the captured inbox, an object in the S3 bucket, a database row, or a
recorded emulator request.

If a skill requires an MCP server, that server is a separate reviewed input. Its
source digest and test result become part of the skill test evidence. The skill
does not gain access to every installed MCP server.

### Evidence

The result shows the prompt, loaded skill files, allowed tools, tool calls,
redacted arguments and results, fixture changes, network attempts, and final
answer. This is enough to review both the instructions and their effects.

## Admission

Static validation can run on every pull request. Private execution can run for
an unmerged recipe at its pinned commit. Public admission still needs human
review of executable files, permissions, declared capabilities, fixture data,
and the exact evidence from the passing test.

The admitted recipe folder digest, source commit, validator version, capability
registry version, and passing test inputs must match. If one changes, DropLive
tests the new identity again.
