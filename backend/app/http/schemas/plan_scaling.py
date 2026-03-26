from __future__ import annotations

from pydantic import BaseModel, Field


class ManualScaleOptionItem(BaseModel):
    key: str
    label: str
    numerator: int
    denominator: int


class ManualScaleOptionsResponse(BaseModel):
    options: list[ManualScaleOptionItem]


class ApplyManualScaleRequest(BaseModel):
    pixel_length: float = Field(gt=0)
    scale_key: str
    dpi: int = Field(default=96, gt=0)
    output_unit: str = Field(default="m")


class ApplyManualScaleResponse(BaseModel):
    pixel_length: float
    scale_key: str
    dpi: int
    output_unit: str
    real_length: float
    scale_factor_mm_per_pixel: float
