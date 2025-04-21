"""
backend/db/search.py
--------------------
Minimal **Elasticsearch 8** BM25 wrapper for keyword / citation queries.

• Creates the index with english analyzers + k‑nearest‑shingles for phrase matches.
• Exposes `index_chunks()` to bulk‑index a list of chunks.
• `bm25_search()` runs a multi‑match over 'text' and 'filename' with configurable
  fuzziness; returns the same dict format as vector_store for easy merging.
"""

from __future__ import annotations

import logging
from typing import Iterable, Sequence

import aiohttp
import anyio
from elasticsearch import AsyncElasticsearch, exceptions as es_exceptions
from backend.config import settings

log = logging.getLogger(__name__)

INDEX = "chunks"

# --------------------------------------------------------------------------- #
# 1.  Client bootstrap & index template                                       #
# --------------------------------------------------------------------------- #
_es: AsyncElasticsearch | None = None


def _get_es() -> AsyncElasticsearch:
    global _es
    if _es is None:
        _es = AsyncElasticsearch(settings.elastic_url, request_timeout=30)
    return _es


MAPPINGS = {
    "mappings": {
        "properties": {
            "project_id": {"type": "keyword"},
            "document_id": {"type": "keyword"},
            "text": {"type": "text", "analyzer": "english"},
            "page": {"type": "integer"},
            "page_line": {"type": "keyword"},
            "filename": {"type": "keyword"},
        }
    }
}


async def _ensure_index() -> None:
    es = _get_es()
    exists = await es.indices.exists(index=INDEX)
    if not exists:
        log.warning("Elasticsearch index '%s' not found—creating …", INDEX)
        await es.indices.create(index=INDEX, body=MAPPINGS)


# --------------------------------------------------------------------------- #
# 2.  Public API                                                              #
# --------------------------------------------------------------------------- #
async def index_chunks(chunks: Iterable[dict]) -> None:
    """
    Bulk‑index chunk docs.

    Expected keys in each chunk dict:
    { id, project_id, document_id, text, page, page_line, filename }
    """
    await _ensure_index()
    actions: list[dict] = []
    for c in chunks:
        actions.append({"index": {"_index": INDEX, "_id": c["id"]}})
        actions.append(
            {
                "project_id": c["project_id"],
                "document_id": c["document_id"],
                "text": c["text"],
                "page": c["page"],
                "page_line": c["page_line"],
                "filename": c["filename"],
            }
        )
    es = _get_es()
    try:
        await es.bulk(operations=actions, refresh="wait_for")
    except es_exceptions.ElasticsearchException as exc:
        log.error("Elastic bulk‑index failed: %s", exc, exc_info=True)
        raise


async def bm25_search(
    query: str,
    project_id: str | None = None,
    top_k: int = 8,
) -> list[dict]:
    """
    Simple multi‑match BM25 search across 'text' + 'filename'.

    Returns list[dict] containing `_id`, `_score`, and the source fields.
    """
    await _ensure_index()
    es = _get_es()
    must_clause: list[dict] = [
        {
            "multi_match": {
                "query": query,
                "fields": ["text^2", "filename"],
                "fuzziness": "AUTO",
            }
        }
    ]
    if project_id:
        must_clause.append({"term": {"project_id": project_id}})

    body = {
        "query": {
            "bool": {
                "must": must_clause,
            }
        },
        "size": top_k,
    }
    res = await es.search(index=INDEX, body=body)
    hits = res["hits"]["hits"]
    return [
        {
            "id": h["_id"],
            "score": h["_score"],
            **h["_source"],
        }
        for h in hits
    ]
