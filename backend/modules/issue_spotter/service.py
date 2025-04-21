from __future__ import annotations
import json
import logging
from collections import Counter, defaultdict
from uuid import UUID
from typing import List, Dict

from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.config import settings
from backend.db import models
from . import prompts

log = logging.getLogger(__name__)


# ---------- Pydantic ---------- #
class IssueSpotterRequest(BaseModel):
    project_id: UUID
    top_k: int | None = Field(
        20, description="Return at most this many ranked issues"
    )


class IssueHit(BaseModel):
    label: str
    preserved: bool
    citations: List[str]
    frequency: int


class IssueSpotterResponse(BaseModel):
    issues: List[IssueHit]


# ---------- LLM helpers ---------- #
def _llm_extract(chunk_txt: str) -> List[dict]:
    import openai, tiktoken  # noqa: WPS433

    client = openai.OpenAI(api_key=settings.openai_api_key)
    msg = prompts.EXTRACT_ISSUES.format(excerpt=chunk_txt[:4000])
    out = client.chat.completions.create(
        model=settings.openai_model,
        messages=[{"role": "user", "content": msg}],
        max_tokens=512,
        temperature=0,
    )
    raw = out.choices[0].message.content
    try:
        return json.loads(raw)
    except json.JSONDecodeError:  # fail soft
        log.warning("Issue JSON parse failed; raw=%s", raw[:200])
        return []


def _fallback_extract(chunk_txt: str) -> List[dict]:
    # Very naive regex fallback: flag lines with "objection" / "error"
    if "objection" in chunk_txt.lower():
        return [
            {
                "issue_label": "Evidentiary objection",
                "preserved": True,
                "rule": "Fed. R. Evid.",
                "citation": "",
            }
        ]
    return []


def extract_issues(chunk_txt: str) -> List[dict]:
    if settings.openai_api_key:
        try:
            return _llm_extract(chunk_txt)
        except Exception as exc:  # noqa: BLE001
            log.warning("LLM issue extract failed -> fallback: %s", exc)
    return _fallback_extract(chunk_txt)


# ---------- Core routine ---------- #
async def spot_issues(
    req: IssueSpotterRequest,
    db: AsyncSession,
) -> IssueSpotterResponse:
    # 1. Pull all chunks for project
    chunks = (
        await db.execute(
            select(models.Chunk).join(models.Document).where(
                models.Document.project_id == req.project_id
            )
        )
    ).scalars()

    raw_hits: List[dict] = []
    for ch in chunks:
        raw_hits.extend(extract_issues(ch.text))

    # 2. Consolidate duplicates
    counter: Counter[str] = Counter()
    citations: Dict[str, list[str]] = defaultdict(list)
    preserved_map: Dict[str, bool] = {}

    for hit in raw_hits:
        label = hit["issue_label"]
        counter[label] += 1
        preserved_map[label] = hit.get("preserved", True)
        if hit.get("citation"):
            citations[label].append(hit["citation"])

    ranked = counter.most_common(req.top_k or len(counter))

    issues_out: List[IssueHit] = [
        IssueHit(
            label=lbl,
            preserved=preserved_map.get(lbl, True),
            citations=citations.get(lbl, []),
            frequency=freq,
        )
        for lbl, freq in ranked
    ]

    return IssueSpotterResponse(issues=issues_out)
