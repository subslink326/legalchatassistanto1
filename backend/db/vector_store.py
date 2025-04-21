"""
backend/db/vector_store.py
--------------------------
Thin wrapper around **Qdrant** for adding and querying chunk embeddings.

Highlights
----------
• Auto‑creates the collection (if missing) with `cosine` distance and
  configurable vector size.
• Works with both OpenAI embeddings and local models—just pass a `get_embedding`
  callable that turns text → list[float].
• Async‑compatible: runs Qdrant’s sync client in a threadpool via `anyio.to_thread`.
"""

from __future__ import annotations

import logging
import uuid
from typing import Callable, Sequence

import anyio
from qdrant_client import QdrantClient
from qdrant_client.http import models as qdrant
from backend.config import settings

log = logging.getLogger(__name__)

# --------------------------------------------------------------------------- #
# 1.  Client & collection bootstrap                                           #
# --------------------------------------------------------------------------- #
COLLECTION = "chunks"
VECTOR_SIZE = 1536         # adjust if you use different embedding dims
DISTANCE = qdrant.Distance.COSINE

_client: QdrantClient | None = None


def _get_client() -> QdrantClient:
    global _client
    if _client is None:
        _client = QdrantClient(url=settings.qdrant_url, timeout=30)
        _ensure_collection(_client)
    return _client


def _ensure_collection(client: QdrantClient) -> None:
    if COLLECTION in client.get_collections().collections:
        return

    log.warning("Qdrant collection '%s' not found—creating …", COLLECTION)
    client.create_collection(
        collection_name=COLLECTION,
        vectors_config=qdrant.VectorParams(
            size=VECTOR_SIZE,
            distance=DISTANCE,
        ),
    )
    client.create_payload_index(
        COLLECTION,
        field_name="document_id",
        field_schema=qdrant.PayloadSchemaType.KEYWORD,
    )
    client.create_payload_index(
        COLLECTION,
        field_name="project_id",
        field_schema=qdrant.PayloadSchemaType.KEYWORD,
    )


# --------------------------------------------------------------------------- #
# 2.  Public API                                                              #
# --------------------------------------------------------------------------- #
async def add_texts(
    project_id: str,
    document_id: str,
    texts: Sequence[str],
    get_embedding: Callable[[str], list[float]],
) -> list[str]:
    """
    Embed each `text`, upsert to Qdrant, and return the generated vector IDs.

    Parameters
    ----------
    project_id : str
    document_id : str
    texts : Sequence[str]
    get_embedding : Callable
        Function that converts a single string into an embedding list[float].
    """
    vectors, payloads, ids = [], [], []
    for t in texts:
        vec_id = str(uuid.uuid4())
        ids.append(vec_id)
        vectors.append(get_embedding(t))
        payloads.append(
            {
                "text": t,
                "project_id": project_id,
                "document_id": document_id,
            }
        )

    client = _get_client()

    def _upsert() -> None:  # runs in thread
        client.upsert(
            collection_name=COLLECTION,
            points=qdrant.Batch(
                ids=ids,
                vectors=vectors,
                payloads=payloads,
            ),
        )

    await anyio.to_thread.run_sync(_upsert)
    return ids


async def similarity_search(
    query: str,
    get_embedding: Callable[[str], list[float]],
    top_k: int = 8,
    project_filter: str | None = None,
) -> list[dict]:
    """
    Return top‑k most similar chunks.

    Each result dict contains:
    { "vector_id", "score", "text", "document_id", "project_id" }
    """
    query_vec = get_embedding(query)
    client = _get_client()

    def _search() -> list[qdrant.ScoredPoint]:
        return client.search(
            collection_name=COLLECTION,
            query_vector=query_vec,
            limit=top_k,
            with_payload=True,
            with_vectors=False,
            query_filter=qdrant.Filter(
                must=[
                    qdrant.FieldCondition(
                        key="project_id",
                        match=qdrant.MatchValue(value=project_filter),
                    )
                ]
            )
            if project_filter
            else None,
        )

    points = await anyio.to_thread.run_sync(_search)
    return [
        {
            "vector_id": p.id,
            "score": p.score,
            **p.payload,  # text, document_id, project_id
        }
        for p in points
    ]


async def delete_vectors(vector_ids: Sequence[str]) -> None:
    """Remove vectors (and their payload) from the collection."""
    client = _get_client()

    def _delete() -> None:
        client.delete(
            collection_name=COLLECTION,
            points_selector=qdrant.PointIdsList(points=vector_ids),
        )

    await anyio.to_thread.run_sync(_delete)
