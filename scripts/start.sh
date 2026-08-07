#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAIGA_DOCKER_DIR="${ROOT_DIR}/infrastructure/taiga-docker"
TAIGA_BACK_DIR="${ROOT_DIR}/components/taiga-back"
ENV_FILE="${ROOT_DIR}/.env"

COMPOSE_BASE_ARGS=(
  -f docker-compose.yml
  -f docker-compose.local.yml
)

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' was not found."
    exit 1
  fi
}

compose_base() {
  docker compose "${COMPOSE_BASE_ARGS[@]}" "$@"
}

wait_for_running() {
  local service="$1"
  local timeout="${2:-180}"
  local elapsed=0

  while [ "${elapsed}" -lt "${timeout}" ]; do
    if compose_base ps --services --status running | grep -qx "${service}"; then
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  echo "Error: service '${service}' did not start within ${timeout}s."
  compose_base logs --tail=80 "${service}" || true
  return 1
}

echo "[1/7] Initializing submodules..."
require_cmd git
git -C "${ROOT_DIR}" submodule sync --recursive

missing_submodules=()
while IFS= read -r submodule_path; do
  [ -n "${submodule_path}" ] && missing_submodules+=("${submodule_path}")
done < <(git -C "${ROOT_DIR}" submodule status --recursive | awk '/^-/{print $2}')

if [ "${#missing_submodules[@]}" -gt 0 ]; then
  echo "[1/7] Initializing missing submodules: ${missing_submodules[*]}"
  git -C "${ROOT_DIR}" submodule update --init --recursive -- "${missing_submodules[@]}"
else
  echo "[1/7] Submodules are ready; keeping their current checkouts."
fi

if [ ! -f "${TAIGA_BACK_DIR}/settings/config.py" ]; then
  echo "[1/7] Creating components/taiga-back/settings/config.py from docker/config.py..."
  cp "${TAIGA_BACK_DIR}/docker/config.py" "${TAIGA_BACK_DIR}/settings/config.py"
fi

require_cmd docker

if [ ! -d "${TAIGA_DOCKER_DIR}" ]; then
  echo "Error: directory not found: ${TAIGA_DOCKER_DIR}"
  exit 1
fi

cd "${TAIGA_DOCKER_DIR}"

if [ ! -f "docker-compose.local.yml" ]; then
  echo "Error: docker-compose.local.yml was not found in ${TAIGA_DOCKER_DIR}"
  exit 1
fi

if [ -f "${ENV_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${ENV_FILE}"
  set +a
fi

# Compatibility: map legacy variables to the names expected by Compose.
export SECRET_KEY="${SECRET_KEY:-${TAIGA_SECRET_KEY:-insecure-secret-key-change-in-production}}"
export RABBITMQ_USER="${RABBITMQ_USER:-${TAIGA_ASYNC_RABBITMQ_USER:-${TAIGA_EVENTS_RABBITMQ_USER:-taiga}}}"
export RABBITMQ_PASS="${RABBITMQ_PASS:-${TAIGA_ASYNC_RABBITMQ_PASS:-${TAIGA_EVENTS_RABBITMQ_PASS:-taiga}}}"
export RABBITMQ_VHOST="${RABBITMQ_VHOST:-${TAIGA_ASYNC_RABBITMQ_VHOST:-${TAIGA_EVENTS_RABBITMQ_VHOST:-taiga}}}"
export EMAIL_BACKEND="${EMAIL_BACKEND:-console}"
export EMAIL_DEFAULT_FROM="${EMAIL_DEFAULT_FROM:-changeme@example.com}"
export EMAIL_USE_TLS="${EMAIL_USE_TLS:-False}"
export EMAIL_USE_SSL="${EMAIL_USE_SSL:-False}"
export EMAIL_HOST="${EMAIL_HOST:-smtp.host.example.com}"
export EMAIL_PORT="${EMAIL_PORT:-587}"
export EMAIL_HOST_USER="${EMAIL_HOST_USER:-user}"
export EMAIL_HOST_PASSWORD="${EMAIL_HOST_PASSWORD:-password}"
export ENABLE_TELEMETRY="${ENABLE_TELEMETRY:-False}"
export ATTACHMENTS_MAX_AGE="${ATTACHMENTS_MAX_AGE:-360}"

echo "[2/7] Stopping and removing current containers..."
compose_base down --remove-orphans

echo "[3/7] Building local backend and async images..."
compose_base build taiga-back taiga-async

echo "[4/7] Starting core Taiga services..."
compose_base up -d \
  taiga-db \
  taiga-async-rabbitmq \
  taiga-events-rabbitmq \
  taiga-events \
  taiga-protected \
  taiga-back \
  taiga-async \
  taiga-front

echo "[5/7] Waiting for core services..."
wait_for_running taiga-front 180
wait_for_running taiga-back 180
wait_for_running taiga-events 180
wait_for_running taiga-protected 180

echo "[6/7] Starting the gateway..."
compose_base up -d taiga-gateway

echo "[7/7] Running services:"
compose_base ps
echo
echo "Taiga is available at: http://localhost:9000"
