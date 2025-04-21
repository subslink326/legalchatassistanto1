from fastapi import APIRouter, HTTPException, status
from pydantic import ValidationError

from backend.modules.argument_mapper import (
    ArgumentMapRequest,
    ArgumentMapResponse,
    build_map,
)

router = APIRouter()


@router.post(
    "/argument-map",
    response_model=ArgumentMapResponse,
    status_code=status.HTTP_200_OK,
)
async def argument_map_endpoint(req: ArgumentMapRequest):
    try:
        return await build_map(req)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors())

# --------  Brief Skeleton Generator ----------
from backend.modules.brief_skeleton.service import (
    BriefRequest,
    BriefResponse,
    generate_brief,
)


@router.post(
    "/brief-skeleton",
    response_model=BriefResponse,
    status_code=status.HTTP_200_OK,
)
async def brief_skeleton_endpoint(req: BriefRequest):
    try:
        return await generate_brief(req)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors())

# --------  Strength‑of‑Argument scorer ----------
from backend.modules.strength_score.service import (
    StrengthRequest,
    StrengthResponse,
    score_issue,
)


@router.post(
    "/argument-strength",
    response_model=StrengthResponse,
    status_code=status.HTTP_200_OK,
)
async def argument_strength_endpoint(req: StrengthRequest):
    try:
        return await score_issue(req)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors())
