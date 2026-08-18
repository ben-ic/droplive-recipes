# Coding-agent prompt

Copy the prompt below into your coding agent. Replace `SOURCE` with a public
GitHub URL or the absolute path to a repository on your computer.

```text
Create the smallest working DropLive recipe for this source:

SOURCE: <GitHub URL or absolute local path>

Work in a clone of the droplive-recipes repository. Read README.md,
CONTRIBUTING.md, docs/recipe-format.md, and docs/troubleshooting.md before you
edit files.

Goal:
- Add one recipe under recipes/<kind>/<github-owner>/<github-repository>/.
- Make the project build and start with a read-only root filesystem.
- Keep droplive.yaml as small as possible.

Rules:
1. Inspect the source before you choose a build path.
2. Set kind to app, api, mcp, or skill.
3. If one upstream Docker Compose file or Dockerfile already works, do not copy
   it. Start with only:

     version: 1
     kind: <kind>

4. If several upstream build files exist, select the exact file in build.
5. If upstream does not work, add recipe-owned docker-compose.yaml. Prefer
   Compose before a replacement Dockerfile.
6. Name the main Compose service app when practical. Set read_only: true. Use
   tmpfs for temporary writes and volumes for persistent data. Add a real health
   check.
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

Test the selected Docker or Compose path. Confirm:
- it builds for linux/amd64;
- it starts without privileged mode or host networking;
- it starts with a read-only root filesystem;
- its health check proves readiness;
- every write goes to tmpfs or declared persistent data;
- no secret is present in the committed files.

If the project cannot meet a DropLive limit, stop and report the exact limit.
Do not weaken the limit. At the end, list the files you added, the command you
used to validate them, and anything that still needs review.
```
