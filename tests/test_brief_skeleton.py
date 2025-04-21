import asyncio, datetime
from backend.modules.brief_skeleton.service import BriefRequest, generate_brief
def test_generate_brief_markdown_only():
    req = BriefRequest(case_title="X v Y", motion_type="Rule 59 Motion",
                       issues=["A","B"], party="Defendant", prayer="a new trial")
    resp = asyncio.run(generate_brief(req))
    assert "### I. Issues Presented" in resp.outline_markdown
    assert resp.docx_filename is None
