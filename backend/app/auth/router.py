from __future__ import annotations

from fastapi_users import FastAPIUsers

from app.auth.jwt import auth_backend
from app.auth.schemas import UserCreate, UserRead, UserUpdate
from app.auth.user_manager import get_user_manager
from app.models import User


fastapi_users = FastAPIUsers[User, int](get_user_manager, [auth_backend])

current_active_user = fastapi_users.current_user(active=True)

auth_router = fastapi_users.get_auth_router(auth_backend)
register_router = fastapi_users.get_register_router(UserRead, UserCreate)
users_router = fastapi_users.get_users_router(UserRead, UserUpdate)

