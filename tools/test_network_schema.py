#!/usr/bin/env python3
"""Check the app-level declared network boundary.

`run.network` is how a recipe states what its application is reviewed to reach.
Absent means the recipe says nothing and the platform's own posture applies, which
is every recipe written before this existed. `none` is a reviewed claim that the
application reaches nothing at all. `allowlist` is a reviewed claim naming exactly
what it reaches.

The two words carry different weight and the schema has to keep them apart: an
empty `allowlist` would read as "reviewed and reaches nothing" without anyone
having said so, and `none` beside a host list is a contradiction rather than a
preference.
"""

import json
from pathlib import Path

from jsonschema import Draft202012Validator


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = json.loads((ROOT / "schema/droplive.recipe.v1.schema.json").read_text())
VALIDATOR = Draft202012Validator(SCHEMA)

ROOT_DEFAULTS = {
    "description": "A fixture recipe used only by this test",
    "repository": "https://github.com/example/project",
}


def recipe(**run):
    return {**ROOT_DEFAULTS, "version": 1, "kind": "app", "run": {"port": 8080, **run}}


def valid(document):
    errors = sorted(VALIDATOR.iter_errors(document), key=str)
    assert not errors, errors[0].message


def invalid(document):
    assert sorted(VALIDATOR.iter_errors(document), key=str), "expected a schema error"


# Every recipe written before this key existed.
valid(recipe())

valid(recipe(network="none"))
valid(recipe(network="allowlist", expected_hosts=["api.github.com"]))
valid(recipe(network="allowlist", expected_hosts=["*.githubusercontent.com"]))

# Reviewed to reach nothing, beside a list of things to reach.
invalid(recipe(network="none", expected_hosts=["api.github.com"]))

# An allowlist has to list something. Otherwise it is `none` written in a way
# that does not read like a claim about the application.
invalid(recipe(network="allowlist"))
invalid(recipe(network="allowlist", expected_hosts=[]))

# Hosts without the word are hosts nobody reviewed as a boundary.
invalid(recipe(expected_hosts=["api.github.com"]))

# `observed` belongs to the MCP block, where it means the platform watches. An
# application saying it would be claiming a posture it cannot choose.
invalid(recipe(network="observed"))

# The pattern grammar is the compiler's: exact names, or one leading label
# wildcard. Anything the matcher would have to interpret is refused here.
invalid(recipe(network="allowlist", expected_hosts=["*"]))
invalid(recipe(network="allowlist", expected_hosts=["*.com.*"]))
invalid(recipe(network="allowlist", expected_hosts=["https://api.github.com"]))
invalid(recipe(network="allowlist", expected_hosts=["api.github.com/path"]))
invalid(recipe(network="allowlist", expected_hosts=["API.GITHUB.COM"]))
invalid(recipe(network="allowlist", expected_hosts=["api.github.com", "api.github.com"]))

# The MCP block is untouched: its own vocabulary still validates.
valid({
    **ROOT_DEFAULTS,
    "version": 1,
    "kind": "mcp",
    "mcp": {
        "transport": "stdio",
        "command": ["server"],
        "network": "none",
        "tools": {"smoke": {"name": "read_status", "arguments": {}}},
    },
})

print("network schema ok")
