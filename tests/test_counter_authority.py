import asyncio
from backend.modules.counter_authority.service import CounterRequest, generate_counter
def test_generate_counter_fallback_stub():
    resp = asyncio.run(generate_counter(
        CounterRequest(project_id="0"*32, draft="Error admitting hearsay"), None))
    assert "Government counsel" in resp.rebuttal
