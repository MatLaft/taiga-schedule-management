#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEXT_DIR="${ROOT_DIR}/taiga-front-next"
FRONT_DIR="${ROOT_DIR}/taiga-front"
NEXT_ELEMENTS="${NEXT_DIR}/dist/elements/elements.js"
FRONT_ELEMENTS="${FRONT_DIR}/elements.js"
NVMRC_PATH="${NEXT_DIR}/.nvmrc"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Erro: comando '$1' nao encontrado."
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

  echo "Erro: nvm nao encontrado. Instale nvm para usar a versao de Node do projeto."
  exit 1
}

if [ ! -d "${NEXT_DIR}" ]; then
  echo "Erro: diretorio nao encontrado: ${NEXT_DIR}"
  exit 1
fi

if [ ! -d "${FRONT_DIR}" ]; then
  echo "Erro: diretorio nao encontrado: ${FRONT_DIR}"
  exit 1
fi

if [ ! -d "${NEXT_DIR}/node_modules" ]; then
  echo "Erro: dependencias ausentes em ${NEXT_DIR}/node_modules."
  echo "Rode: cd ${NEXT_DIR} && npm install"
  exit 1
fi

if [ ! -f "${NVMRC_PATH}" ]; then
  echo "Erro: arquivo nao encontrado: ${NVMRC_PATH}"
  exit 1
fi

REQUIRED_NODE_VERSION="$(tr -d '[:space:]' < "${NVMRC_PATH}")"
if [ -z "${REQUIRED_NODE_VERSION}" ]; then
  echo "Erro: ${NVMRC_PATH} esta vazio."
  exit 1
fi

echo "[1/4] Selecionando Node ${REQUIRED_NODE_VERSION} via nvm..."
load_nvm

if ! nvm use "${REQUIRED_NODE_VERSION}" >/dev/null 2>&1; then
  echo "Node ${REQUIRED_NODE_VERSION} nao encontrado localmente. Instalando com nvm..."
  nvm install "${REQUIRED_NODE_VERSION}"
  nvm use "${REQUIRED_NODE_VERSION}" >/dev/null
fi

require_cmd npm

echo "[2/4] Compilando webcomponent em taiga-front-next..."
(
  cd "${NEXT_DIR}"
  npm run build:elements
  npm run pack:elements
)

if [ ! -f "${NEXT_ELEMENTS}" ]; then
  echo "Erro: arquivo nao gerado: ${NEXT_ELEMENTS}"
  exit 1
fi

echo "[3/4] Copiando elements.js para taiga-front..."
cp "${NEXT_ELEMENTS}" "${FRONT_ELEMENTS}"

echo "[4/4] Concluido."
echo "Node em uso: $(node -v)"
ls -lh "${NEXT_ELEMENTS}" "${FRONT_ELEMENTS}"
