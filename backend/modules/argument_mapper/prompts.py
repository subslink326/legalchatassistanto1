"""
LLM prompt templates – tweak as needed.
"""
EXTRACT_ELEMENTS = """
You are an appellate lawyer. Break the following ISSUE STATEMENT into its
constituent legal elements / prongs required to prevail, under the specified
jurisdiction.  Return ONLY a bullet list – no commentary.

ISSUE: "{issue}"
JURISDICTION: "{jurisdiction}"
"""
