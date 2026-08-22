#!/usr/bin/env python3
"""Check the MCP and skill recipe boundaries."""

import json
import tempfile
from pathlib import Path

from jsonschema import Draft202012Validator
from lint_recipes import compose_errors, dockerfile_errors, mcp_errors


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = json.loads((ROOT / "schema/droplive.recipe.v1.schema.json").read_text())
VALIDATOR = Draft202012Validator(SCHEMA)


# This file tests `kind`, not the root required fields. Filling them in keeps a
# missing description from becoming the reason something is judged invalid --
# without it every `invalid` case would pass for the wrong reason.
ROOT_DEFAULTS = {
    "description": "A fixture recipe used only by this test",
    "repository": "https://github.com/example/project",
}


def complete(recipe):
    return {**ROOT_DEFAULTS, **recipe}


def valid(recipe):
    errors = list(VALIDATOR.iter_errors(complete(recipe)))
    assert not errors, [error.message for error in errors]


def invalid(recipe):
    assert list(VALIDATOR.iter_errors(complete(recipe)))


def mcp(transport="stdio", **fields):
    document = {
        "transport": transport,
        "network": "none",
        "tools": {"smoke": {"name": "read_status", "arguments": {}}},
    }
    if transport == "stdio":
        document["command"] = ["server"]
    else:
        document["path"] = "/mcp"
    document.update(fields)
    return {"version": 1, "kind": "mcp", "mcp": document}


valid({
    "version": 1,
    "kind": "mcp",
    "mcp": {
        "transport": "stdio",
        "command": ["node", "dist/index.js"],
        "network": "none",
        "tools": {"smoke": {"name": "read_status", "arguments": {}}},
    },
})
valid(mcp("streamable-http"))
valid(mcp("streamable-http", command=["server"]))
valid(mcp(network="observed", expected_hosts=["api.example.com", "*.example.com"]))
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
    "mcp": mcp()["mcp"],
})
invalid({
    "version": 1,
    "kind": "api",
    "skill": {"entrypoint": "SKILL.md"},
})
invalid({
    "version": 1,
    "kind": "mcp",
    "mcp": mcp()["mcp"],
    "skill": {"entrypoint": "SKILL.md"},
})
invalid({
    "version": 1,
    "kind": "mcp",
    "mcp": mcp(path="/mcp")["mcp"],
})
invalid({
    "version": 1,
    "kind": "mcp",
    "mcp": mcp("streamable-http", endpoint="https://example.com/mcp")["mcp"],
})
invalid({"version": 1, "kind": "mcp", "mcp": {"transport": "stdio"}})
invalid(mcp(network="none", expected_hosts=["api.example.com"]))
invalid(mcp(network="observed", expected_hosts=["https://api.example.com"]))
invalid(mcp(network="observed", expected_hosts=["10.0.0.1"]))
invalid(mcp(network="observed", expected_hosts=["api.example.com:443"]))
invalid(mcp(network="observed", expected_hosts=["api.example.com/path"]))
invalid(mcp(network="observed", expected_hosts=["user@api.example.com"]))
invalid(mcp(network="observed", expected_hosts=["*example.com"]))

package_recipe = mcp(
    package={
        "manager": "npm",
        "name": "example-mcp",
        "version": "1.2.3",
        "integrity": "sha256:" + "0" * 64,
    }
)
valid(package_recipe)
invalid({**package_recipe, "build": {"dockerfile": "Dockerfile"}})

assert mcp_errors(mcp(command=["server", "{{MISSING_VALUE}}"])) == [
    "MCP command uses undeclared runtime value MISSING_VALUE"
]

declared_runtime_value = mcp(command=["server", "{{ENDPOINT}}"])
declared_runtime_value["environment"] = {"ENDPOINT": {"owner": "user"}}
assert mcp_errors(declared_runtime_value) == []

embedded_runtime_value = mcp(command=["server", "--endpoint={{ENDPOINT}}"])
embedded_runtime_value["environment"] = {"ENDPOINT": {"owner": "user"}}
assert mcp_errors(embedded_runtime_value) == [
    "MCP runtime value must be one complete command argument: --endpoint={{ENDPOINT}}"
]

incomplete_runtime_value = mcp(command=["server", "{{ENDPOINT}"])
incomplete_runtime_value["environment"] = {"ENDPOINT": {"owner": "user"}}
assert mcp_errors(incomplete_runtime_value) == [
    "MCP runtime value must be one complete command argument: {{ENDPOINT}"
]

with tempfile.TemporaryDirectory() as directory:
    folder = Path(directory)
    dockerfile = folder / "Dockerfile"
    dockerfile.write_text("FROM scratch\nENTRYPOINT [\"/server\"]\n")
    assert dockerfile_errors(dockerfile, {}, require_network_probe=False) == []
    assert len(dockerfile_errors(dockerfile, {}, require_network_probe=True)) == 2

    # read_only cuts both ways now. An application is given a writable
    # copy-on-write root, so asking for a read-only one is the mistake; an MCP or
    # emulator container still has to set it.
    head = "services:\n  app:\n    image: scratch@sha256:" + "0" * 64 + "\n"
    compose = folder / "docker-compose.yaml"

    compose.write_text(head + "    read_only: true\n")
    assert compose_errors(compose, None, {}, False, "mcp") == []
    assert len(compose_errors(compose, None, {}, True, "mcp")) == 2
    assert compose_errors(compose, None, {}, False, "app") == [
        "service app sets read_only: true, but an application is given a writable "
        "root filesystem; remove it and the workarounds it forced"
    ]

    compose.write_text(head)
    assert compose_errors(compose, None, {}, False, "app") == []
    assert compose_errors(compose, None, {}, False, "mcp") == [
        "service app must set read_only: true"
    ]

print("MCP and skill schema cases passed")
