from __future__ import annotations

# Manual scale options for image/PDF based workflows.
# Key is what frontend can send back in payload.
MANUAL_SCALE_OPTIONS: dict[str, dict[str, int | str]] = {
    "1:50": {"numerator": 1, "denominator": 50, "label": "1:50"},
    "1:100": {"numerator": 1, "denominator": 100, "label": "1:100"},
    "1:200": {"numerator": 1, "denominator": 200, "label": "1:200"},
}

# Typical rendered image DPI baseline.
DEFAULT_IMAGE_DPI = 96
