"""
backend/core/ocr.py
-------------------
Fallback OCR for scanned PDFs or images.

Primary strategy:
• Try PyMuPDF (fitz) to extract text layer.
• If empty, rasterize page → run Tesseract (`pytesseract.image_to_string`).

Exposed function:
    extract_text(pdf_path: Path) -> list[str]   # list of page strings
"""
from __future__ import annotations

import logging
from pathlib import Path
from typing import List

import pytesseract
import fitz  # PyMuPDF
from PIL import Image

log = logging.getLogger(__name__)


def _page_text_or_ocr(page) -> str:
    text = page.get_text().strip()
    if text:
        return text

    # Rasterize at 300 DPI for better OCR quality
    pix = page.get_pixmap(dpi=300)
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
    ocr_text = pytesseract.image_to_string(img)
    log.debug("OCR extracted %d chars from page %d", len(ocr_text), page.number)
    return ocr_text


def extract_text(pdf_path: Path) -> List[str]:
    """Return list of page strings (may include empty pages)."""
    pages: list[str] = []
    with fitz.open(pdf_path) as doc:
        for page in doc:
            pages.append(_page_text_or_ocr(page))
    return pages
