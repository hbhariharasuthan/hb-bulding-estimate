from __future__ import annotations

from pydantic import BaseModel, Field


class MasterItem(BaseModel):
    id: int
    name: str
    is_active: bool


class MasterCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    is_active: bool = True


class MasterUpdateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    is_active: bool = True


class MastersResponse(BaseModel):
    materials: list[MasterItem]
    properties: list[MasterItem]
    units: list[MasterItem]


class MaterialStandardCreateRequest(BaseModel):
    material_id: int = Field(gt=0)
    property_id: int = Field(gt=0)
    unit_id: int = Field(gt=0)
    value: float | None = None
    default: bool = True
    is_active: bool = True


class MaterialStandardUpdateRequest(BaseModel):
    unit_id: int | None = Field(default=None, gt=0)
    value: float | None = None
    default: bool | None = None
    is_active: bool | None = None


class MaterialStandardItem(BaseModel):
    standard_id: int
    material_id: int
    material_name: str
    property_id: int
    property_name: str
    value: float | None
    unit_id: int
    unit_name: str
    default: bool
    is_active: bool
