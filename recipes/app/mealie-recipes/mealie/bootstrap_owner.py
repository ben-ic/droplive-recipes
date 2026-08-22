"""Replace Mealie's weak seed owner exactly once, before accepting traffic."""

from __future__ import annotations

import os
import re

from sqlalchemy import select

from mealie.core.config import get_app_settings
from mealie.core.security import hash_password
from mealie.core.security.providers.credentials_provider import CredentialsProvider
from mealie.db.db_setup import session_context
from mealie.db.models.users.users import User


EMAIL_PATTERN = re.compile(r"[^@\s]+@[^@\s]+\.[^@\s]+\Z")


def required_environment(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"{name} is required")
    return value


def main() -> None:
    settings = get_app_settings()
    email = required_environment("MEALIE_BOOTSTRAP_EMAIL").lower()
    password = required_environment("MEALIE_BOOTSTRAP_PASSWORD")

    if len(email) > 254 or not EMAIL_PATTERN.fullmatch(email):
        raise RuntimeError("MEALIE_BOOTSTRAP_EMAIL must be a valid email address")
    if email == settings._DEFAULT_EMAIL.strip().lower():
        raise RuntimeError("MEALIE_BOOTSTRAP_EMAIL must not use Mealie's demonstration address")
    if len(password) != 64 or not re.fullmatch(r"[A-Za-z0-9_-]{64}", password):
        raise RuntimeError("MEALIE_BOOTSTRAP_PASSWORD must be a 64-character URL-safe password")

    with session_context() as session:
        users = list(session.execute(select(User)).scalars())
        default_email = settings._DEFAULT_EMAIL.strip().lower()
        default_users = [user for user in users if (user.email or "").strip().lower() == default_email]

        if not default_users:
            print("DropLive owner bootstrap already complete; preserving existing users", flush=True)
            return

        if len(default_users) != 1 or len(users) != 1:
            raise RuntimeError("refusing to rotate a default-address owner in a non-empty multi-user database")

        owner = default_users[0]
        if not owner.admin:
            raise RuntimeError("refusing to rotate a non-admin default-address user")
        if not CredentialsProvider.verify_password(settings._DEFAULT_PASSWORD, owner.password or ""):
            print("Default-address owner already has a non-default password; preserving it", flush=True)
            return

        email_owner = session.execute(select(User).where(User.email == email)).scalars().one_or_none()
        if email_owner is not None and email_owner.id != owner.id:
            raise RuntimeError("requested owner email already belongs to another user")

        owner.email = email
        owner.username = "owner"
        owner.full_name = "Owner"
        owner.password = hash_password(password)
        owner.login_attemps = 0
        owner.locked_at = None
        session.commit()

    print("DropLive replaced Mealie's demonstration owner credentials", flush=True)


if __name__ == "__main__":
    main()
