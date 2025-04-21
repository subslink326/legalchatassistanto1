from backend.modules.argument_mapper.service import extract_elements
from backend.modules.argument_mapper import graph

def test_extract_elements_fallback():
    issue = "Whether the trial court abused its discretion and erred"
    elems = extract_elements(issue, "federal")
    assert isinstance(elems, list) and all(isinstance(e, str) for e in elems)

def test_build_graph_structure():
    g = graph.build_graph("ISSUE", ["E1"], {"E1":[("C1","snippet")]})
    assert "nodes" in g and "links" in g
    assert any(n["label"]=="ISSUE" for n in g["nodes"])
    assert any(l for l in g["links"] if l["source"] == 0)
