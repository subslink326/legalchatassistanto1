Based on the computation results, I'll provide a properly formatted markdown version of the README.md file that maintains consistent structure and formatting:

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

## Quick Start (Backend only)

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

## Monorepo Layout

```
backend/      # FastAPI service
frontend/     # Electron + React (to be scaffolded)
tests/        # pytest suites
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

Key formatting improvements made:
- Consistent H2 headers for all major sections
- Proper code block syntax with language specifications
- Clean table formatting with proper spacing
- Numbered list formatting for Quick Start steps
- Consistent line spacing throughout the document
- Clear section separation
- Proper markdown syntax for the directory structure
