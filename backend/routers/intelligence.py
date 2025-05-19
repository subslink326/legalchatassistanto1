from fastapi import APIRouter, HTTPException, status
from pydantic import ValidationError

from backend.modules.argument_mapper import (
    ArgumentMapRequest,
    ArgumentMapResponse,
    build_map,
)

from backend.modules.counter_authority.service import (
    CounterRequest,
    CounterResponse,
    generate_counter,
)
from backend.modules.conflict_detector.service import (
    ConflictRequest,
    ConflictResponse,
    detect_conflicts,
)
from backend.modules.issue_spotter.service import (
    IssueSpotterRequest,
    IssueSpotterResponse,
    spot_issues,
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

# --------  Counter-Authority Rebuttal ----------
@router.post(
    "/counter-authority",
    response_model=CounterResponse,
    status_code=status.HTTP_200_OK,
)
async def counter_authority_endpoint(req: CounterRequest):
    try:
        return await generate_counter(req)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors())

# --------  Conflict Detector ----------
@router.post(
    "/conflict-detector",
    response_model=ConflictResponse,
    status_code=status.HTTP_200_OK,
)
async def conflict_detector_endpoint(req: ConflictRequest):
    try:
        return await detect_conflicts(req)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors())

# --------  Issue Spotter ----------
@router.post(
    "/issue-spotter",
    response_model=IssueSpotterResponse,
    status_code=status.HTTP_200_OK,
)
async def issue_spotter_endpoint(req: IssueSpotterRequest):
    try:
        return await spot_issues(req)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors())
