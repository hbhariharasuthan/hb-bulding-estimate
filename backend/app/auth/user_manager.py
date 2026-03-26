from __future__ import annotations

import os

from fastapi import Depends, Request
from fastapi_users import BaseUserManager, IntegerIDMixin

from app.auth.user_db import get_user_db
from app.models import User


class UserManager(IntegerIDMixin, BaseUserManager[User, int]):
    reset_password_token_secret = os.environ.get(
        "JWT_SECRET", "change-me-in-production"
    )
    verification_token_secret = os.environ.get("JWT_SECRET", "change-me-in-production")

    async def on_after_register(self, user: User, request: Request | None = None):
        return None


async def get_user_manager(user_db=Depends(get_user_db)):
    yield UserManager(user_db)

