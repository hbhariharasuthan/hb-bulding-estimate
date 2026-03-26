from __future__ import annotations

from app.config.scale_config import DEFAULT_IMAGE_DPI, MANUAL_SCALE_OPTIONS

MM_PER_INCH = 25.4


def get_manual_scale_option(scale_key: str) -> dict[str, int | str]:
    option = MANUAL_SCALE_OPTIONS.get(scale_key)
    if option is None:
        allowed = ", ".join(MANUAL_SCALE_OPTIONS.keys())
        raise ValueError(f"Unsupported scale '{scale_key}'. Allowed: {allowed}")
    return option


def compute_manual_scale_factor(scale_key: str, dpi: int = DEFAULT_IMAGE_DPI) -> float:
    """
    Returns real-world millimeters represented by one pixel.
    """
    if dpi <= 0:
        raise ValueError("dpi must be > 0")

    option = get_manual_scale_option(scale_key)
    denominator = int(option["denominator"])
    mm_per_pixel_on_drawing = MM_PER_INCH / float(dpi)
    return mm_per_pixel_on_drawing * float(denominator)


def apply_manual_scale(
    pixel_length: float,
    scale_key: str,
    dpi: int = DEFAULT_IMAGE_DPI,
    output_unit: str = "m",
) -> float:
    """
    Converts pixel length to real-world length in requested unit.
    Supported units: mm, cm, m.
    """
    if pixel_length <= 0:
        raise ValueError("pixel_length must be > 0")

    mm_length = pixel_length * compute_manual_scale_factor(scale_key=scale_key, dpi=dpi)
    unit = output_unit.lower()
    if unit == "mm":
        return mm_length
    if unit == "cm":
        return mm_length / 10.0
    if unit == "m":
        return mm_length / 1000.0
    raise ValueError("output_unit must be one of: mm, cm, m")
