#!/usr/bin/env python3
"""Check the narrow recipe-owned BYOK opt-in."""

import json
from pathlib import Path

from jsonschema import Draft202012Validator
from lint_recipes import capability_errors


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = json.loads((ROOT / "schema/droplive.recipe.v1.schema.json").read_text())
CAPABILITIES = __import__("yaml").safe_load(
    (ROOT / "capabilities/v1.yaml").read_text()
)["capabilities"]
VALIDATOR = Draft202012Validator(SCHEMA)


def recipe(capability, bindings, byok=True, access="server"):
    return {
        "version": 1,
        "kind": "app",
        "description": "A fixture recipe used only by this test",
        "repository": "https://github.com/example/project",
        "emulators": {
            "model": {
                "capability": capability,
                "access": access,
                "byok": byok,
                "bindings": bindings,
            }
        },
    }


allowed = recipe(
    "llm.openai_chat.v1",
    {"OPENROUTER_API_KEY": "non_authenticating_api_key"},
)
assert not list(VALIDATOR.iter_errors(allowed))
assert capability_errors(allowed, CAPABILITIES) == []

missing_key = recipe(
    "llm.openai_chat.v1",
    {"OPENAI_BASE_URL": "api_base_url"},
)
assert capability_errors(missing_key, CAPABILITIES) == [
    "emulator model BYOK must bind non_authenticating_api_key"
]

unsupported = recipe(
    "computer.daytona.v1",
    {"DAYTONA_API_KEY": "api_key"},
    access="server-and-browser",
)
assert capability_errors(unsupported, CAPABILITIES) == [
    "emulator model enables BYOK for unsupported capability computer.daytona.v1"
]

not_opted_in = recipe(
    "llm.openai_chat.v1",
    {"OPENAI_BASE_URL": "api_base_url"},
    byok=False,
)
assert capability_errors(not_opted_in, CAPABILITIES) == []

print("BYOK schema cases passed")
