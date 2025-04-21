from __future__ import annotations
import logging
from collections import defaultdict
from uuid import UUID
from typing import List

from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.modules.conflict_detector import nlp
from backend.db import models

log = logging.getLogger(__name__)


class ConflictCard(BaseModel):
    statement_a: str
    source_a: str
    statement_b: str
    source_b: str
    explanation: str = "Possible contradiction"


class ConflictRequest(BaseModel):
    project_id: UUID
    max_pairs: int | None = Field(50, gt=0, le=500)


class ConflictResponse(BaseModel):
    conflicts: List[ConflictCard]


async def detect_conflicts(req: ConflictRequest, db: AsyncSession) -> ConflictResponse:
    q = (
        select(models.Chunk, models.Document)
        .join(models.Document)
        .where(models.Document.project_id == req.project_id)
    )
    rows = (await db.execute(q)).all()
    facts_by_doc: dict[str, list[tuple[str, str]]] = defaultdict(list)

    for chunk, doc in rows:
        for fact in nlp.extract_facts(chunk.text):
            cite = f"{doc.filename} p.{chunk.page}"
            facts_by_doc[doc.id.hex].append((fact, cite))

    conflicts: list[ConflictCard] = []
    seen = set()
    for doc_id, facts in facts_by_doc.items():
        n = len(facts)
        for i in range(n):
            for j in range(i + 1, n):
                f1, cite1 = facts[i]
                f2, cite2 = facts[j]
                key = tuple(sorted((f1, f2)))
                if key in seen:
                    continue
                seen.add(key)
                if nlp.contradicts(f1, f2):
                    conflicts.append(
                        ConflictCard(
                            statement_a=f1,
                            source_a=cite1,
                            statement_b=f2,
                            source_b=cite2,
                        )
                    )
                    if len(conflicts) >= (req.max_pairs or 50):
                        return ConflictResponse(conflicts=conflicts)
    return ConflictResponse(conflicts=conflicts)
