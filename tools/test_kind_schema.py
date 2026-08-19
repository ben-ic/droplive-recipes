#!/usr/bin/env python3
"""Check the MCP and skill recipe boundaries."""

import json
import tempfile
from pathlib import Path

from jsonschema import Draft202012Validator
from lint_recipes import compose_errors, dockerfile_errors


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = json.loads((ROOT / "schema/droplive.recipe.v1.schema.json").read_text())
VALIDATOR = Draft202012Validator(SCHEMA)


def valid(recipe):
    errors = list(VALIDATOR.iter_errors(recipe))
    assert not errors, [error.message for error in errors]


def invalid(recipe):
    assert list(VALIDATOR.iter_errors(recipe))


valid({
    "version": 1,
    "kind": "mcp",
    "mcp": {"transport": "stdio", "command": ["node", "dist/index.js"]},
})
valid({
    "version": 1,
    "kind": "mcp",
    "mcp": {"transport": "streamable-http", "path": "/mcp"},
})
valid({
    "version": 1,
    "kind": "mcp",
    "mcp": {"transport": "streamable-http", "path": "/mcp", "command": ["server"]},
})
valid({
    "version": 1,
    "kind": "mcp",
    "mcp": {"transport": "stdio"},
    "build": {"dockerfile": "Dockerfile"},
})
valid({
    "version": 1,
    "kind": "skill",
    "skill": {"entrypoint": "SKILL.md"},
})

invalid({"version": 1, "kind": "mcp"})
invalid({"version": 1, "kind": "skill"})
invalid({
    "version": 1,
    "kind": "app",
    "mcp": {"transport": "stdio", "command": ["server"]},
})
invalid({
    "version": 1,
    "kind": "api",
    "skill": {"entrypoint": "SKILL.md"},
})
invalid({
    "version": 1,
    "kind": "mcp",
    "mcp": {"transport": "stdio", "command": ["server"]},
    "skill": {"entrypoint": "SKILL.md"},
})
invalid({
    "version": 1,
    "kind": "mcp",
    "mcp": {"transport": "stdio", "command": ["server"], "path": "/mcp"},
})
invalid({
    "version": 1,
    "kind": "mcp",
    "mcp": {"transport": "streamable-http", "path": "/mcp", "endpoint": "https://example.com/mcp"},
})

with tempfile.TemporaryDirectory() as directory:
    folder = Path(directory)
    dockerfile = folder / "Dockerfile"
    dockerfile.write_text("FROM scratch\nENTRYPOINT [\"/server\"]\n")
    assert dockerfile_errors(dockerfile, {}, require_network_probe=False) == []
    assert len(dockerfile_errors(dockerfile, {}, require_network_probe=True)) == 2

    compose = folder / "docker-compose.yaml"
    compose.write_text("services:\n  app:\n    image: scratch@sha256:" + "0" * 64 + "\n    read_only: true\n")
    assert compose_errors(compose, None, {}, require_network_probe=False) == []
    assert len(compose_errors(compose, None, {}, require_network_probe=True)) == 2

print("MCP and skill schema cases passed")
