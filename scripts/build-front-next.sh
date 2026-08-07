#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEXT_DIR="${ROOT_DIR}/components/taiga-front-next"
FRONT_DIR="${ROOT_DIR}/components/taiga-front"
NEXT_ELEMENTS="${NEXT_DIR}/dist/elements/elements.js"
FRONT_ELEMENTS="${FRONT_DIR}/elements.js"
NVMRC_PATH="${NEXT_DIR}/.nvmrc"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' was not found."
    exit 1
  fi
}

load_nvm() {
  if command -v nvm >/dev/null 2>&1; then
    return
  fi

  export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"

  if [ -s "${NVM_DIR}/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "${NVM_DIR}/nvm.sh"
    return
  fi

  if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "/opt/homebrew/opt/nvm/nvm.sh"
    return
  fi

  if [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "/usr/local/opt/nvm/nvm.sh"
    return
  fi

  echo "Error: nvm was not found. Install nvm to use the project's Node version."
  exit 1
}

if [ ! -d "${NEXT_DIR}" ]; then
  echo "Error: directory not found: ${NEXT_DIR}"
  exit 1
fi

if [ ! -d "${FRONT_DIR}" ]; then
  echo "Error: directory not found: ${FRONT_DIR}"
  exit 1
fi

if [ ! -d "${NEXT_DIR}/node_modules" ]; then
  echo "Error: dependencies are missing from ${NEXT_DIR}/node_modules."
  echo "Run: cd ${NEXT_DIR} && npm install"
  exit 1
fi

if [ ! -f "${NEXT_DIR}/node_modules/@angular/cli/package.json" ]; then
  echo "Error: @angular/cli was not found in ${NEXT_DIR}/node_modules."
  echo "The development dependencies are not installed."
  echo "Run: cd ${NEXT_DIR} && npm ci --include=dev"
  exit 1
fi

if [ ! -f "${NVMRC_PATH}" ]; then
  echo "Error: file not found: ${NVMRC_PATH}"
  exit 1
fi

REQUIRED_NODE_VERSION="$(tr -d '[:space:]' < "${NVMRC_PATH}")"
if [ -z "${REQUIRED_NODE_VERSION}" ]; then
  echo "Error: ${NVMRC_PATH} is empty."
  exit 1
fi

echo "[1/4] Selecting Node ${REQUIRED_NODE_VERSION} through nvm..."
load_nvm

if ! nvm use "${REQUIRED_NODE_VERSION}" >/dev/null 2>&1; then
  echo "Node ${REQUIRED_NODE_VERSION} is not installed locally. Installing it with nvm..."
  nvm install "${REQUIRED_NODE_VERSION}"
  nvm use "${REQUIRED_NODE_VERSION}" >/dev/null
fi

require_cmd npm

echo "[2/4] Building the taiga-front-next web component..."
(
  cd "${NEXT_DIR}"
  npm run build:elements
  npm run pack:elements
)

if [ ! -f "${NEXT_ELEMENTS}" ]; then
  echo "Error: expected output was not generated: ${NEXT_ELEMENTS}"
  exit 1
fi

echo "[3/4] Copying elements.js to taiga-front..."
cp "${NEXT_ELEMENTS}" "${FRONT_ELEMENTS}"

echo "[4/4] Build complete."
echo "Active Node version: $(node -v)"
ls -lh "${NEXT_ELEMENTS}" "${FRONT_ELEMENTS}"
