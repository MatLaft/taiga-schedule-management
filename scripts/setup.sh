#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE="${ROOT_DIR}/.env.example"
BACKEND_CONFIG="${ROOT_DIR}/components/taiga-back/settings/config.py"
BACKEND_CONFIG_EXAMPLE="${ROOT_DIR}/components/taiga-back/docker/config.py"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git was not found."
  exit 1
fi

echo "[1/3] Initializing submodules..."
git -C "${ROOT_DIR}" submodule sync --recursive
git -C "${ROOT_DIR}" submodule update --init --recursive

if [ ! -f "${ENV_FILE}" ]; then
  echo "[2/3] Creating the local .env file from .env.example..."
  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
else
  echo "[2/3] Keeping the existing local .env file."
fi

if [ ! -f "${BACKEND_CONFIG}" ]; then
  echo "[3/3] Creating the local backend configuration..."
  cp "${BACKEND_CONFIG_EXAMPLE}" "${BACKEND_CONFIG}"
else
  echo "[3/3] Keeping the existing local backend configuration."
fi

echo
echo "Setup complete."
echo "Review ${ENV_FILE}, then run ./scripts/start.sh."
