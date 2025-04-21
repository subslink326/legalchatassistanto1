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
