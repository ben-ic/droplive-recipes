# Coding-agent prompt

Copy the prompt below into your coding agent. Replace `SOURCE` with a public
GitHub URL or the absolute path to a repository on your computer.

```text
Create the smallest working DropLive recipe for this source:

SOURCE: <GitHub URL or absolute local path>

Work in a clone of the droplive-recipes repository. Read README.md,
CONTRIBUTING.md, docs/recipe-format.md, and docs/troubleshooting.md before you
edit files. For an MCP server or skill, also read docs/mcp-and-skills.md.

Goal:
- Add one recipe under recipes/<kind>/<github-owner>/<github-repository>/.
  For several MCP products in one repository, add a product subfolder and the
  matching product slug.
- For an app, API, or MCP server, make the project build and start with a
  read-only root filesystem.
- For a skill, identify the complete instruction package and its entrypoint.
- Keep droplive.yaml as small as possible.

Rules:
1. Inspect the source before you choose a build path.
2. Set kind to app, api, mcp, or skill.
   - Use mcp only when a process answers MCP initialize over stdio or
     Streamable HTTP.
   - Use skill only when SKILL.md is the instruction entrypoint and the product
     does not provide an MCP transport.
   - If the source contains both, create one recipe for each product. Do not mix
     mcp and skill in one recipe.
3. For an app or API, if one upstream Docker Compose file or Dockerfile already
   works, do not copy it. Start with only:

     version: 1
     kind: <kind>

4. If several upstream build files exist, select the exact file in build.
5. For a runtime recipe, if upstream does not work, add recipe-owned
   docker-compose.yaml. Prefer Compose before a replacement Dockerfile.
6. Name the main Compose service app when practical. Set read_only: true. Use
   tmpfs for temporary writes and volumes for persistent data. Add an HTTP
   health check for an app, API, or Streamable HTTP MCP server. A stdio MCP
   server does not need a port or HTTP health check.
7. Add a recipe Dockerfile or entrypoint only when Compose cannot fix the
   problem. Pin every FROM image by sha256 digest.
8. Put normal public defaults and optional variables in Docker Compose. In
   droplive.yaml, declare only values that DropLive must generate or ask the
   visitor to supply. Use owner: droplive or owner: user. For generated values,
   use only the documented formats: hex, url-safe, alphanumeric, password,
   base64, or laravel-base64. Add length or a safe RE2 pattern only when the
   application requires it. Never commit a secret or add a # droplive:
   entrypoint annotation.
9. Use companions for databases and caches. Use only listed emulator
   capabilities for external services. Never add an arbitrary external host.
10. Do not put a repository URL, branch, tag, commit, measurement, artifact
    digest, or secret in droplive.yaml.
11. Do not change the source repository. Test changes in a temporary working
    copy. Recipe files can overlay that working copy for testing.
12. When safe, add realistic sample data with seed.sh. Use the application's API,
    official CLI, or official import format. Do not write private database tables.
    Keep seed data deterministic, repeatable, obviously fictional, and free of
    secrets. Skip seeding when the project has no stable seeding interface.
13. Run python3 tools/lint_recipes.py before you finish.
14. For every MCP recipe, declare one network mode:
    - Use `network: {mode: none, destinations: []}` only when the server works
      without outbound network access.
    - Use `network: {mode: observed, destinations: ["*"]}` when the server must
      reach the internet or a visitor can select the destination. DropLive
      allows the traffic and records the actual destinations in the receipt.
    - Replace `"*"` with fixed expected hostnames only when the server always
      uses that complete set. Do not put URLs, paths, ports, credentials, or
      private IP addresses in `destinations`.
15. For every MCP recipe, add at least one small, deterministic `tools.smoke`
    call. It must be read-only unless it uses a disposable fixture. It must not
    use private data, a real vendor credential, an unbounded query, or a
    destructive operation. Use `tools.examples` only for useful optional
    starting arguments. Do not copy the full tool catalog into the recipe.
16. Verify MCP initialize, capability listing, and every smoke call against
    disposable fixtures. A process that stays alive without a successful MCP
    operation does not pass.
17. Use a registry package only when the recipe represents that exact package
    release. Verify that it belongs to the source project. Do not replace a
    requested source commit with an unrelated package release. Do not combine a
    package release and a source build unless their relationship is explicit
    and verified. For a package build, resolve and hash the complete dependency
    closure. Treat that closure as part of the tested artifact identity.
18. Resolve every runtime dependency. For example, a browser-control MCP server
    must have a pinned browser binary in its artifact or use a documented
    browser capability or companion. Do not assume that Chrome, Chromium, a
    Playwright browser, a database, or another service is already installed. If
    the repository cannot express the dependency, stop and report it as
    unsupported.
19. Use the documented capability for a vendor-like service. For example, use
    `storage.s3.v1` for S3. Do not also declare an S3 companion. Use companions
    only for the dependency types listed in the repository. A recipe declares
    the capability it needs, not private DropLive topology.
20. For a skill, verify observable effects with a fixed prompt and an explicit
    tool allowlist. Never use a real vendor credential for an MCP or skill test.

For an app, API, or MCP server, test the selected Docker or Compose path. Confirm:
- it builds for linux/amd64;
- it starts without privileged mode or host networking;
- it starts with a read-only root filesystem;
- every write goes to tmpfs or declared persistent data;
- no secret is present in the committed files.

For an app, API, or Streamable HTTP MCP server, confirm that its HTTP health
check proves readiness. For a stdio MCP server, confirm the MCP handshake and at
least one operation instead. Do not add a port or HTTP health check only to
satisfy the recipe.

For a skill, confirm:
- `skill.entrypoint` resolves inside the pinned source tree;
- all referenced local files stay inside that tree;
- the package has no embedded secret or undeclared download; and
- fixed scenarios produce observable fixture effects without an unlisted tool
  or network destination.

If the project cannot meet a DropLive limit, stop and report the exact limit.
Do not weaken the limit. At the end, list the files you added, the command you
used to validate them, and anything that still needs review.
```
