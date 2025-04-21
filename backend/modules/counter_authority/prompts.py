"""
Counter‑Authority LLM prompt templates.
"""
REBUTTAL_TEMPLATE = """
You are government counsel drafting a rebuttal to the defense arguments below.
Provide a concise, persuasive response citing any negative or contrary authority.

Defense Draft:
\"\"\"{draft}\"\"\"
"""
