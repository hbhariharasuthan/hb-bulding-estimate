from __future__ import annotations

import json
from pathlib import Path

import cv2
from sqlalchemy.orm import Session

from app.models import Element, Plan
from app.repositories import PlanCalibrationRepository
from app.services.calibration_service import CalibrationService


class DetectionService:
    """Step 2 scaffold: create placeholder elements from processed pages."""

    def __init__(self, db: Session):
        self.db = db
        self._storage_root = Path(__file__).resolve().parents[2] / "storage" / "app" / "public"
        self._calibration_repo = PlanCalibrationRepository(db)
        self._calibration_service = CalibrationService(self._calibration_repo)

    _allowed_variants = {"soft", "binary", "ocr", "source"}

    def detect_plan(
        self,
        plan: Plan,
        *,
        output_unit: str | None = None,
        variant: str | None = None,
    ) -> dict:
        calibration = self._calibration_repo.get_for_plan(plan.plan_id)
        if calibration is None:
            raise ValueError("No active calibration found for this plan. Save calibration first.")

        pages = self._read_page_meta(plan.plan_id)
        if not pages:
            raise ValueError("No processed pages found. Run preprocessing first.")

        # Keep scaffold idempotent by replacing prior scaffold rows only.
        (
            self.db.query(Element)
            .filter(
                Element.plan_id == plan.plan_id,
                Element.detected_label == "step2_scaffold",
            )
            .delete(synchronize_session=False)
        )

        chosen_variant = (variant or "soft").lower()
        if chosen_variant not in self._allowed_variants:
            allowed = ", ".join(sorted(self._allowed_variants))
            raise ValueError(f"Unsupported variant '{chosen_variant}'. Allowed: {allowed}")

        created: list[Element] = []
        target_unit = (output_unit or calibration.output_unit or "m").lower()
        for page in pages:
            chosen = self._pick_variant_path(page, chosen_variant)
            image_path = self._to_local_path(str(chosen))
            width, height = self._read_image_size(image_path)
            if width <= 0 or height <= 0:
                continue

            # Placeholder geometry for Step 2 integration testing.
            p1 = float(width * 0.60)   # horizontal span
            p2 = float(height * 0.40)  # vertical span
            converted = self._calibration_service.convert_lengths(
                plan_id=plan.plan_id,
                pixel_lengths=[p1, p2],
                output_unit=target_unit,
            )["values"]

            e1 = Element(
                plan_id=plan.plan_id,
                element_type="wall_segment_scaffold",
                coordinates={
                    "page_number": page["page_number"],
                    "kind": "line",
                    "x1": width * 0.2,
                    "y1": height * 0.2,
                    "x2": width * 0.8,
                    "y2": height * 0.2,
                    "unit": target_unit,
                },
                pixel_length=p1,
                length=converted[0],
                detected_label="step2_scaffold",
                confidence_score=0.5,
            )
            e2 = Element(
                plan_id=plan.plan_id,
                element_type="wall_segment_scaffold",
                coordinates={
                    "page_number": page["page_number"],
                    "kind": "line",
                    "x1": width * 0.2,
                    "y1": height * 0.25,
                    "x2": width * 0.2,
                    "y2": height * 0.65,
                    "unit": target_unit,
                },
                pixel_length=p2,
                length=converted[1],
                detected_label="step2_scaffold",
                confidence_score=0.5,
            )
            self.db.add(e1)
            self.db.add(e2)
            created.extend([e1, e2])

        self.db.commit()
        for row in created:
            self.db.refresh(row)

        return {
            "plan_id": plan.plan_id,
            "calibration_id": calibration.calibration_id,
            "output_unit": target_unit,
            "variant": chosen_variant,
            "created_elements": [
                {
                    "element_id": row.element_id,
                    "element_type": row.element_type,
                    "pixel_length": row.pixel_length,
                    "length": row.length,
                    "coordinates": row.coordinates,
                }
                for row in created
            ],
        }

    def estimate_floor_metrics(
        self,
        plan: Plan,
        *,
        page_number: int | None = None,
        variant: str | None = None,
    ) -> dict:
        calibration = self._calibration_repo.get_for_plan(plan.plan_id)
        if calibration is None or calibration.mm_per_pixel is None or calibration.mm_per_pixel <= 0:
            raise ValueError("No active calibration with mm_per_pixel found for this plan.")

        pages = self._read_page_meta(plan.plan_id)
        if not pages:
            raise ValueError("No processed pages found. Run preprocessing first.")

        chosen_variant = (variant or "soft").lower()
        if chosen_variant not in self._allowed_variants:
            allowed = ", ".join(sorted(self._allowed_variants))
            raise ValueError(f"Unsupported variant '{chosen_variant}'. Allowed: {allowed}")

        page = None
        if page_number is None:
            page = pages[0]
        else:
            page = next((p for p in pages if int(p.get("page_number") or 0) == int(page_number)), None)
        if page is None:
            raise ValueError("Requested page not found in processed metadata.")

        chosen = self._pick_variant_path(page, chosen_variant)
        image_path = self._to_local_path(str(chosen))
        contour = self._extract_outer_contour(image_path)
        if contour is None:
            raise ValueError("Unable to detect outer floor contour from selected image.")

        perimeter_px = float(cv2.arcLength(contour, True))
        area_px2 = float(cv2.contourArea(contour))
        mm_per_pixel = float(calibration.mm_per_pixel)

        perimeter_mm = perimeter_px * mm_per_pixel
        area_mm2 = area_px2 * (mm_per_pixel ** 2)

        mm_per_foot = 304.8
        perimeter_ft = perimeter_mm / mm_per_foot
        area_sqft = area_mm2 / (mm_per_foot**2)

        perimeter_m = perimeter_mm / 1000.0
        area_sqm = area_mm2 / 1_000_000.0
        contour_points = [
            {"x": float(pt[0][0]), "y": float(pt[0][1])}
            for pt in contour
        ]

        return {
            "plan_id": plan.plan_id,
            "page_number": int(page.get("page_number") or 0),
            "variant": chosen_variant,
            "perimeter_px": perimeter_px,
            "area_px2": area_px2,
            "mm_per_pixel": mm_per_pixel,
            "perimeter_ft": perimeter_ft,
            "area_sqft": area_sqft,
            "perimeter_m": perimeter_m,
            "area_sqm": area_sqm,
            "contour_points": contour_points,
        }

    def _read_page_meta(self, plan_id: int) -> list[dict]:
        meta_dir = self._storage_root / "processed" / str(plan_id) / "meta"
        if not meta_dir.exists():
            return []
        out: list[dict] = []
        for meta_path in sorted(meta_dir.glob("page_*.json")):
            try:
                payload = json.loads(meta_path.read_text(encoding="utf-8"))
            except Exception:
                continue
            out.append(payload)
        return out

    def _pick_variant_path(self, page: dict, variant: str) -> str:
        if variant == "source":
            return str(page.get("source_image") or "")
        if variant == "binary":
            return str(
                page.get("processed_binary_image")
                or page.get("processed_image")
                or page.get("source_image")
                or ""
            )
        if variant == "ocr":
            return str(page.get("processed_image") or page.get("source_image") or "")
        # soft (default)
        return str(
            page.get("processed_soft_image")
            or page.get("processed_image")
            or page.get("source_image")
            or ""
        )

    def _to_local_path(self, public_path: str) -> Path:
        p = (public_path or "").strip()
        if p.startswith("/storage/"):
            return self._storage_root / p.removeprefix("/storage/").lstrip("/")
        return self._storage_root / p.lstrip("/")

    def _read_image_size(self, image_path: Path) -> tuple[int, int]:
        image = cv2.imread(str(image_path))
        if image is None:
            return (0, 0)
        h, w = image.shape[:2]
        return int(w), int(h)

    def _extract_outer_contour(self, image_path: Path):
        raw = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
        if raw is None:
            return None
        h, w = raw.shape[:2]
        blur = cv2.GaussianBlur(raw, (5, 5), 0)
        _, thr = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        # Building wall extraction only:
        # 1) Remove thin lines (dimension/plot/frame strokes)
        # 2) Connect thick wall segments into a dense footprint mask
        opened = cv2.morphologyEx(
            thr,
            cv2.MORPH_OPEN,
            cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5)),
            iterations=1,
        )
        wall_mask = cv2.morphologyEx(
            opened,
            cv2.MORPH_CLOSE,
            cv2.getStructuringElement(cv2.MORPH_RECT, (11, 11)),
            iterations=2,
        )
        wall_mask = cv2.morphologyEx(
            wall_mask,
            cv2.MORPH_OPEN,
            cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3)),
            iterations=1,
        )
        contours, _ = cv2.findContours(wall_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if not contours:
            return None

        img_area = float(h * w)
        min_area = img_area * 0.008
        border_margin_x = max(10, int(w * 0.03))
        border_margin_y = max(10, int(h * 0.03))
        candidates = []
        for c in contours:
            area = float(cv2.contourArea(c))
            if area < min_area:
                continue

            x, y, bw, bh = cv2.boundingRect(c)
            # Exclude page/frame/plot strokes near borders.
            if (
                x <= border_margin_x
                or y <= border_margin_y
                or (x + bw) >= (w - border_margin_x)
                or (y + bh) >= (h - border_margin_y)
            ):
                continue

            roi = wall_mask[y : y + bh, x : x + bw]
            density = float(cv2.countNonZero(roi)) / float(max(1, bw * bh))
            # Building walls form a denser component than sparse outer annotations.
            if density < 0.10:
                continue
            candidates.append(c)

        if not candidates:
            return None

        # Use largest dense in-frame contour as building footprint.
        return max(candidates, key=cv2.contourArea)
