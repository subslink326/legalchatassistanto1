#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until pg_isready -h postgres -U postgres; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "PostgreSQL is up - continuing"

# Wait for Qdrant to be ready
echo "Waiting for Qdrant..."
until curl -s http://qdrant:6333/healthz; do
  echo "Qdrant is unavailable - sleeping"
  sleep 2
done
echo "Qdrant is up - continuing"

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch..."
until curl -s http://elastic:9200; do
  echo "Elasticsearch is unavailable - sleeping"
  sleep 2
done
echo "Elasticsearch is up - continuing"

# Apply database migrations
echo "Applying database migrations..."
python scripts/migrate.py upgrade

# Execute the command passed to docker run
exec "$@"