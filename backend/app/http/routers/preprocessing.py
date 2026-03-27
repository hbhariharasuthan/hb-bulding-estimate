from __future__ import annotations

import json
from pathlib import Path

from fastapi import APIRouter, Body, Depends, File, Form, HTTPException, UploadFile, status
from PIL import Image
from sqlalchemy.orm import Session

from app.core.utils.image_scaling import apply_manual_scale, compute_manual_scale_factor
from app.core.responses.api_response import ApiResponse
from app.db import get_db
from app.http.schemas.plan_calibration import ConvertByCalibrationRequest, SavePlanCalibrationRequest
from app.models import Element, User
from app.permissions import require_permissions
from app.repositories import PlanCalibrationRepository, PlanRepository
from app.services import CalibrationService, DetectionService, PreprocessingService

router = APIRouter(prefix="/api/v1/plans", tags=["Plans Preprocessing"])

_storage_root = Path(__file__).resolve().parents[3] / "storage" / "app" / "public"


def _as_plan_payload(row) -> dict:
    return {
        "plan_id": row.plan_id,
        "plan_name": row.plan_name,
        "file_path": row.file_path,
        "file_type": row.file_type,
        "file_size": row.file_size,
        "status": row.status,
        "processing_progress": row.processing_progress,
        "total_pages": row.total_pages,
        "current_page": row.current_page,
        "dpi": row.dpi,
        "detected_units": row.detected_units,
        "error_message": row.error_message,
    }


def _public_to_local_path(public_path: str) -> Path:
    normalized = (public_path or "").strip()
    if normalized.startswith("/storage/"):
        return _storage_root / normalized.removeprefix("/storage/").lstrip("/")
    return _storage_root / normalized.lstrip("/")


def _image_info(public_path: str) -> dict:
    path = _public_to_local_path(public_path)
    out: dict[str, int | None] = {"width": None, "height": None, "file_size": None}
    if not path.exists():
        return out
    out["file_size"] = path.stat().st_size
    try:
        with Image.open(path) as image:
            out["width"], out["height"] = image.size
    except Exception:
        pass
    return out


def _read_page_meta(plan_id: int) -> list[dict]:
    meta_dir = _storage_root / "processed" / str(plan_id) / "meta"
    if not meta_dir.exists():
        return []

    pages: list[dict] = []
    for meta_path in sorted(meta_dir.glob("page_*.json")):
        try:
            payload = json.loads(meta_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        source_image = str(payload.get("source_image") or "")
        processed_image = str(payload.get("processed_image") or "")
        processed_soft_image = str(payload.get("processed_soft_image") or "")
        processed_binary_image = str(payload.get("processed_binary_image") or "")
        pages.append(
            {
                "page_number": int(payload.get("page_number") or 0),
                "source_image": source_image,
                "processed_image": processed_image,
                "processed_soft_image": processed_soft_image,
                "processed_binary_image": processed_binary_image,
                "detected_unit": payload.get("detected_unit") or "",
                "explanation": payload.get("explanation") or "",
                "source_info": _image_info(source_image),
                "processed_info": _image_info(processed_image),
                "processed_soft_info": _image_info(processed_soft_image),
                "processed_binary_info": _image_info(processed_binary_image),
            }
        )
    return pages


def _as_calibration_payload(row) -> dict:
    return {
        "calibration_id": row.calibration_id,
        "plan_id": row.plan_id,
        "page_number": row.page_number,
        "scale_key": row.scale_key,
        "dpi": row.dpi,
        "pixel_length": row.pixel_length,
        "real_length": row.real_length,
        "output_unit": row.output_unit,
        "mm_per_pixel": row.mm_per_pixel,
        "x1": row.x1,
        "y1": row.y1,
        "x2": row.x2,
        "y2": row.y2,
        "is_active": row.is_active,
        "updated_by": row.updated_by,
    }


@router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_plan(
    plan_name: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:write")),
):
    suffix = Path(file.filename or "").suffix.lower()
    if not suffix:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="File extension is required.")

    target_dir = _storage_root / "uploads" / "plans" / str(user.user_id) / "originals"
    target_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{plan_name.strip().replace(' ', '_')}{suffix}"
    target_path = target_dir / filename

    content = await file.read()
    target_path.write_bytes(content)

    repo = PlanRepository(db)
    row = repo.create(
        user_id=user.user_id,
        plan_name=plan_name.strip(),
        file_path=f"/storage/{target_path.relative_to(_storage_root).as_posix()}",
        file_type=suffix.removeprefix("."),
        file_size=len(content),
    )

    return ApiResponse.success(
        message="Plan uploaded.",
        data={"plan": _as_plan_payload(row)},
        status_code=status.HTTP_201_CREATED,
    )


@router.get("")
def list_plans(
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:read")),
):
    repo = PlanRepository(db)
    rows = repo.list_for_user(user_id=user.user_id, is_admin=user.role == "admin")
    return ApiResponse.success(
        message="Plans fetched.",
        data={"plans": [_as_plan_payload(r) for r in rows]},
    )


@router.get("/{plan_id}")
def get_plan(
    plan_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:read")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)
    return ApiResponse.success(message="Plan fetched.", data={"plan": _as_plan_payload(row)})


@router.post("/{plan_id}/preprocess")
def preprocess_plan(
    plan_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:write")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)

    service = PreprocessingService(db)
    try:
        updated = service.process_plan(row)
    except NotImplementedError as exc:
        return ApiResponse.error(message=str(exc), status_code=status.HTTP_400_BAD_REQUEST)
    except FileNotFoundError as exc:
        return ApiResponse.error(message=str(exc), status_code=status.HTTP_404_NOT_FOUND)
    except Exception as exc:
        return ApiResponse.error(message=f"Preprocessing failed: {exc}", status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return ApiResponse.success(message="Preprocessing completed.", data={"plan": _as_plan_payload(updated)})


@router.get("/{plan_id}/pages")
def plan_pages(
    plan_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:read")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)

    pages = _read_page_meta(plan_id=plan_id)
    return ApiResponse.success(message="Plan pages fetched.", data={"pages": pages})


@router.get("/{plan_id}/calibration")
def get_plan_calibration(
    plan_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:read")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)

    calibration_repo = PlanCalibrationRepository(db)
    calibration = calibration_repo.get_for_plan(plan_id=plan_id)
    if calibration is None:
        return ApiResponse.success(message="No active calibration.", data={"calibration": None})
    return ApiResponse.success(
        message="Calibration fetched.",
        data={"calibration": _as_calibration_payload(calibration)},
    )


@router.post("/{plan_id}/calibration")
def save_plan_calibration(
    plan_id: int,
    payload: SavePlanCalibrationRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:write")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)

    try:
        real_length = apply_manual_scale(
            pixel_length=payload.pixel_length,
            scale_key=payload.scale_key,
            dpi=payload.dpi,
            output_unit=payload.output_unit,
        )
        mm_per_pixel = compute_manual_scale_factor(
            scale_key=payload.scale_key,
            dpi=payload.dpi,
        )
    except ValueError as exc:
        return ApiResponse.error(message=str(exc), status_code=status.HTTP_400_BAD_REQUEST)

    calibration_repo = PlanCalibrationRepository(db)
    saved = calibration_repo.upsert_for_plan(
        plan_id=plan_id,
        page_number=payload.page_number,
        pixel_length=payload.pixel_length,
        real_length=real_length,
        unit=payload.output_unit.lower(),
        scale_factor=mm_per_pixel,
        scale_key=payload.scale_key,
        dpi=payload.dpi,
        mm_per_pixel=mm_per_pixel,
        output_unit=payload.output_unit.lower(),
        x1=payload.x1,
        y1=payload.y1,
        x2=payload.x2,
        y2=payload.y2,
        updated_by=user.user_id,
    )
    return ApiResponse.success(
        message="Calibration saved.",
        data={"calibration": _as_calibration_payload(saved)},
    )


@router.post("/{plan_id}/calibration/convert")
def convert_using_saved_calibration(
    plan_id: int,
    payload: ConvertByCalibrationRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:read")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)

    calibration_repo = PlanCalibrationRepository(db)
    service = CalibrationService(calibration_repo=calibration_repo)
    try:
        converted = service.convert_lengths(
            plan_id=plan_id,
            pixel_lengths=payload.pixel_lengths,
            output_unit=payload.output_unit,
        )
    except ValueError as exc:
        return ApiResponse.error(message=str(exc), status_code=status.HTTP_400_BAD_REQUEST)

    return ApiResponse.success(message="Lengths converted using active calibration.", data=converted)


@router.post("/{plan_id}/detect")
def detect_elements(
    plan_id: int,
    payload: dict = Body(default={}),
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:write")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)

    output_unit = payload.get("output_unit") if isinstance(payload, dict) else None
    variant = payload.get("variant") if isinstance(payload, dict) else None
    service = DetectionService(db)
    try:
        result = service.detect_plan(row, output_unit=output_unit, variant=variant)
    except ValueError as exc:
        return ApiResponse.error(message=str(exc), status_code=status.HTTP_400_BAD_REQUEST)
    except Exception as exc:
        return ApiResponse.error(message=f"Detection failed: {exc}", status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return ApiResponse.success(
        message="Step 2 scaffold detection completed.",
        data=result,
    )


@router.get("/{plan_id}/elements")
def list_detected_elements(
    plan_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:read")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)

    rows = (
        db.query(Element)
        .filter(Element.plan_id == plan_id)
        .order_by(Element.element_id.asc())
        .all()
    )
    payload = [
        {
            "element_id": r.element_id,
            "element_type": r.element_type,
            "pixel_length": r.pixel_length,
            "pixel_area": r.pixel_area,
            "length": r.length,
            "width": r.width,
            "height": r.height,
            "area": r.area,
            "volume": r.volume,
            "detected_label": r.detected_label,
            "confidence_score": r.confidence_score,
            "coordinates": r.coordinates,
        }
        for r in rows
    ]
    return ApiResponse.success(message="Elements fetched.", data={"elements": payload})


@router.post("/{plan_id}/floor-metrics")
def estimate_floor_metrics(
    plan_id: int,
    payload: dict = Body(default={}),
    db: Session = Depends(get_db),
    user: User = Depends(require_permissions("plans:read")),
):
    repo = PlanRepository(db)
    row = repo.get_for_user(plan_id=plan_id, user_id=user.user_id, is_admin=user.role == "admin")
    if row is None:
        return ApiResponse.error(message="Plan not found.", status_code=status.HTTP_404_NOT_FOUND)

    page_number = payload.get("page_number") if isinstance(payload, dict) else None
    variant = payload.get("variant") if isinstance(payload, dict) else None
    service = DetectionService(db)
    try:
        result = service.estimate_floor_metrics(
            row,
            page_number=page_number,
            variant=variant,
        )
    except ValueError as exc:
        return ApiResponse.error(message=str(exc), status_code=status.HTTP_400_BAD_REQUEST)
    except Exception as exc:
        return ApiResponse.error(
            message=f"Floor metrics failed: {exc}",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    return ApiResponse.success(message="Floor metrics estimated.", data=result)

