from __future__ import annotations

from pathlib import Path
from uuid import uuid4

from fastapi import UploadFile
from sqlalchemy.orm import Session

from app.models import SiteSetting
from app.repositories.site_settings_repository import SiteSettingsRepository


class SiteSettingsService:
    def __init__(self, db: Session):
        self.repo = SiteSettingsRepository(db)

    @staticmethod
    def _clean_optional(value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        return stripped if stripped else None

    @staticmethod
    async def _save_file(file: UploadFile | None, field_name: str) -> str | None:
        if file is None:
            return None
        ext = Path(file.filename or "").suffix.lower()
        uploads = (
            Path(__file__).resolve().parents[2]
            / "storage"
            / "app"
            / "public"
            / "site-settings"
        )
        uploads.mkdir(parents=True, exist_ok=True)
        filename = f"{field_name}_{uuid4().hex}{ext}"
        out_path = uploads / filename
        data = await file.read()
        out_path.write_bytes(data)
        return f"/storage/site-settings/{filename}"

    @staticmethod
    def _public_url_to_path(public_url: str | None) -> Path | None:
        if not public_url or not public_url.startswith("/storage/site-settings/"):
            return None
        filename = public_url.removeprefix("/storage/site-settings/").strip()
        if not filename:
            return None
        return (
            Path(__file__).resolve().parents[2]
            / "storage"
            / "app"
            / "public"
            / "site-settings"
            / filename
        )

    @classmethod
    def _remove_file_if_exists(cls, public_url: str | None) -> None:
        path = cls._public_url_to_path(public_url)
        if path is None:
            return
        path.unlink(missing_ok=True)

    def get(self) -> SiteSetting | None:
        return self.repo.get_first()

    async def create(
        self,
        site_name: str | None,
        site_admin_email: str | None,
        site_admin_contact_number: str | None,
        razorpay_key: str | None,
        razorpay_secret: str | None,
        site_logo: UploadFile | None,
        login_background: UploadFile | None,
        remove_site_logo: bool = False,
        remove_login_background: bool = False,
    ) -> SiteSetting:
        payload = {
            "site_name": self._clean_optional(site_name),
            "site_admin_email": self._clean_optional(site_admin_email),
            "site_admin_contact_number": self._clean_optional(site_admin_contact_number),
            "razorpay_key": self._clean_optional(razorpay_key),
            "razorpay_secret": self._clean_optional(razorpay_secret),
            "site_logo": None if remove_site_logo else await self._save_file(site_logo, "site_logo"),
            "login_background": None
            if remove_login_background
            else await self._save_file(login_background, "login_background"),
        }
        return self.repo.create(**payload)

    async def update(
        self,
        row: SiteSetting,
        site_name: str | None,
        site_admin_email: str | None,
        site_admin_contact_number: str | None,
        razorpay_key: str | None,
        razorpay_secret: str | None,
        site_logo: UploadFile | None,
        login_background: UploadFile | None,
        remove_site_logo: bool = False,
        remove_login_background: bool = False,
    ) -> SiteSetting:
        payload = {
            "site_name": self._clean_optional(site_name),
            "site_admin_email": self._clean_optional(site_admin_email),
            "site_admin_contact_number": self._clean_optional(site_admin_contact_number),
            "razorpay_key": self._clean_optional(razorpay_key),
            "razorpay_secret": self._clean_optional(razorpay_secret),
        }
        if remove_site_logo:
            self._remove_file_if_exists(row.site_logo)
            payload["site_logo"] = None
        else:
            saved_logo = await self._save_file(site_logo, "site_logo")
            if saved_logo is not None:
                self._remove_file_if_exists(row.site_logo)
                payload["site_logo"] = saved_logo

        if remove_login_background:
            self._remove_file_if_exists(row.login_background)
            payload["login_background"] = None
        else:
            saved_bg = await self._save_file(login_background, "login_background")
            if saved_bg is not None:
                self._remove_file_if_exists(row.login_background)
                payload["login_background"] = saved_bg
        return self.repo.update(row, **payload)
