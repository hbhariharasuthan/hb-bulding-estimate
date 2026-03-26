from fastapi import APIRouter, Depends

from app.permissions import require_permissions

router = APIRouter(prefix="/plans", tags=["plans"])

@router.get("")
async def list_plans(_=Depends(require_permissions("plans:read"))):
    return {"message": "Plans list placeholder"}


@router.post("")
async def create_plan(_=Depends(require_permissions("plans:write"))):
    return {"message": "Plan create placeholder"}

