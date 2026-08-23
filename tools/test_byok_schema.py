#!/usr/bin/env python3
"""Check the narrow recipe-owned BYOK opt-in.

A real-provider substitution replaces a whole binding group or none of it. The
credential alone is not a smaller substitution but a wrong one: the application
would receive the visitor's real key while its base URL still named the
emulator, so the key would go to a fixture that ignores it and the demo would
present generated replies as the provider's.
"""

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


# The endpoint and the credential together: the only complete group.
allowed = recipe(
    "llm.openai_chat.v1",
    {
        "OPENROUTER_BASE_URL": "api_base_url",
        "OPENROUTER_API_KEY": "non_authenticating_api_key",
    },
)
assert not list(VALIDATOR.iter_errors(allowed))
assert capability_errors(allowed, CAPABILITIES) == []

# Pinning a model does not change where the request goes, so the selector stays
# optional. Requiring it would turn a rule about atomicity into one about
# completeness.
with_selector = recipe(
    "llm.openai_chat.v1",
    {
        "OPENROUTER_BASE_URL": "api_base_url",
        "OPENROUTER_MODEL": "model_name",
        "OPENROUTER_API_KEY": "non_authenticating_api_key",
    },
)
assert capability_errors(with_selector, CAPABILITIES) == []

# The defect, refused. This exact shape used to be accepted.
credential_only = recipe(
    "llm.openai_chat.v1",
    {"OPENROUTER_API_KEY": "non_authenticating_api_key"},
)
assert capability_errors(credential_only, CAPABILITIES) == [
    "emulator model enables BYOK and must bind api_base_url: "
    "the provider endpoint and credential are replaced together"
]

# And its mirror: a real endpoint reached with the fixture's non-authenticating
# placeholder fails at the first call, inside the application's error handling.
endpoint_only = recipe(
    "llm.openai_chat.v1",
    {"OPENROUTER_BASE_URL": "api_base_url"},
)
assert capability_errors(endpoint_only, CAPABILITIES) == [
    "emulator model enables BYOK and must bind non_authenticating_api_key: "
    "the provider endpoint and credential are replaced together"
]

# The computer is never BYOK. It runs inside the session microVM, and handing a
# visitor's real credential to untrusted code is what that boundary prevents.
unsupported = recipe(
    "computer.daytona.v1",
    {"DAYTONA_API_KEY": "api_key"},
    access="server-and-browser",
)
assert capability_errors(unsupported, CAPABILITIES) == [
    "emulator model enables BYOK for unsupported capability computer.daytona.v1"
]

# A recipe that has not opted in is bound entirely to the emulator, so a partial
# binding is only a partial binding and nothing is being substituted.
not_opted_in = recipe(
    "llm.openai_chat.v1",
    {"OPENAI_BASE_URL": "api_base_url"},
    byok=False,
)
assert capability_errors(not_opted_in, CAPABILITIES) == []

print("BYOK schema cases passed")
