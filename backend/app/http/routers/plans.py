from fastapi import APIRouter, Depends, HTTPException, status

from app.config.scale_config import MANUAL_SCALE_OPTIONS
from app.core.utils.image_scaling import apply_manual_scale, compute_manual_scale_factor
from app.http.schemas.plan_scaling import (
    ApplyManualScaleRequest,
    ApplyManualScaleResponse,
    ManualScaleOptionItem,
    ManualScaleOptionsResponse,
)
from app.permissions import require_permissions

router = APIRouter(prefix="/plans", tags=["plans"])

@router.get("")
async def list_plans(_=Depends(require_permissions("plans:read"))):
    return {"message": "Plans list placeholder"}


@router.post("")
async def create_plan(_=Depends(require_permissions("plans:write"))):
    return {"message": "Plan create placeholder"}


@router.get(
    "/manual-scale-options",
    response_model=ManualScaleOptionsResponse,
    summary="Manual scale options for image/PDF",
)
async def get_manual_scale_options(_=Depends(require_permissions("plans:read"))):
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


@router.post(
    "/apply-manual-scale",
    response_model=ApplyManualScaleResponse,
    summary="Apply manual scale to pixel length",
)
async def post_apply_manual_scale(
    payload: ApplyManualScaleRequest,
    _=Depends(require_permissions("plans:write")),
):
    try:
        real_length = apply_manual_scale(
            pixel_length=payload.pixel_length,
            scale_key=payload.scale_key,
            dpi=payload.dpi,
            output_unit=payload.output_unit,
        )
        scale_factor = compute_manual_scale_factor(
            scale_key=payload.scale_key,
            dpi=payload.dpi,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc

    return ApplyManualScaleResponse(
        pixel_length=payload.pixel_length,
        scale_key=payload.scale_key,
        dpi=payload.dpi,
        output_unit=payload.output_unit.lower(),
        real_length=real_length,
        scale_factor_mm_per_pixel=scale_factor,
    )

