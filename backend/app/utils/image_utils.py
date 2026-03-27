from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


@dataclass
class EnhancedImageSet:
    soft_path: Path
    binary_path: Path
    ocr_path: Path


def enhance_image(source_path: Path, target_path: Path) -> Path:
    """Backward-compatible wrapper: writes OCR-friendly binary output."""
    result = enhance_image_variants(
        source_path=source_path,
        soft_target_path=target_path.with_name(f"{target_path.stem}_soft{target_path.suffix}"),
        binary_target_path=target_path.with_name(f"{target_path.stem}_binary{target_path.suffix}"),
        ocr_target_path=target_path,
    )
    return result.ocr_path


def enhance_image_variants(
    *,
    source_path: Path,
    soft_target_path: Path,
    binary_target_path: Path,
    ocr_target_path: Path,
) -> EnhancedImageSet:
    """Create multiple variants for detection and OCR."""
    raw = cv2.imread(str(source_path), cv2.IMREAD_COLOR)
    if raw is None:
        raise ValueError(f"Unable to read image: {source_path}")

    gray = cv2.cvtColor(raw, cv2.COLOR_BGR2GRAY)
    denoised = cv2.GaussianBlur(gray, (3, 3), 0)

    # Soft variant preserves line texture for object detection.
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    soft = clahe.apply(denoised)

    # Binary variant is useful for OCR/edge diagnostics.
    binary = cv2.adaptiveThreshold(
        denoised,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        31,
        5,
    )

    # OCR variant keeps previous behavior for compatibility.
    edges = cv2.Canny(binary, 60, 160)
    ocr = cv2.bitwise_or(binary, edges)

    for target, image in (
        (soft_target_path, soft),
        (binary_target_path, binary),
        (ocr_target_path, ocr),
    ):
        target.parent.mkdir(parents=True, exist_ok=True)
        ok = cv2.imwrite(str(target), image)
        if not ok:
            raise ValueError(f"Unable to save processed image: {target}")

    return EnhancedImageSet(
        soft_path=soft_target_path,
        binary_path=binary_target_path,
        ocr_path=ocr_target_path,
    )


def detect_dpi(image_path: Path, default_dpi: float = 300.0) -> float:
    """Read DPI from image metadata when possible."""
    try:
        with Image.open(image_path) as image:
            info = image.info.get("dpi")
            if isinstance(info, tuple) and info and info[0]:
                return float(info[0])
            if isinstance(info, (int, float)) and info > 0:
                return float(info)
    except Exception:
        pass
    return float(default_dpi)


def extract_text_for_unit_detection(image_path: Path) -> str:
    """OCR helper with conservative preprocessing."""
    try:
        import pytesseract
    except Exception:
        return ""

    raw = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
    if raw is None:
        return ""

    normalized = cv2.GaussianBlur(raw, (3, 3), 0)
    _, threshold = cv2.threshold(normalized, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    text = pytesseract.image_to_string(np.asarray(threshold))
    return (text or "").lower()

