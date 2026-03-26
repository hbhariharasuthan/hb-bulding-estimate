from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.http.controllers.auth_controller import AuthController
from app.http.schemas.auth import ApiErrorResponse, ApiSuccessLoginResponse, LoginRequest

router = APIRouter(prefix="/api/v1/auth", tags=["Auth MVC"])


@router.post(
    "/login",
    summary="Login with email and password",
    description="Laravel-style custom login endpoint returning JWT token, role, and permissions.",
    response_model=ApiSuccessLoginResponse,
    responses={
        401: {"model": ApiErrorResponse, "description": "Invalid credentials"},
        403: {"model": ApiErrorResponse, "description": "Inactive user"},
    },
)
async def login(payload: LoginRequest, db: Session = Depends(get_db)):
    return await AuthController.login(payload=payload, db=db)
