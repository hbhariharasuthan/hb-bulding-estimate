from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class LoginUserData(BaseModel):
    id: int
    name: str
    email: EmailStr
    role: str
    permissions: list[str]


class LoginData(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: LoginUserData


class ApiSuccessLoginResponse(BaseModel):
    success: bool = True
    message: str
    data: LoginData
    errors: dict | None = None
    meta: dict


class ApiErrorResponse(BaseModel):
    success: bool = False
    message: str
    data: dict | None = None
    errors: dict | list | None = None
    meta: dict
