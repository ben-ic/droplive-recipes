#!/usr/bin/env python3
"""Check the entrypoint declaration rules.

Every case here is a mistake that reached `main` and was found by launching the
application instead of by validating it.
"""

import tempfile
from pathlib import Path

from lint_recipes import entrypoint_errors, is_public_origin_name


GOOD = '''#!/bin/sh
set -eu
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=none name=ADMIN_PASSWORD capability=owner-login username=admin
: "${ADMIN_PASSWORD:?DropLive must generate ADMIN_PASSWORD}"
exec "$@"
'''


def check(script, recipe=None, dockerfile=None):
    with tempfile.TemporaryDirectory() as directory:
        folder = Path(directory)
        (folder / "droplive.yaml").write_text("version: 1\nkind: app\n")
        if script is not None:
            (folder / "droplive-entrypoint.sh").write_text(script)
        if dockerfile is not None:
            (folder / "Dockerfile").write_text(dockerfile)
        return entrypoint_errors(folder / "droplive.yaml", recipe or {"version": 1, "kind": "app"})


def expect_clean(script, **kwargs):
    errors = check(script, **kwargs)
    assert not errors, errors


def expect(fragment, script, **kwargs):
    errors = check(script, **kwargs)
    assert any(fragment in error for error in errors), (fragment, errors)


# A correct entrypoint stays quiet.
expect_clean(GOOD)

# An annotation only counts when the same script also requires the value.
expect(
    "annotated but never required",
    GOOD.replace(': "${ADMIN_PASSWORD:?DropLive must generate ADMIN_PASSWORD}"\n', ""),
)

# A second capability= silently removes the sign-in card, so refuse it loudly.
expect(
    "silently removes the sign-in card",
    GOOD.replace(
        'exec "$@"',
        "# droplive: generate=hex96 ownership=app purpose=owner-bootstrap"
        " lifecycle=stable rotation=none name=OTHER_SECRET capability=owner-login\n"
        ': "${OTHER_SECRET:?x}"\nexec "$@"',
    ),
)

# A line that looks like an annotation but does not parse reads as if it works.
expect("do not match the annotation grammar", GOOD.replace("purpose=owner-bootstrap", "purpose=api-key-pepper"))

# The name has to read as a credential or nothing treats it as one.
expect("as a whole word", GOOD.replace("ADMIN_PASSWORD", "ADMIN_THING"))

# capability= must agree with purpose= or the card never appears.
expect("they must agree", GOOD.replace("capability=owner-login", "capability=admin-login"))

# An exact-length check rejects a longer, perfectly usable value.
expect(
    "rejects a longer, usable value",
    GOOD.replace(
        'exec "$@"',
        'v_length=${#ADMIN_PASSWORD}\nif test "$v_length" -ne 16; then exit 64; fi\nexec "$@"',
    ),
)
expect_clean(
    GOOD.replace(
        'exec "$@"',
        'v_length=${#ADMIN_PASSWORD}\nif test "$v_length" -lt 16; then exit 64; fi\nexec "$@"',
    )
)

# An annotation in a Dockerfile is never read.
expect(
    "only read in the copied entrypoint script",
    GOOD,
    dockerfile="# droplive: generate=hex96 ownership=app purpose=owner-bootstrap"
    " lifecycle=stable rotation=none name=OTHER_PASSWORD\nFROM scratch\n",
)

# Declaring the session origin as a generated value hands the app a secret.
expect(
    "origin-shaped name",
    GOOD,
    recipe={
        "version": 1,
        "kind": "app",
        "environment": {"NEXTAUTH_URL": {"owner": "droplive"}},
    },
)

# A connection URL is not an origin, so a companion still owns it.
assert is_public_origin_name("NEXTAUTH_URL")
assert is_public_origin_name("WAKAPI_PUBLIC_URL")
assert is_public_origin_name("APP_BASE_URL")
assert not is_public_origin_name("DATABASE_URL")
assert not is_public_origin_name("REDIS_URL")
assert not is_public_origin_name("AUTH_SECRET")

print("entrypoint rule cases passed")
