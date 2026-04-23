#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env.local"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

mkdir -p "${ROOT_DIR}/data/config/plugin-conf.d"

render_template() {
  local src="$1"
  local dest="$2"

  if command -v envsubst >/dev/null 2>&1; then
    envsubst < "${src}" > "${dest}"
  else
    cp "${src}" "${dest}"
    sed -i "s|\${MUNIN_NODE_NAME}|${MUNIN_NODE_NAME:-docker-host}|g" "${dest}"
    sed -i "s|\${MUNIN_NODE_ADDRESS}|${MUNIN_NODE_ADDRESS:-host.docker.internal}|g" "${dest}"
    sed -i "s|\${MUNIN_ALLOWED_CIDR}|${MUNIN_ALLOWED_CIDR:-172.20.0.0/16}|g" "${dest}"
    sed -i "s|\${EXCLUDE_CONTAINER_NAME}|${EXCLUDE_CONTAINER_NAME:-runner}|g" "${dest}"
  fi
}

render_template "${ROOT_DIR}/templates/config/munin.conf" "${ROOT_DIR}/data/config/munin.conf"
render_template "${ROOT_DIR}/templates/config/apache2_munin.conf" "${ROOT_DIR}/data/config/apache2_munin.conf"
cp "${ROOT_DIR}/templates/config/apache2_apache2.conf" "${ROOT_DIR}/data/config/apache2_apache2.conf"
cp "${ROOT_DIR}/templates/config/ports.conf" "${ROOT_DIR}/data/config/ports.conf"
render_template "${ROOT_DIR}/templates/config/plugin-conf.d/docker" "${ROOT_DIR}/data/config/plugin-conf.d/docker"

echo "infra-munin layout initialized."
