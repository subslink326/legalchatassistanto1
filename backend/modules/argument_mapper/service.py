from __future__ import annotations
import logging
from uuid import UUID
from typing import List, Dict, Tuple

from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from backend.config import settings
from backend.core import utils
from backend.db.search import bm25_search
from backend.db.vector_store import similarity_search
from . import prompts, graph

log = logging.getLogger(__name__)


class ArgumentMapRequest(BaseModel):
    project_id: UUID = Field(..., description="Target project")
    issue: str = Field(..., description="Issue statement")
    jurisdiction: str = Field("federal", description="e.g. 'federal', 'CA'")


class ArgumentMapResponse(BaseModel):
    graph: dict


def _elements_via_llm(issue: str, jurisdiction: str) -> List[str]:
    import openai

    client = openai.OpenAI(api_key=settings.openai_api_key)
    prompt = prompts.EXTRACT_ELEMENTS.format(issue=issue, jurisdiction=jurisdiction)
    res = client.chat.completions.create(
        model=settings.openai_model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=256,
        temperature=0,
    )
    raw = res.choices[0].message.content
    return [ln.lstrip("•- ").strip() for ln in raw.splitlines() if ln.strip()]


def _elements_fallback(issue: str) -> List[str]:
    toks = issue.replace("whether", "").replace("Whether", "").split(" and ")
    elems: list[str] = []
    for t in toks:
        elems.extend(x.strip() for x in t.split(",") if x.strip())
    return elems[:4]


def extract_elements(issue: str, jurisdiction: str) -> List[str]:
    if settings.openai_api_key:
        try:
            return _elements_via_llm(issue, jurisdiction)
        except Exception as e:  # noqa: BLE001
            log.warning("LLM extraction failed, falling back: %s", e)
    return _elements_fallback(issue)


async def gather_evidence(
    project_id: UUID,
    elements: List[str],
    top_k: int = 4,
) -> Dict[str, List[Tuple[str, str]]]:
    evidence: Dict[str, List[Tuple[str, str]]] = {}
    embed = utils.get_embedding
    for el in elements:
        bm25_hits = await bm25_search(el, project_id=str(project_id), top_k=top_k)
        vec_hits = await similarity_search(el, embed, top_k=top_k, project_filter=str(project_id))
        merged = {h["id"]: h["text"] for h in bm25_hits}
        for v in vec_hits:
            merged.setdefault(v["vector_id"], v["text"])
        evidence[el] = list(merged.items())[:top_k]
    return evidence


async def build_map(req: ArgumentMapRequest, db: AsyncSession | None = None) -> ArgumentMapResponse:
    elements = extract_elements(req.issue, req.jurisdiction)
    evidence = await gather_evidence(req.project_id, elements)
    g = graph.build_graph(req.issue, elements, evidence)
    return ArgumentMapResponse(graph=g)
