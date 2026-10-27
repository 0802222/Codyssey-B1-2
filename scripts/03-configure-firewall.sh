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
  echo "[ERROR] ufw is not installed. Run 02-provision-runtime.sh first." >&2
  exit 1
}

ufw allow "${AGENT_PORT}/tcp"
ufw --force enable
ufw status numbered
ufw status verbose
# 05-monitor 가 읽는 방화벽 상태 파일 갱신
# 02-provision-runtime.sh 는 방화벽을 켜기 전에 상태를 기록하므로, 활성화 후 여기서 다시 기록한다
AGENT_HOME="${AGENT_HOME:-/workspace/runtime}"         # 상태 파일이 있는 경로
SERVICE_USER="${SERVICE_USER:-agentuser}"              # 파일 소유자 (관제 스크립트 실행 계정)
if ufw status | grep -q "Status: active"; then         # ufw 활성 여부 확인
  echo "active" > "$AGENT_HOME/firewall-status.txt"
else
  echo "inactive" > "$AGENT_HOME/firewall-status.txt"
fi
chown "$SERVICE_USER:$SERVICE_USER" "$AGENT_HOME/firewall-status.txt"
