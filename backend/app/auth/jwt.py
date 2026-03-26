from __future__ import annotations

import os

from fastapi_users.authentication import AuthenticationBackend, BearerTransport, JWTStrategy


bearer_transport = BearerTransport(tokenUrl="auth/jwt/login")


def get_jwt_strategy() -> JWTStrategy:
    return JWTStrategy(
        secret=os.environ.get("JWT_SECRET", "change-me-in-production"),
        lifetime_seconds=60 * 60 * 24,
    )


auth_backend = AuthenticationBackend(
    name="jwt",
    transport=bearer_transport,
    get_strategy=get_jwt_strategy,
)

