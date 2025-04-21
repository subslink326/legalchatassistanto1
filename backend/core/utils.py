"""
backend/core/utils.py
---------------------
Grab‑bag of small helpers shared across modules:
• secure_filename() – sanitize user‑uploaded filenames
• sha256_file()     – content hash for deduplication
• get_embedding()   – default text → vector using either OpenAI or local model
"""
from __future__ import annotations

import hashlib
import os
import re
from pathlib import Path
from typing import List

from backend.config import settings

# -------------------- #
# 1.  Secure filename   #
# -------------------- #
_filename_strip_re = re.compile(r"[^A-Za-z0-9_.-]")


def secure_filename(value: str) -> str:
    """
    Simple Flask‑style filename sanitizer.
    """
    value = _filename_strip_re.sub("", value)
    return value[:255]


# -------------------- #
# 2.  File SHA‑256      #
# -------------------- #
def sha256_file(path: os.PathLike) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


# ------------------------------ #
# 3.  Embedding convenience      #
# ------------------------------ #
def _openai_embedding(texts: List[str]) -> List[List[float]]:
    import openai  # import lazily

    client = openai.OpenAI(api_key=settings.openai_api_key)
    res = client.embeddings.create(
        model="text-embedding-3-large",
        input=texts,
    )
    return [d.embedding for d in res.data]


def _local_embedding(texts: List[str]) -> List[List[float]]:
    # Placeholder: load your sentence‑transformers model here.
    from sentence_transformers import SentenceTransformer

    model = SentenceTransformer("intfloat/e5-large-v2")
    return model.encode(texts, normalize_embeddings=True).tolist()


def get_embedding(text: str) -> List[float]:
    """
    Wrapper returning a single embedding list[float] for `text`.
    Chooses OpenAI if API key is present, else falls back to local model.
    """
    if settings.openai_api_key:
        return _openai_embedding([text])[0]
    return _local_embedding([text])[0]
