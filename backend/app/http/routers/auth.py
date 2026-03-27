from fastapi import APIRouter, Depends

from app.auth import auth_router, register_router, users_router
from app.auth.router import current_active_user
from app.auth.schemas import CurrentUserOut
from app.models import User

router = APIRouter()


@router.get(
    "/auth/me",
    response_model=CurrentUserOut,
    tags=["auth"],
    summary="Current user",
    description=(
        "Returns the active user for the JWT in `Authorization: Bearer <token>`. "
        "Obtain a token from `POST /auth/jwt/login` or `POST /api/v1/auth/login`. "
        "Use this endpoint to verify a token and load profile data."
    ),
)
async def read_current_user(user: User = Depends(current_active_user)) -> CurrentUserOut:
    return CurrentUserOut.model_validate(user)


@router.get(
    "/api/v1/auth/me",
    response_model=CurrentUserOut,
    tags=["Auth"],
    summary="Current user (v1)",
    description="Same as `/auth/me`, under `/api/v1` for clients using the v1 prefix.",
)
async def read_current_user_v1(user: User = Depends(current_active_user)) -> CurrentUserOut:
    return CurrentUserOut.model_validate(user)


router.include_router(auth_router, prefix="/auth/jwt", tags=["auth"])
router.include_router(register_router, prefix="/auth", tags=["auth"])
router.include_router(users_router, prefix="/users", tags=["users"])

