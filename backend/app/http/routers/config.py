from __future__ import annotations

from fastapi import APIRouter

from app.config.scale_config import MANUAL_SCALE_OPTIONS
from app.http.schemas.plan_scaling import ManualScaleOptionItem, ManualScaleOptionsResponse

router = APIRouter(prefix="/api/v1/config", tags=["Config"])


@router.get(
    "/manual-scale-options",
    response_model=ManualScaleOptionsResponse,
    summary="List manual scale options",
    description="Returns configured manual scale options for dropdowns.",
)
async def list_manual_scale_options() -> ManualScaleOptionsResponse:
    options = [
        ManualScaleOptionItem(
            key=key,
            label=str(item["label"]),
            numerator=int(item["numerator"]),
            denominator=int(item["denominator"]),
        )
        for key, item in MANUAL_SCALE_OPTIONS.items()
    ]
    return ManualScaleOptionsResponse(options=options)
