from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class SiteSettingsOut(BaseModel):
    id: int
    site_name: str | None
    site_admin_email: str | None
    site_logo: str | None
    login_background: str | None
    site_admin_contact_number: str | None
    razorpay_key: str | None
    razorpay_secret: str | None
    created_at: datetime
    updated_at: datetime


class SiteSettingsInput(BaseModel):
    site_name: str | None = None
    site_admin_email: str | None = None
    site_admin_contact_number: str | None = None
    razorpay_key: str | None = None
    razorpay_secret: str | None = None


class SiteSettingsData(BaseModel):
    site_settings: SiteSettingsOut | None


class SiteSettingsSuccessResponse(BaseModel):
    success: bool = True
    message: str
    data: SiteSettingsData
    errors: dict | None = None
    meta: dict


class SiteSettingsErrorResponse(BaseModel):
    success: bool = False
    message: str
    data: dict | None = None
    errors: dict | None = None
    meta: dict
