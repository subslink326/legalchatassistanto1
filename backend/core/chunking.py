"""
backend/core/chunking.py
------------------------
Adaptive text splitters that respect model token budgets and, for transcripts,
preserve page:line boundaries (e.g., "34:12").

Public API
----------
• `split_text(text, max_tokens, tokenizer)`      – generic sentence/paragraph splitter
• `split_transcript(text, max_tokens, tokenizer)`– splitter that keeps page:line
• `count_tokens(text, tokenizer)`                – helper used across pipeline
"""
from __future__ import annotations

import re
from typing import Callable, Iterable, List

# Default tokenizer (OpenAI tiktoken); callers can inject others
try:
    import tiktoken

    _default_tokenizer = tiktoken.get_encoding("cl100k_base")
except ModuleNotFoundError:  # fallback to whitespace split if tiktoken unavailable
    _default_tokenizer = None  # type: ignore

# -------------------- #
# 1.  Token counting    #
# -------------------- #
def count_tokens(text: str, tokenizer: Callable | None = None) -> int:
    tok = tokenizer or _default_tokenizer
    if tok is None:
        # naïve fallback
        return len(text.split())
    return len(tok.encode(text))


# -------------------- #
# 2.  Generic splitter  #
# -------------------- #
def _paragraphs(text: str) -> Iterable[str]:
    buf: list[str] = []
    for line in text.splitlines():
        if line.strip():
            buf.append(line)
        elif buf:
            yield " ".join(buf).strip()
            buf.clear()
    if buf:
        yield " ".join(buf).strip()


def split_text(
    text: str,
    max_tokens: int,
    tokenizer: Callable | None = None,
) -> List[str]:
    """
    Split into chunks ≤ `max_tokens`, attempting to break on paragraph boundaries,
    then on sentence punctuation if still too large.
    """
    tokenizer = tokenizer or _default_tokenizer
    chunks: list[str] = []

    for para in _paragraphs(text):
        if count_tokens(para, tokenizer) <= max_tokens:
            chunks.append(para)
            continue

        # Sentence‑level split for huge paragraphs
        sentences = re.split(r"(?<=[.!?])\s+", para)
        buf = ""
        for s in sentences:
            if count_tokens(buf + " " + s, tokenizer) > max_tokens:
                chunks.append(buf.strip())
                buf = s
            else:
                buf += " " + s
        if buf:
            chunks.append(buf.strip())

    return [c for c in chunks if c]


# ------------------------------- #
# 3.  Transcript‑aware splitter    #
# ------------------------------- #
_PAGE_LINE = re.compile(r"^(\d+):(\d+)\s+(.+)$")


def split_transcript(
    text: str,
    max_tokens: int,
    tokenizer: Callable | None = None,
) -> List[dict]:
    """
    Returns list[dict] with keys:
      { 'text', 'page', 'line' }

    Keeps page‑and‑line intact so citations are precise.
    """
    tokenizer = tokenizer or _default_tokenizer
    current_chunk: list[str] = []
    page, line = None, None
    out: list[dict] = []

    for raw in text.splitlines():
        m = _PAGE_LINE.match(raw)
        if not m:
            continue  # skip malformed
        pg, ln, content = int(m.group(1)), int(m.group(2)), m.group(3)
        candidate = " ".join([*current_chunk, content]).strip()

        if count_tokens(candidate, tokenizer) > max_tokens and current_chunk:
            out.append(
                {
                    "text": " ".join(current_chunk).strip(),
                    "page": page,
                    "line": line,
                }
            )
            current_chunk = [content]
            page, line = pg, ln
        else:
            if not current_chunk:
                page, line = pg, ln
            current_chunk.append(content)

    if current_chunk:
        out.append({"text": " ".join(current_chunk).strip(), "page": page, "line": line})

    return out
