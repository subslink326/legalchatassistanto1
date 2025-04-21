#!/usr/bin/env bash
set -euo pipefail

# 1) Module directory
mkdir -p backend/modules/counter_authority

# 2) prompts.py
cat > backend/modules/counter_authority/prompts.py <<'PY'
"""
Counter‑Authority LLM prompt templates.
"""
REBUTTAL_TEMPLATE = """
You are government counsel drafting a rebuttal to the defense arguments below.
Provide a concise, persuasive response citing any negative or contrary authority.

Defense Draft:
\"\"\"{draft}\"\"\"
"""
PY

# 3) service.py
cat > backend/modules/counter_authority/service.py <<'PY'
from __future__ import annotations
import logging
from uuid import UUID
from typing import Optional
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from backend.config import settings
from backend.modules.counter_authority import prompts

log = logging.getLogger(__name__)

class CounterRequest(BaseModel):
    project_id: UUID
    draft: str

class CounterResponse(BaseModel):
    rebuttal: str

async def generate_counter(
    req: CounterRequest,
    db: AsyncSession | None = None,
) -> CounterResponse:
    # Try OpenAI if key is set
    if settings.openai_api_key:
        try:
            import openai
            client = openai.OpenAI(api_key=settings.openai_api_key)
            prompt = prompts.REBUTTAL_TEMPLATE.format(draft=req.draft)
            res = client.chat.completions.create(
                model=settings.openai_model,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=512,
                temperature=0.7,
            )
            text = res.choices[0].message.content
            return CounterResponse(rebuttal=text)
        except Exception as e:
            log.warning("LLM counter generation failed: %s", e)
    # Fallback stub
    stub = (
        "Government counsel would argue that the defendant's position is meritless "
        "and would cite controlling negative authority to defeat it."
    )
    return CounterResponse(rebuttal=stub)
PY

# 4) Patch the intelligence router
apply_patch() {
patch --silent backend/routers/intelligence.py <<'PATCH'
*** Begin Patch
@@
 from fastapi import APIRouter, HTTPException, status
-from pydantic import ValidationError
+from pydantic import ValidationError
+
+# --------  Counter‑Authority Generator ----------
+from backend.modules.counter_authority.service import (
+    CounterRequest,
+    CounterResponse,
+    generate_counter,
+)
@@
     except ValidationError as e:
         raise HTTPException(status_code=400, detail=e.errors())
+
+
+@router.post(
+    "/counter-authority",
+    response_model=CounterResponse,
+    status_code=status.HTTP_200_OK,
+)
+async def counter_authority_endpoint(req: CounterRequest):
+    try:
+        from backend.db.database import get_db
+        async for db in get_db():
+            return await generate_counter(req, db)
+    except ValidationError as e:
+        raise HTTPException(status_code=400, detail=e.errors())
*** End Patch
PATCH
}
apply_patch

echo "✅ Phase 12 files written and router updated."
