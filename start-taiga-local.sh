#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAIGA_DOCKER_DIR="${ROOT_DIR}/taiga-docker"

COMPOSE_BASE_ARGS=(
  -f docker-compose.yml
  -f docker-compose.local.yml
)

COMPOSE_WITH_INITS_ARGS=(
  -f docker-compose.yml
  -f docker-compose-inits.yml
  -f docker-compose.local.yml
)

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Erro: comando '$1' nao encontrado."
    exit 1
  fi
}

compose_base() {
  docker compose "${COMPOSE_BASE_ARGS[@]}" "$@"
}

compose_with_inits() {
  docker compose "${COMPOSE_WITH_INITS_ARGS[@]}" "$@"
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

  echo "Erro: servico '${service}' nao ficou em execucao em ${timeout}s."
  compose_base logs --tail=80 "${service}" || true
  return 1
}

echo "[1/7] Inicializando submodulos..."
require_cmd git
git -C "${ROOT_DIR}" submodule sync --recursive
git -C "${ROOT_DIR}" submodule update --init --recursive

if [ ! -f "${ROOT_DIR}/taiga-back/settings/config.py" ]; then
  echo "[1/7] Criando taiga-back/settings/config.py a partir de docker/config.py..."
  cp "${ROOT_DIR}/taiga-back/docker/config.py" "${ROOT_DIR}/taiga-back/settings/config.py"
fi

require_cmd docker

if [ ! -d "${TAIGA_DOCKER_DIR}" ]; then
  echo "Erro: diretorio nao encontrado: ${TAIGA_DOCKER_DIR}"
  exit 1
fi

cd "${TAIGA_DOCKER_DIR}"

if [ ! -f "docker-compose.local.yml" ]; then
  echo "Erro: arquivo docker-compose.local.yml nao encontrado em ${TAIGA_DOCKER_DIR}"
  exit 1
fi

if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

# Compatibilidade: converte variaveis antigas para as esperadas no compose.
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

echo "[2/7] Parando e removendo containers atuais..."
compose_base down --remove-orphans

echo "[3/7] Gerando imagens locais (back/async/manage)..."
compose_with_inits build taiga-back taiga-async taiga-manage

echo "[4/7] Subindo servicos base do Taiga..."
compose_base up -d \
  taiga-db \
  taiga-async-rabbitmq \
  taiga-events-rabbitmq \
  taiga-events \
  taiga-protected \
  taiga-back \
  taiga-async \
  taiga-front

echo "[5/7] Aguardando servicos base..."
wait_for_running taiga-front 180
wait_for_running taiga-back 180
wait_for_running taiga-events 180
wait_for_running taiga-protected 180

echo "[6/7] Subindo gateway..."
compose_base up -d taiga-gateway

echo "[7/7] Servicos em execucao:"
compose_base ps
echo
echo "Taiga disponivel em: http://localhost:9000"
