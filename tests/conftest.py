import pytest
from fastapi.testclient import TestClient
from backend.app import app
from backend.config import settings

@pytest.fixture(autouse=True)
def disable_openai(monkeypatch):
    monkeypatch.setattr(settings, "openai_api_key", None)

@pytest.fixture
def client():
    return TestClient(app)
