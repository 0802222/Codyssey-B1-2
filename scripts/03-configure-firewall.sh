#!/usr/bin/env bash
set -euo pipefail

AGENT_PORT="${AGENT_PORT:-15034}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "[ERROR] Run this script as root." >&2
  exit 1
fi

[[ "$AGENT_PORT" =~ ^[0-9]+$ ]] && (( AGENT_PORT >= 1 && AGENT_PORT <= 65535 )) || {
  echo "[ERROR] Invalid AGENT_PORT: $AGENT_PORT" >&2
  exit 1
}

command -v ufw >/dev/null 2>&1 || {
  echo "[ERROR] ufw is not installed. Run provision.sh first." >&2
  exit 1
}

ufw allow "${AGENT_PORT}/tcp"
ufw enable
ufw status numbered
ufw status verbose