# MCP servers and skills

MCP servers and skills are different products. DropLive must classify and test
them in different ways.

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
| Answers MCP `initialize` | Required | No |
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
- denied network access except for reviewed emulator capabilities; and
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

### Check the protocol

The test client performs this sequence:

1. Send `initialize` with the protocol version supported by DropLive.
2. Check the server name, version, and advertised capabilities.
3. Send the initialized notification.
4. List each advertised primitive: tools, resources, prompts, and resource
   templates.
5. Reject malformed JSON-RPC, duplicate names, invalid schemas, and responses
   that do not match the advertised capability.
6. Invoke reviewed test cases with fixed fixture input.
7. Close the client and confirm that the server exits or becomes idle cleanly.

Listing is not sufficient evidence. At least one advertised operation must run.
An operation that can change data runs only against a disposable fixture. A
server with no safe deterministic operation needs a reviewed test case before
it can pass.

### Test data and authentication

Recipes use the same emulator and companion declarations as applications:

- SMTP uses `mail.smtp.v1`.
- Gmail and Google OAuth use the Google capabilities and reviewed mailbox
  datasets.
- S3 uses `storage.s3.v1`. DropLive supplies a real S3-compatible service, a
  bucket, and credentials for this test only.
- PostgreSQL, MySQL, MariaDB, MongoDB, Redis, and Upstash use companions.
- Other vendor sign-in and API calls use reviewed emulator capabilities.

The recipe maps capability outputs to the environment names that the server
expects. DropLive never sends a real vendor credential. If no capability or
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
