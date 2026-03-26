from __future__ import annotations

from fastapi import Depends, HTTPException, status

from app.auth import current_active_user
from app.models import User
from app.permissions.role_permissions import ROLE_PERMISSIONS


def require_permissions(*required_permissions: str):
    async def _checker(user: User = Depends(current_active_user)) -> User:
        granted = ROLE_PERMISSIONS.get(user.role, set())
        missing = [perm for perm in required_permissions if perm not in granted]
        if missing:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing permission(s): {', '.join(missing)}",
            )
        return user

    return _checker

