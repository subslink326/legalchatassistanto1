from __future__ import annotations
import networkx as nx
from networkx.readwrite import json_graph
from typing import List, Dict, Tuple


def build_graph(
    issue: str,
    elements: List[str],
    evidence: Dict[str, List[Tuple[str, str]]],
) -> dict:
    G = nx.DiGraph()
    G.add_node("issue", label=issue, type="issue")

    for el in elements:
        el_node = f"el:{el}"
        G.add_node(el_node, label=el, type="element")
        G.add_edge("issue", el_node)

        for chunk_id, snippet in evidence.get(el, []):
            ev_node = f"ev:{chunk_id}"
            G.add_node(
                ev_node,
                label=snippet,
                type="evidence",
                chunk_id=chunk_id,
            )
            G.add_edge(el_node, ev_node)

    return json_graph.node_link_data(G)
