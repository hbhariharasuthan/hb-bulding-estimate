from __future__ import annotations

from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.auth.jwt import get_jwt_strategy
from app.permissions.role_permissions import ROLE_PERMISSIONS
from app.repositories.user_repository import UserRepository


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    def __init__(self, db: Session):
        self.user_repository = UserRepository(db)

    async def login(self, email: str, password: str) -> dict | None:
        user = self.user_repository.get_by_email(email)
        if user is None:
            return None

        if not user.is_active:
            return {"error": "inactive_user"}

        if not pwd_context.verify(password, user.hashed_password):
            return None

        strategy = get_jwt_strategy()
        token = await strategy.write_token(user)
        permissions = sorted(ROLE_PERMISSIONS.get(user.role, set()))

        return {
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "role": user.role,
                "permissions": permissions,
            },
        }
