#!/usr/bin/env bash
set -euo pipefail

# Dockerfile
cat > Dockerfile << 'DOCKER'
# Backend container
FROM python:3.10-slim

WORKDIR /app
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml poetry.lock* /app/
RUN pip install poetry && poetry config virtualenvs.create false && poetry install --no-dev

COPY . /app

EXPOSE 8000
CMD ["uvicorn", "backend.app:app", "--host", "0.0.0.0", "--port", "8000"]
DOCKER

# docker-compose.yaml
cat > docker-compose.yaml << 'YAML'
version: "3.9"
services:
  backend:
    build: .
    ports:
      - "8000:8000"
    env_file: .env
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
  elastic:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.13.2
    environment:
      - discovery.type=single-node
    ports:
      - "9200:9200"
YAML

# GitHub Actions CI
mkdir -p .github/workflows
cat > .github/workflows/ci.yaml << 'YAML'
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: user
          POSTGRES_PASSWORD: pass
          POSTGRES_DB: legal_ai
        ports:
          - 5432:5432
        options: >-
          --health-cmd="pg_isready -U user"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
      qdrant:
        image: qdrant/qdrant:latest
        ports: ["6333:6333"]
      elastic:
        image: docker.elastic.co/elasticsearch/elasticsearch:8.13.2
        env:
          discovery.type: single-node
        ports: ["9200:9200"]
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: 3.10
      - name: Install dependencies
        run: |
          pip install poetry
          poetry install
      - name: Wait for services
        run: sleep 20
      - name: Init DB
        run: |
          python - << 'PY'
          import asyncio
          from backend.db.database import init_models
          asyncio.run(init_models())
          PY
      - name: Run tests
        run: pytest -q
YAML

echo "✅ Phase 22 scaffold (Docker & CI) created."
