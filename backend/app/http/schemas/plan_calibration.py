from __future__ import annotations

from pydantic import BaseModel, Field


class SavePlanCalibrationRequest(BaseModel):
    page_number: int | None = None
    scale_key: str
    dpi: int = Field(gt=0)
    pixel_length: float = Field(gt=0)
    output_unit: str = Field(default="m")
    x1: float | None = None
    y1: float | None = None
    x2: float | None = None
    y2: float | None = None


class PlanCalibrationPayload(BaseModel):
    calibration_id: int
    plan_id: int
    page_number: int | None = None
    scale_key: str | None = None
    dpi: int | None = None
    pixel_length: float | None = None
    real_length: float | None = None
    output_unit: str | None = None
    mm_per_pixel: float | None = None
    x1: float | None = None
    y1: float | None = None
    x2: float | None = None
    y2: float | None = None
    is_active: bool
    updated_by: int | None = None


class ConvertByCalibrationRequest(BaseModel):
    pixel_lengths: list[float] = Field(min_length=1)
    output_unit: str | None = Field(default=None)


class ConvertByCalibrationResponse(BaseModel):
    plan_id: int
    calibration_id: int
    output_unit: str
    mm_per_pixel: float
    values: list[float]
