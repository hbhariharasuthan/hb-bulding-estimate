from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.orm import Session

from app.core.responses.api_response import ApiResponse
from app.db import get_db
from app.http.schemas.site_settings import (
    SiteSettingsErrorResponse,
    SiteSettingsOut,
    SiteSettingsSuccessResponse,
)
from app.services.site_settings_service import SiteSettingsService

router = APIRouter(prefix="/api/v1/site-settings", tags=["Site Settings"])


@router.get(
    "",
    summary="Get current site settings",
    response_model=SiteSettingsSuccessResponse,
)
def get_site_settings(db: Session = Depends(get_db)):
    service = SiteSettingsService(db)
    row = service.get()
    data = (
        SiteSettingsOut.model_validate(row, from_attributes=True).model_dump(mode="json")
        if row
        else None
    )
    return ApiResponse.success(message="Site settings fetched.", data={"site_settings": data})


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    summary="Create site settings",
    response_model=SiteSettingsSuccessResponse,
    responses={409: {"model": SiteSettingsErrorResponse}},
)
async def create_site_settings(
    site_name: str | None = Form(default=None),
    site_admin_email: str | None = Form(default=None),
    site_admin_contact_number: str | None = Form(default=None),
    razorpay_key: str | None = Form(default=None),
    razorpay_secret: str | None = Form(default=None),
    remove_site_logo: bool = Form(default=False),
    remove_login_background: bool = Form(default=False),
    site_logo: UploadFile | None = File(default=None),
    login_background: UploadFile | None = File(default=None),
    db: Session = Depends(get_db),
):
    service = SiteSettingsService(db)
    existing = service.get()
    if existing is not None:
        return ApiResponse.error(
            message="Site settings already exists. Use PUT endpoint.",
            status_code=status.HTTP_409_CONFLICT,
        )
    row = await service.create(
        site_name=site_name,
        site_admin_email=site_admin_email,
        site_admin_contact_number=site_admin_contact_number,
        razorpay_key=razorpay_key,
        razorpay_secret=razorpay_secret,
        site_logo=site_logo,
        login_background=login_background,
        remove_site_logo=remove_site_logo,
        remove_login_background=remove_login_background,
    )
    data = SiteSettingsOut.model_validate(row, from_attributes=True).model_dump(mode="json")
    return ApiResponse.success(message="Site settings created.", data={"site_settings": data}, status_code=201)


@router.put(
    "/{setting_id}",
    summary="Update site settings",
    response_model=SiteSettingsSuccessResponse,
    responses={404: {"model": SiteSettingsErrorResponse}},
)
async def update_site_settings(
    setting_id: int,
    site_name: str | None = Form(default=None),
    site_admin_email: str | None = Form(default=None),
    site_admin_contact_number: str | None = Form(default=None),
    razorpay_key: str | None = Form(default=None),
    razorpay_secret: str | None = Form(default=None),
    remove_site_logo: bool = Form(default=False),
    remove_login_background: bool = Form(default=False),
    site_logo: UploadFile | None = File(default=None),
    login_background: UploadFile | None = File(default=None),
    db: Session = Depends(get_db),
):
    service = SiteSettingsService(db)
    row = service.get()
    if row is None or row.id != setting_id:
        return ApiResponse.error(message="Site settings not found.", status_code=status.HTTP_404_NOT_FOUND)
    updated = await service.update(
        row=row,
        site_name=site_name,
        site_admin_email=site_admin_email,
        site_admin_contact_number=site_admin_contact_number,
        razorpay_key=razorpay_key,
        razorpay_secret=razorpay_secret,
        site_logo=site_logo,
        login_background=login_background,
        remove_site_logo=remove_site_logo,
        remove_login_background=remove_login_background,
    )
    data = SiteSettingsOut.model_validate(updated, from_attributes=True).model_dump(mode="json")
    return ApiResponse.success(message="Site settings updated.", data={"site_settings": data})
