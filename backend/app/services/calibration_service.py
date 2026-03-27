from __future__ import annotations

from app.repositories import PlanCalibrationRepository


class CalibrationService:
    def __init__(self, calibration_repo: PlanCalibrationRepository):
        self.calibration_repo = calibration_repo

    def convert_lengths(
        self,
        *,
        plan_id: int,
        pixel_lengths: list[float],
        output_unit: str | None = None,
    ) -> dict:
        calibration = self.calibration_repo.get_for_plan(plan_id=plan_id)
        if calibration is None:
            raise ValueError("No active calibration found for this plan.")
        if calibration.mm_per_pixel is None or calibration.mm_per_pixel <= 0:
            raise ValueError("Active calibration is missing mm_per_pixel.")

        unit = (output_unit or calibration.output_unit or "m").lower()
        mm_per_pixel = float(calibration.mm_per_pixel)

        results: list[float] = []
        for px in pixel_lengths:
            if px <= 0:
                raise ValueError("All pixel lengths must be > 0.")
            mm_value = px * mm_per_pixel
            if unit == "mm":
                results.append(mm_value)
            elif unit == "cm":
                results.append(mm_value / 10.0)
            elif unit == "m":
                results.append(mm_value / 1000.0)
            else:
                raise ValueError("output_unit must be one of: mm, cm, m")

        return {
            "plan_id": plan_id,
            "calibration_id": calibration.calibration_id,
            "output_unit": unit,
            "mm_per_pixel": mm_per_pixel,
            "values": results,
        }
