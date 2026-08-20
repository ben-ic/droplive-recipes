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
3. For an app or API, write two files and nothing else to begin with:

     recipes/app/<owner>/<repo>/droplive.yaml
       version: 1
       kind: <kind>
       run:
         port: <container port>
         health: <path returning 200 only when ready>
         data: [<every directory written at runtime>]

     recipes/app/<owner>/<repo>/Dockerfile
       FROM <published image>@sha256:<digest>
       EXPOSE <container port>

   run.port is required. Do not use the build field; nothing reads it.
4. Find the published image the project itself publishes, and resolve its digest
   from the registry. Do not copy an upstream Dockerfile or Compose file.
5. Run it before adding anything. Extend the pinned image in the Dockerfile when
   it needs a command or an environment default. Add an entrypoint script only
   when startup itself must do something first, and say in a comment which
   failure caused it. A recipe-owned docker-compose.yaml is supported but rarely
   the right answer for one container.
6. Every path in run.data is mounted EMPTY. Nothing is copied from the image, so
   a directory the image ships is hidden rather than extended, and a directory
   the image only expects to exist will not. List a path because the application
   writes there, not because the data matters. If startup needs files at that
   path, bake a template elsewhere in the image and restore it from an entrypoint
   before the application starts. Test with empty, non-seeded volumes: an
   ordinary Docker named volume is seeded from the image and will hide this.
7. Pin every recipe-owned FROM image by sha256 digest. Do not copy a complete
   upstream Dockerfile only to make a small runtime change. Extend a pinned
   upstream image with the smallest required adaptation.
8. Put normal public defaults and optional variables in Docker Compose. In
   droplive.yaml, declare only values that DropLive must generate or ask the
   visitor to supply. Use owner: droplive or owner: user. For generated values,
   use only the documented formats: hex, url-safe, alphanumeric, password,
   base64, or laravel-base64. Add length or a safe RE2 pattern only when the
   application requires it. DropLive injects these declared values when it
   starts the service. Do not repeat them in Docker Compose. Never commit a
   secret. To name which generated value a visitor signs in with, add
   login: {username: <literal>} to that variable; the username has to be a
   literal the visitor can read, so a value whose username is also generated
   cannot use it.
9. Declare required runtime values in the recipe entrypoint with
   : "${NAME:?message}". DropLive reads those guards, so most recipes need no
   environment section at all. For a credential the application owns and
   DropLive mints per demo, add the annotation line directly above its guard:
   # droplive: generate=hex96 ownership=app purpose=owner-bootstrap
   lifecycle=stable rotation=none name=NAME capability=owner-login
   username=admin. The fields are fixed and ordered; generate is hex64 or
   hex96; rotation is app only when the application can change the value after
   sign-in. Add capability= only to the one credential a person signs in with,
   and never twice in the same script, because a second one removes the sign-in
   card. The annotated name needs PASSWORD, PASS, SECRET, or TOKEN as a whole
   word, and cannot be a connection or third-party credential. If the entrypoint
   checks the shape of a value it was given, check a MINIMUM length and the
   character set. Never assert an exact length: a longer value is still usable,
   and the check exits before the application ever binds a port, so the failure
   reads as a broken application rather than a recipe asserting a shape.
10. Never declare the demo's own URL. DropLive supplies the session origin to a
    name shaped like an origin: exactly APP_URL, AUTH_URL, NEXTAUTH_URL, or
    ROOT_URL, or any name ending in _ROOT_URL, _SITE_URL, _BASE_URL, or
    _PUBLIC_URL. Require it in the entrypoint and stop there. Require it even when
    upstream treats it as optional, if the application writes its own address
    into the pages it serves: DropLive fills in what an application REQUIRES,
    so a variable that merely asks politely is never bound, and the app then
    emits its internal address. Verdaccio served a blank page that way -- its
    <base href> pointed at a bridge IP no visitor can reach, while the root
    still answered 200 and every probe called it healthy. Declaring an
    origin variable as owner: droplive is a bug: the application then receives a
    random secret where its URL should be.
11. When the demo serves a login page, ask one question first: does the
    application take its password from the environment? Check before choosing.
    - If it DOES, mint one. Declare the variable owner: droplive with
      login: {username: <literal>}, and the card shows a credential belonging to
      that one session. Grafana, MinIO, Directus and Langflow all work this way.
      The username stays a literal, which is what makes login.username usable --
      only the password is generated.
    - Only if it does NOT, state the shipped credential as
      sign_in: {username, password, note}. File Browser writes admin/admin into
      a fresh database and offers no way to change it, so the recipe is the only
      thing that can tell the visitor.
    Do not state a published default merely because it is simpler. A credential
    printed in the application's own documentation is one every reader already
    knows, live on a reachable demo, and the fix costs one declaration. sign_in
    is for credentials DropLive cannot change, not credentials nobody changed.
12. Use companions for databases and caches. Use only listed emulator
    capabilities for external services. Never add an arbitrary external host.
    DropLive reads only the short companion form today.
13. Do not put a repository URL, branch, tag, commit, measurement, artifact
    digest, or secret in droplive.yaml.
14. Do not change the source repository. Test changes in a temporary working
    copy. Recipe files can overlay that working copy for testing.
15. When safe, add realistic sample data with seed.sh. Use the application's API,
    official CLI, or official import format. Do not write private database tables.
    Keep seed data deterministic, repeatable, obviously fictional, and free of
    secrets. Skip seeding when the project has no stable seeding interface.
16. Run python3 tools/lint_recipes.py before you finish.
17. For every MCP recipe, select one network mode:
    - Use `network: none` only when the server works without outbound network
      access. DropLive blocks network access when it tests this claim.
    - Use `network: observed` when the server needs network access. DropLive
      allows the traffic and records the actual destinations in the receipt.
    - Use optional `expected_hosts` only to document expected public hostnames.
      It does not allow or block traffic. Do not put URLs, paths, ports,
      credentials, or IP addresses in it.
18. Give every MCP recipe one small, deterministic `tools.smoke` call. It must
    be read-only, bounded, and independent of private user data. Use public or
    disposable fixture data. Use `tools.examples` only for useful optional
    starting arguments. Do not copy the full tool catalog into the recipe.
19. Verify MCP initialize, capability listing, and the smoke call against
    disposable fixtures. A process that stays alive without a successful MCP
    operation does not pass. Never use a real vendor credential.
20. Treat an MCP package recipe as one exact package release. Verify that the
    package belongs to the source project. Do not replace a requested source
    commit with an unrelated package release. Do not combine `mcp.package` with
    a source build. A source recipe builds the exact requested Git commit.
21. For an MCP package build, resolve and hash the complete dependency closure.
    Treat that closure as part of the tested artifact identity.
22. Resolve every runtime dependency. A browser-control MCP server must use the
    documented browser capability or include a pinned browser in its artifact.
    Do not assume that Chrome, Chromium, a Playwright browser, a database, or
    another service is installed. If the recipe cannot express the dependency,
    stop and report it as unsupported.
23. When an MCP command needs a runtime value, put the complete `{{NAME}}` token
    in its own command argument and declare the matching environment, emulator,
    or companion binding. Do not embed a token inside another argument.
24. Use the documented capability for a vendor-like service. For example, use
    `storage.s3.v1` for S3. Do not also declare an S3 companion. Use companions
    only for dependency types listed in the repository. A recipe declares the
    capability it needs, not private DropLive topology.
25. For a skill, verify observable effects with a fixed prompt and an explicit
    tool allowlist. Never use a real vendor credential.

For an app, API, or MCP server, test the selected Docker or Compose path. Confirm:
- it builds for linux/amd64;
- it starts without privileged mode or host networking;
- it starts with a read-only root filesystem;
- every writable volume starts empty;
- the application does not depend on Docker named-volume copy-up;
- files required at startup remain available after writable mounts are attached;
- every write goes to tmpfs or declared persistent data;
- values declared in droplive.yaml, companions, and emulators are injected only
  at runtime; and
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
