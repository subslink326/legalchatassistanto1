import asyncio
from backend.modules.strength_score.service import StrengthRequest, score_issue
def test_score_issue_range_and_breakdown():
    req = StrengthRequest(project_id="0"*32, issue="Sample", standard_of_review="de novo", k=0)
    resp = asyncio.run(score_issue(req))
    assert 0 <= resp.score <= 100 and len(resp.breakdown)==4
