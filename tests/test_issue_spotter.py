from backend.modules.issue_spotter.service import extract_issues
def test_extract_issues_fallback_on_objection():
    hits = extract_issues("The attorney lodged an objection at sidebar.")
    assert isinstance(hits, list) and any(h.get("issue_label") for h in hits)
