#!/usr/bin/env bash
set -euo pipefail    # 에러, 미정의 변수, 파이프 중간 실패 시 즉시 중단

AGENT_PORT="${AGENT_PORT:-15034}"    # 앱이 사용하는 포트 (기본값 15034)

# root 가 아니면 중단 (ufw 는 root 권한 필요)
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[ERROR] Run this script as root." >&2
  exit 1
fi

# 포트가 1~65535 사이 숫자인지 확인
[[ "$AGENT_PORT" =~ ^[0-9]+$ ]] && (( AGENT_PORT >= 1 && AGENT_PORT <= 65535 )) || {
  echo "[ERROR] Invalid AGENT_PORT: $AGENT_PORT" >&2
  exit 1
}

# ufw 가 설치돼 있는지 확인
command -v ufw >/dev/null 2>&1 || {
  echo "[ERROR] ufw is not installed. Run 02-provision-runtime.sh first." >&2
  exit 1
}

ufw allow "${AGENT_PORT}/tcp"    # 앱 포트 TCP 허용 규칙 추가
ufw --force enable               # 확인 질문 없이 방화벽 활성화
ufw status numbered              # 규칙을 번호와 함께 출력
ufw status verbose               # 기본 정책까지 자세히 출력
# 05-monitor 가 읽는 방화벽 상태 파일 기록
# agentuser 는 ufw 상태를 직접 볼 수 없으므로 root 가 방화벽을 켠 뒤 결과를 파일로 남긴다
AGENT_HOME="${AGENT_HOME:-/workspace/runtime}"         # 상태 파일이 있는 경로
SERVICE_USER="${SERVICE_USER:-agentuser}"              # 파일 소유자 (관제 스크립트 실행 계정)
if ufw status | grep -q "Status: active"; then         # ufw 활성 여부 확인
  echo "active" > "$AGENT_HOME/firewall-status.txt"
else
  echo "inactive" > "$AGENT_HOME/firewall-status.txt"
fi
chown "$SERVICE_USER:$SERVICE_USER" "$AGENT_HOME/firewall-status.txt"
