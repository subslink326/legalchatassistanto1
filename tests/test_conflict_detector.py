from backend.modules.conflict_detector.nlp import extract_facts, contradicts
def test_extract_facts_detects_entities():
    facts = extract_facts("John Doe testified that he saw the defendant.")
    assert any("John Doe" in f for f in facts)
def test_contradiction_heuristic():
    assert contradicts("He never entered the warehouse.",
                       "He entered the warehouse at midnight.")
