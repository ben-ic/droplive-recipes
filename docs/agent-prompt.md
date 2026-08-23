# Coding-agent prompt

Replace `SOURCE` and use this prompt:

```text
Create the smallest complete DropLive recipe for this source:

SOURCE: <public repository URL or absolute local path>

Work in a clone of droplive-recipes. Read README.md, CONTRIBUTING.md,
docs/recipe-format.md, and docs/troubleshooting.md. For MCP or skill work, also
read docs/mcp-and-skills.md.

Rules:
1. Inspect the source and its published runtime before you edit the recipe.
2. Create recipes/<kind>/<forge-owner>/<repository>/.
3. Set version: 1 and the correct kind.
4. Add required description and canonical HTTPS repository. The recipe owns
   these values. Do not add stars, homepage, licence, or other changing forge
   facts.
5. Start with a digest-pinned recipe-root Dockerfile for one service.
6. Use a recipe-root docker-compose.yaml when the application has multiple
   required application-owned services. Docker Compose is a first-class input.
   Preserve the service topology. Name the visitor-facing service app when the
   file has multiple services.
7. Pin all recipe-owned base images and image-only Compose services by digest.
8. Add the public port and a readiness check that passes only when the service
   is ready.
9. Put public defaults in the image or Compose. Declare only values that
   DropLive must generate or the visitor must provide.
10. Provide login and setup metadata for every value that the launch UI must
    show. A visitor must not need private contributor knowledge.
11. Use typed companions for databases and caches and reviewed emulators for
    supported external services.
12. Do not commit a secret, and do not try to enable a real provider from the
    recipe. Whether a capability may be a visitor's own provider is DropLive's
    decision, not the recipe's; bind the capability and the platform decides.
13. Do not use privileged mode, host networking, host mounts, or Docker socket
    access.
14. Run all repository validators.
15. Treat a passing build or probe as a candidate only. Do not claim that it is
    ready for listing. An exact version needs separate public browser
    verification that reaches a useful screen.

Report the files changed, the commands run, the build result, and any value or
instruction that the launch UI must show.
```
