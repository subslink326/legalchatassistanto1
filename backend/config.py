"""
Centralised runtime configuration.

Import `get_settings()` anywhere in the backend to access environment
variables with type safety and sensible defaults.
"""

from functools import lru_cache
from pathlib import Path
from pydantic import BaseSettings, Field, PostgresDsn, AnyUrl


class Settings(BaseSettings):
    # --- Database (Postgres) ---
    postgres_host: str = "postgres"
    postgres_port: int = 5432
    postgres_db: str = "legal_ai"
    postgres_user: str = "legal_ai"
    postgres_password: str = "legal_ai_pw"
    postgres_dsn: PostgresDsn | None = None  # Optional full DSN override

    # --- Vector store (Qdrant) ---
    qdrant_url: AnyUrl = Field(
        "http://qdrant:6333",
        description="Qdrant base URL inside the Docker network",
    )

    # --- Full‑text search (Elasticsearch) ---
    elastic_url: AnyUrl = Field(
        "http://elasticsearch:9200",
        description="Elasticsearch base URL inside the Docker network",
    )

    # --- LLM / Embeddings ---
    openai_api_key: str | None = None
    ollama_host: str | None = None  # in case you switch to local Llama 3

    # --- Misc ---
    debug: bool = True
    project_root: Path = Path(__file__).resolve().parents[1]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

    # ---------- Helper properties ----------
    @property
    def database_uri(self) -> str:
        """Return a full SQLAlchemy DSN."""
        if self.postgres_dsn:
            return str(self.postgres_dsn)

        return (
            f"postgresql+psycopg2://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )


@lru_cache
def get_settings() -> Settings:
    """FastAPI will call this via dependency injection; cached for speed."""
    return Settings()
