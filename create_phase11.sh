#!/usr/bin/env bash
set -euo pipefail

mkdir -p backend/modules/strength_score

# 1.  backend/modules/strength_score/service.py
cat > backend/modules/strength_score/service.py <<'PY'
"""
Compute a 0‑100 strength score for a single issue.
Stubbed precedent & split checks; replace with real legal‑search integrations.
"""
from __future__ import annotations
import hashlib
import logging
from typing import List

from pydantic import BaseModel, Field, validator

from backend.core import utils
from backend.db.vector_store import similarity_search
from backend.db.search import bm25_search
from backend.config import settings

log = logging.getLogger(__name__)


# ---------- Pydantic ---------- #
class StrengthRequest(BaseModel):
    project_id: str = Field(..., description="UUID string")
    issue: str
    standard_of_review: str = Field(..., regex=r"(?i)(de novo|abuse|plain error)")
    k: int | None = Field(5, description="Top‑k chunks to gauge record clarity")


class StrengthResponse(BaseModel):
    score: float
    breakdown: dict[str, float]


# ---------- Factor helpers ---------- #
_STD_REVIEW_TABLE = {
    "de novo": 1.0,
    "abuse": 0.6,
    "plain error": 0.3,
}


def _precedent_weight(issue: str) -> float:
    """
    Placeholder: hash‑based deterministic pseudo‑score until
    real precedent search is wired.
    """
    h = int(hashlib.sha1(issue.encode()).hexdigest(), 16)
    return (h % 10) / 10  # 0.0 ‑ 0.9


def _novelty(issue: str) -> float:
    return 1.0 if "circuit split" in issue.lower() else 0.0


async def _record_clarity(issue: str, project_id: str, k: int = 5) -> float:
    embed = utils.get_embedding
    vec_hits = await similarity_search(
        issue, embed, top_k=k, project_filter=project_id
    )
    if not vec_hits:
        return 0.0
    # cosine scores come back 0‑1; average them
    return sum(h["score"] for h in vec_hits) / len(vec_hits)


# ---------- Main entry ---------- #
async def score_issue(req: StrengthRequest) -> StrengthResponse:
    precedent = _precedent_weight(req.issue)
    std_review = _STD_REVIEW_TABLE.get(req.standard_of_review.lower(), 0.3)
    record = await _record_clarity(req.issue, req.project_id, req.k or 5)
    novelty = _novelty(req.issue)

    score = (
        0.40 * precedent
        + 0.25 * std_review
        + 0.20 * record
        + 0.15 * novelty
    ) * 100

    return StrengthResponse(
        score=round(score, 2),
        breakdown={
            "precedent": precedent,
            "standard_of_review": std_review,
            "record_clarity": record,
            "novelty": novelty,
        },
    )
PY

# 2.  Patch backend/routers/intelligence.py
apply_patch() {
patch --silent backend/routers/intelligence.py <<'PATCH'
*** Begin Patch
@@
     except ValidationError as e:
         raise HTTPException(status_code=400, detail=e.errors())
 
@@
     except ValidationError as e:
         raise HTTPException(status_code=400, detail=e.errors())
+
+# --------  Strength‑of‑Argument scorer ----------
+from backend.modules.strength_score.service import (
+    StrengthRequest,
+    StrengthResponse,
+    score_issue,
+)
+
+
+@router.post(
+    "/argument-strength",
+    response_model=StrengthResponse,
+    status_code=status.HTTP_200_OK,
+)
+async def argument_strength_endpoint(req: StrengthRequest):
+    try:
+        return await score_issue(req)
+    except ValidationError as e:
+        raise HTTPException(status_code=400, detail=e.errors())
*** End Patch
PATCH
}
apply_patch

echo "✅ Phase 11 files written; Strength‑score endpoint added."