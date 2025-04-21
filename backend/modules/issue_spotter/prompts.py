"""
Issue‑Spotter LLM templates.
"""

EXTRACT_ISSUES = """
You are appellate counsel reviewing trial‑record text. Identify every distinct
legal issue preserved in the excerpt. For each, output JSON with:
  issue_label, preserved (Y/N), rule, citation (page:line pairs).

Return ONLY JSON list — no prose.

###
EXCERPT:
\"\"\"{excerpt}\"\"\"
###
"""
REDUCE_ISSUES = """
You are consolidating issue lists extracted from multiple record chunks.
Merge duplicates (same legal issue), collate citations, and output a single
JSON array sorted by frequency (most cited first).

Input JSON arrays (concatenate then merge):
{all_issues}
"""
