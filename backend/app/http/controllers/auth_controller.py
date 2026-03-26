from __future__ import annotations

from fastapi import status
from sqlalchemy.orm import Session

from app.core.responses.api_response import ApiResponse
from app.http.schemas.auth import LoginRequest
from app.services.auth_service import AuthService


class AuthController:
    @staticmethod
    async def login(payload: LoginRequest, db: Session):
        service = AuthService(db)
        result = await service.login(email=payload.email, password=payload.password)

        if result is None:
            return ApiResponse.error(
                message="Invalid credentials",
                errors={"email": ["Email or password is incorrect."]},
                status_code=status.HTTP_401_UNAUTHORIZED,
            )

        if result.get("error") == "inactive_user":
            return ApiResponse.error(
                message="User account is inactive",
                errors={"user": ["This account is inactive."]},
                status_code=status.HTTP_403_FORBIDDEN,
            )

        return ApiResponse.success(
            message="Login successful",
            data=result,
            status_code=status.HTTP_200_OK,
        )
