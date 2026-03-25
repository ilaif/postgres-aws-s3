#!/bin/bash
set -e

# Install aws_s3 extension on every startup (idempotent).
# Runs in background after postgres is ready, then stays quiet.
_install_extensions() {
  until pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}" -q 2>/dev/null; do
    sleep 1
  done
  psql -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}" \
    -c "CREATE EXTENSION IF NOT EXISTS plpython3u; CREATE EXTENSION IF NOT EXISTS aws_s3 CASCADE;" \
    2>/dev/null || true
}

_install_extensions &

# Hand off to the official postgres entrypoint as PID 1
exec /usr/local/bin/docker-entrypoint.sh "$@"
