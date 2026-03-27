from __future__ import annotations

from pathlib import Path

import fitz


def render_pdf_pages_to_png(pdf_path: Path, output_dir: Path, dpi: int = 300) -> list[Path]:
    """Render every page of PDF into PNG files."""
    output_dir.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(str(pdf_path))
    matrix = fitz.Matrix(dpi / 72.0, dpi / 72.0)

    rendered: list[Path] = []
    for index in range(doc.page_count):
        page = doc.load_page(index)
        pixmap = page.get_pixmap(matrix=matrix, alpha=False)
        target = output_dir / f"page_{index + 1}.png"
        pixmap.save(str(target))
        rendered.append(target)

    doc.close()
    return rendered

