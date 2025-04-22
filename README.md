# 📚 Legal Assistant AI – Post‑Trial Appeals Workbench

Full‑stack desktop app for uploading discovery / transcripts, chunking them for
LLM retrieval, and drafting post‑trial motions & appellate briefs with six
research‑and‑drafting intelligence modules.

## Tech Stack
| Layer | Tech |
|-------|------|
| Desktop shell | **Electron 29** |
| SPA | **React 18 + Vite + TypeScript** |
| API | **FastAPI 0.111** |
| DB | **Postgres 16**, **Qdrant** (vectors), **Elasticsearch 8** (BM25) |
| LLM helpers | LangChain, Llama‑Index |

## Quick Start

### With Docker (Recommended)

1. Copy environment file and edit variables
   ```bash
   cp .env.example .env && $EDITOR .env
   ```

2. Run with Docker Compose
   ```bash
   docker-compose up -d
   ```

3. Access the API at http://localhost:8000/docs

### Backend Only (Development)

1. Install Python deps
   ```bash
   pipx install poetry   # or pip install --user poetry
   poetry install
   ```

2. Copy env
   ```bash
   cp .env.example .env  &&  $EDITOR .env
   ```

3. Run API
   ```bash
   poetry run uvicorn backend.app:app --reload
   ```

Browse Swagger UI at http://localhost:8000/docs

## Database Management

The application uses Alembic for database migrations:

```bash
# Create a new migration (after model changes)
python scripts/migrate.py create "description_of_changes"

# Apply migrations to latest version
python scripts/migrate.py upgrade

# Show migration history
python scripts/migrate.py history

# Rollback one migration
python scripts/migrate.py downgrade
```

## Monorepo Layout

```
backend/      # FastAPI service
├── app.py    # Application factory
├── config.py # Environment configuration
├── core/     # Core utilities
├── db/       # Database models and connections
├── modules/  # Intelligence modules
└── routers/  # API endpoints
frontend/     # Electron + React
├── electron/ # Desktop application shell
└── ui/       # React application
migrations/   # Database migrations
scripts/      # Utility scripts
tests/        # Pytest suites
```

## Contributing

```bash
pre-commit install
```

Create a feature branch:
```bash
git checkout -b feature/argument-mapper
```

Push & open PR.

## License

MIT License © 2025 Your Name