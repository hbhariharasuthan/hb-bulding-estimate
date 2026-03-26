from fastapi import APIRouter

from app.auth import auth_router, register_router, users_router

router = APIRouter()
router.include_router(auth_router, prefix="/auth/jwt", tags=["auth"])
router.include_router(register_router, prefix="/auth", tags=["auth"])
router.include_router(users_router, prefix="/users", tags=["users"])

