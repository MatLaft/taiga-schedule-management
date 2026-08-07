#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/components/taiga-back"
PYTEST="${BACKEND_DIR}/.venv/bin/pytest"

if [ ! -x "${PYTEST}" ]; then
  echo "Error: no test environment was found at ${BACKEND_DIR}/.venv."
  echo "Install the backend dependencies before using this shortcut."
  exit 1
fi

cd "${BACKEND_DIR}"

exec "${PYTEST}" \
  tests/integration/test_schedule_inline_write_permissions.py \
  tests/integration/test_schedule_bulk_apply_dates.py \
  tests/integration/test_schedule_dependencies.py \
  tests/integration/test_bulk_create_api_reorder.py \
  -q
