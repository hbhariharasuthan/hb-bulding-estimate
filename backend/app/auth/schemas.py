from __future__ import annotations

from fastapi_users import schemas
from pydantic import BaseModel, ConfigDict, EmailStr


class UserRead(schemas.BaseUser[int]):
    name: str
    role: str


class UserCreate(schemas.BaseUserCreate):
    name: str
    role: str = "member"


class UserUpdate(schemas.BaseUserUpdate):
    name: str | None = None
    role: str | None = None


class CurrentUserOut(BaseModel):
    """Public profile for the authenticated user (no password hash)."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    name: str
    role: str
    is_active: bool
    is_verified: bool

