from __future__ import annotations

from sqlalchemy.orm import Session

from app.models import SiteSetting


class SiteSettingsRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_first(self) -> SiteSetting | None:
        return self.db.query(SiteSetting).order_by(SiteSetting.id.asc()).first()

    def create(self, **kwargs) -> SiteSetting:
        row = SiteSetting(**kwargs)
        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row

    def update(self, row: SiteSetting, **kwargs) -> SiteSetting:
        for key, value in kwargs.items():
            setattr(row, key, value)
        self.db.commit()
        self.db.refresh(row)
        return row
