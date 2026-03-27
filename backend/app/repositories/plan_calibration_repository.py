from __future__ import annotations

from sqlalchemy.orm import Session

from app.models import PlanCalibration


class PlanCalibrationRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_for_plan(self, plan_id: int) -> PlanCalibration | None:
        return (
            self.db.query(PlanCalibration)
            .filter(
                PlanCalibration.plan_id == plan_id,
                PlanCalibration.is_active.is_(True),
            )
            .first()
        )

    def upsert_for_plan(
        self,
        *,
        plan_id: int,
        page_number: int | None,
        pixel_length: float,
        real_length: float,
        unit: str,
        scale_factor: float,
        scale_key: str,
        dpi: int,
        mm_per_pixel: float,
        output_unit: str,
        x1: float | None,
        y1: float | None,
        x2: float | None,
        y2: float | None,
        updated_by: int | None,
    ) -> PlanCalibration:
        row = self.get_for_plan(plan_id)
        if row is None:
            row = PlanCalibration(plan_id=plan_id)

        row.page_number = page_number
        row.pixel_length = pixel_length
        row.real_length = real_length
        row.unit = unit
        row.scale_factor = scale_factor
        row.scale_key = scale_key
        row.dpi = dpi
        row.mm_per_pixel = mm_per_pixel
        row.output_unit = output_unit
        row.x1 = x1
        row.y1 = y1
        row.x2 = x2
        row.y2 = y2
        row.is_active = True
        row.updated_by = updated_by

        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row
