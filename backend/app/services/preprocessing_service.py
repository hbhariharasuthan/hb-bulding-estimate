from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from sqlalchemy.orm import Session

from app.models import Plan
from app.utils.cad_utils import cad_to_images_placeholder
from app.utils.image_utils import detect_dpi, enhance_image_variants, extract_text_for_unit_detection
from app.utils.pdf_utils import render_pdf_pages_to_png


class PreprocessingService:
    def __init__(self, db: Session):
        self.db = db
        self._storage_root = Path(__file__).resolve().parents[2] / "storage" / "app" / "public"

    def process_plan(self, row: Plan) -> Plan:
        row.status = "processing"
        row.error_message = None
        row.processing_progress = 0
        row.current_page = 0
        self._save(row)

        try:
            source_path = self._resolve_source_path(row.file_path)
            pages_dir = self._storage_root / "plans" / str(row.plan_id)
            processed_dir = self._storage_root / "processed" / str(row.plan_id)
            meta_dir = processed_dir / "meta"
            pages_dir.mkdir(parents=True, exist_ok=True)
            processed_dir.mkdir(parents=True, exist_ok=True)
            meta_dir.mkdir(parents=True, exist_ok=True)

            source_pages = self._to_source_pages(row, source_path, pages_dir)
            total_pages = len(source_pages)
            row.total_pages = total_pages
            row.dpi = detect_dpi(source_pages[0]) if total_pages else 300.0
            self._save(row)

            unit_votes: list[str] = []
            for index, source_page in enumerate(source_pages, start=1):
                processed_target = processed_dir / f"page_{index}.png"
                soft_target = processed_dir / f"page_{index}_soft.png"
                binary_target = processed_dir / f"page_{index}_binary.png"
                variants = enhance_image_variants(
                    source_path=source_page,
                    soft_target_path=soft_target,
                    binary_target_path=binary_target,
                    ocr_target_path=processed_target,
                )

                unit = self.detect_units(variants.binary_path)
                if unit:
                    unit_votes.append(unit)

                meta = {
                    "plan_id": row.plan_id,
                    "page_number": index,
                    "source_image": self._as_public_path(source_page),
                    "processed_image": self._as_public_path(variants.ocr_path),
                    "processed_soft_image": self._as_public_path(variants.soft_path),
                    "processed_binary_image": self._as_public_path(variants.binary_path),
                    "detected_unit": unit or "",
                    "explanation": (
                        "Generated soft (detection), binary (OCR) and OCR-enhanced variants."
                    ),
                }
                meta_path = meta_dir / f"page_{index}.json"
                meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")

                row.current_page = index
                row.processing_progress = int((index / total_pages) * 100) if total_pages else 100
                self._save(row)

            row.detected_units = self._best_unit(unit_votes)
            row.status = "completed"
            row.processing_progress = 100
            return self._save(row)
        except Exception as exc:
            row.status = "failed"
            row.error_message = str(exc)
            self._save(row)
            raise

    def detect_units(self, image_path: Path) -> str | None:
        text = extract_text_for_unit_detection(image_path)
        if not text:
            return None
        if "mm" in text:
            return "mm"
        if "cm" in text:
            return "cm"
        if " ft" in text or "feet" in text or "foot" in text:
            return "ft"
        if "meter" in text or " m " in f" {text} ":
            return "m"
        return None

    def _to_source_pages(self, row: Plan, source_path: Path, pages_dir: Path) -> list[Path]:
        ftype = (row.file_type or "").lower().strip(".")
        suffix = source_path.suffix.lower()
        if ftype == "pdf" or suffix == ".pdf":
            return render_pdf_pages_to_png(source_path, pages_dir, dpi=300)
        if ftype in {"png", "jpg", "jpeg", "webp", "bmp", "tiff"} or suffix in {
            ".png",
            ".jpg",
            ".jpeg",
            ".webp",
            ".bmp",
            ".tif",
            ".tiff",
        }:
            target = pages_dir / "page_1.png"
            target.write_bytes(source_path.read_bytes())
            return [target]
        if ftype in {"dwg", "dxf"} or suffix in {".dwg", ".dxf"}:
            return cad_to_images_placeholder(source_path, pages_dir)
        raise ValueError(f"Unsupported file type: {row.file_type or suffix}")

    def _best_unit(self, votes: list[str]) -> str | None:
        if not votes:
            return None
        return Counter(votes).most_common(1)[0][0]

    def _resolve_source_path(self, file_path: str) -> Path:
        p = (file_path or "").strip()
        if not p:
            raise ValueError("Missing plan file path")
        if p.startswith("/storage/"):
            candidate = self._storage_root / p.removeprefix("/storage/").lstrip("/")
        else:
            candidate = Path(p)
            if not candidate.is_absolute():
                candidate = self._storage_root / p.lstrip("/")
        if not candidate.exists():
            raise FileNotFoundError(f"Plan file not found: {candidate}")
        return candidate

    def _as_public_path(self, path: Path) -> str:
        rel = path.relative_to(self._storage_root)
        return f"/storage/{rel.as_posix()}"

    def _save(self, row: Plan) -> Plan:
        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row

