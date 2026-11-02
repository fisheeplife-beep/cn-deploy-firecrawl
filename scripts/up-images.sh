#!/usr/bin/env bash
# Start image-based lab compose (127.0.0.1:3002).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/compose/.env}"
COMPOSE="$ROOT/compose/docker-compose.images.yml"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — copy from compose/.env.example and set POSTGRES_PASSWORD" >&2
  exit 1
fi
docker compose -f "$COMPOSE" --env-file "$ENV_FILE" pull
docker compose -f "$COMPOSE" --env-file "$ENV_FILE" up -d
docker compose -f "$COMPOSE" --env-file "$ENV_FILE" ps -a
