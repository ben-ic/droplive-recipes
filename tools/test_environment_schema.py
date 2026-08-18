#!/usr/bin/env python3
"""Check the public environment ownership schema."""

import json
from pathlib import Path

from jsonschema import Draft202012Validator


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = json.loads((ROOT / "schema/droplive.recipe.v1.schema.json").read_text())
VALIDATOR = Draft202012Validator(SCHEMA)


def recipe(variable):
    return {
        "version": 1,
        "kind": "app",
        "environment": {"TEST_VALUE": variable},
    }


def valid(variable):
    errors = list(VALIDATOR.iter_errors(recipe(variable)))
    assert not errors, [error.message for error in errors]


def invalid(variable):
    assert list(VALIDATOR.iter_errors(recipe(variable)))


valid({"owner": "droplive"})
valid({"owner": "user"})
valid({"owner": "droplive", "format": "hex", "length": 96})
valid({"owner": "droplive", "format": "url-safe", "length": 32})
valid({"owner": "droplive", "format": "alphanumeric", "length": 32})
valid({
    "owner": "droplive",
    "format": "password",
    "length": 24,
    "pattern": "^[A-Za-z0-9!_-]+$",
})
valid({"owner": "droplive", "format": "base64", "length": 44})
valid({"owner": "droplive", "format": "laravel-base64"})
valid({
    "owner": "droplive",
    "format": "password",
    "login": {"username": "admin"},
})

invalid({"owner": "recipe"})
invalid({"owner": "optional"})
invalid({"owner": "user", "format": "hex"})
invalid({"owner": "user", "length": 32})
invalid({"owner": "user", "pattern": "^.+$"})
invalid({"owner": "user", "login": {"username": "admin"}})
invalid({"owner": "droplive", "format": "unknown"})
invalid({"owner": "droplive", "length": 7})
invalid({"owner": "droplive", "length": 257})
invalid({"owner": "droplive", "format": "hex", "length": 31})
invalid({"owner": "droplive", "format": "base64", "length": 42})
invalid({"owner": "droplive", "format": "laravel-base64", "length": 44})
invalid({"owner": "droplive", "format": "laravel-base64", "pattern": "^.+$"})
invalid({"owner": "droplive", "pattern": "[A-Z]+"})

print("environment schema cases passed")
