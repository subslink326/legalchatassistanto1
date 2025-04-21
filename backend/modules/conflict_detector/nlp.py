"""
Lightweight NLP helpers:
• load_spacy()      – lazy‑loads en_core_web_sm (or legal‑specific model if present)
• extract_facts()   – returns list[str] factual statements from chunk text
• contradicts(a,b)  – heuristic contradiction detector
"""
from __future__ import annotations
import re
from functools import lru_cache
from typing import List
import spacy
from sentence_transformers import SentenceTransformer, util  # noqa: F401

@lru_cache
def load_spacy():
    try:
        return spacy.load("en_core_web_sm")
    except OSError:  # model not installed
        import spacy.cli
        spacy.cli.download("en_core_web_sm")
        return spacy.load("en_core_web_sm")


_model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")


def extract_facts(text: str) -> List[str]:
    """
    Very naive splitter: one fact per sentence containing a named entity.
    """
    nlp = load_spacy()
    doc = nlp(text)
    sentences = []
    for sent in doc.sents:
        if any(tok.ent_type_ for tok in sent):
            sentences.append(sent.text.strip())
    return sentences


def contradicts(s1: str, s2: str) -> bool:
    """
    Heuristic: if semantic similarity <.2 AND sentiment polarity opposite,
    flag as contradiction.
    """
    sim = util.cos_sim(_model.encode(s1), _model.encode(s2)).item()
    if sim > 0.2:
        return False
    # simple negation keyword check
    neg_words = {"no", "never", "not"}
    return (neg_words & set(w.lower() for w in s1.split())) ^ (neg_words & set(w.lower() for w in s2.split()))
