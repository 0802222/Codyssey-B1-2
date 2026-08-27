#!/usr/bin/env bash

set -euo pipefail

AGENT_HOME="${AGENT_HOME:-/home/user/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-$AGENT_HOME/logs}"
LOG_FILE="${LOG_FILE:-${AGENT_LOG_DIR}/monitor.log}"
APP_NAME="${APP_NAME:-agent-leak-app-x86}"
APP_PORT="${APP_PORT:-15034}"

CPU_THRESHOLD=20
MEM_THRESHOLD=10
DISK_THRESHOLD=80

PROC_CPU_THRESHOLD=80
PROC_RSS_THRESHOLD_KB=$((100 * 1024))

MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
MAX_FILES=10


timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

# 0. 경로 체크 (AGENT_HOME)
[[ -d "$AGENT_HOME" ]] || {
  echo "오류: AGENT_HOME 디렉터리가 없습니다: $AGENT_HOME" >&2
  exit 1
}

# 0. AGENT_LOG_DIR 생성, 쓰기 권한 체크
mkdir -p "$AGENT_LOG_DIR"

[[ -w "$AGENT_LOG_DIR" ]] || {
  echo "오류: 로그 디렉터리에 쓰기 권한이 없습니다: $AGENT_LOG_DIR" >&2
  exit 1
}

# 0. 파일 생성 실패 메시지
touch "$LOG_FILE" || {
  echo "오류: 로그 파일을 만들 수 없습니다: $LOG_FILE" >&2
  exit 1
}


# 1. 헬스 체크 - 프로세스 (APP_NAME, APP_PID)
APP_PID="$(pgrep -f "$APP_NAME" | head -n 1 || true)"

ps -p "$APP_PID" -o pid=,ppid=,stat=,etime=,%cpu=,%mem=,rss=,command=

if [ -z "${APP_PID:-}" ]; then
  echo "====== SYSTEM MONITOR RESULT ======"
  echo
  echo "[HEALTH CHECK]"
  echo "[ERROR] Process '${APP_NAME}' not running"
  exit 1
fi



# 2. 헬스 체크 - 포트 (APP_PORT)
# 포트번호는 숫자만 입력받음
[[ "$APP_PORT" =~ ^[0-9]+$ ]] &&
  (( APP_PORT >= 1 && APP_PORT <= 65535 )) || {
  echo "오류: 유효하지 않은 포트입니다: $APP_PORT" >&2
  exit 1
}

# 다른 프로세스가 사용중인지 검사 후 모니터링 결과 출력
if ! ss -ltn | grep -q ":${APP_PORT} "; then
  echo "====== SYSTEM MONITOR RESULT ======"
  echo
  echo "[HEALTH CHECK]"
  echo "[ERROR] Port ${APP_PORT} is not listening"
  exit 2
fi

# 대상 프로세스 자원·상태 수집
read -r APP_PPID APP_STATE APP_ELAPSED APP_CPU APP_MEM APP_RSS APP_COMMAND < <(
  ps -p "$APP_PID" -o ppid=,stat=,etime=,%cpu=,%mem=,rss=,args= |
  awk '{
    ppid=$1
    state=$2
    elapsed=$3
    cpu=$4
    mem=$5
    rss=$6
    $1=$2=$3=$4=$5=$6=""
    sub(/^ +/, "")
    print ppid, state, elapsed, cpu, mem, rss, $0
  }'
)

THREAD_COUNT="$(ps -L -p "$APP_PID" --no-headers | wc -l)"



# 3. 경고 체크 - 방화벽 활성화 여부
FIREWALL_WARNING=""
FIREWALL_STATUS="unknown"

if command -v ufw >/dev/null 2>&1; then
  UFW_STATUS="$(sudo /usr/sbin/ufw status 2>&1 || true)"

  if echo "$UFW_STATUS" | grep -q "Status: active"; then
    FIREWALL_STATUS="active"
  elif echo "$UFW_STATUS" | grep -qi "sudo"; then
    FIREWALL_STATUS="permission denied"
    FIREWALL_WARNING="[INFO] UFW status check failed (sudo permission required)"
  else
    FIREWALL_STATUS="inactive"
    FIREWALL_WARNING="[WARNING] UFW is inactive"
  fi

elif command -v firewall-cmd >/dev/null 2>&1; then
  FWD_STATUS="$(sudo firewall-cmd --state 2>&1 || true)"

  if echo "$FWD_STATUS" | grep -q "running"; then
    FIREWALL_STATUS="active"
  elif echo "$FWD_STATUS" | grep -qi "sudo"; then
    FIREWALL_STATUS="permission denied"
    FIREWALL_WARNING="[INFO] firewalld status check failed (sudo permission required)"
  else
    FIREWALL_STATUS="inactive"
    FIREWALL_WARNING="[WARNING] firewalld is inactive"
  fi

else
  FIREWALL_STATUS="not found"
  FIREWALL_WARNING="[WARNING] No firewall tool detected"
fi


if awk "BEGIN {exit !(${APP_CPU} > ${PROC_CPU_THRESHOLD})}"; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] Process CPU threshold exceeded (${APP_CPU}% > ${PROC_CPU_THRESHOLD}%)\n"
fi

if (( APP_RSS > PROC_RSS_THRESHOLD_KB )); then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] Process RSS threshold exceeded (${APP_RSS}KB > ${PROC_RSS_THRESHOLD_KB}KB)\n"
fi



# 4. 자원 수집 - CPU 사용률
CPU_IDLE_LINE="$(LANG=C top -bn1 | awk '/Cpu\(s\)/ {print}')"
CPU_IDLE="$(echo "${CPU_IDLE_LINE}" | awk -F',' '{for(i=1;i<=NF;i++){if($i ~ /id/){print $i}}}' | awk '{print $1}')"
CPU_USAGE="$(awk "BEGIN {printf \"%.1f\", 100 - ${CPU_IDLE}}")"

# 4. 자원 수집 - 메모리 사용률
MEM_USAGE="$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')"

# 4. 자원 수집 - 디스크 사용률 (/ 기준)
DISK_USAGE="$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')"



# 5. 임계값 경고
RESOURCE_WARNINGS=""

if awk "BEGIN {exit !(${CPU_USAGE} > ${CPU_THRESHOLD})}"; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] CPU threshold exceeded (${CPU_USAGE}% > ${CPU_THRESHOLD}%)\n"
fi

if awk "BEGIN {exit !(${MEM_USAGE} > ${MEM_THRESHOLD})}"; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] MEM threshold exceeded (${MEM_USAGE}% > ${MEM_THRESHOLD}%)\n"
fi

if awk "BEGIN {exit !(${DISK_USAGE} > ${DISK_THRESHOLD})}"; then
  RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] DISK threshold exceeded (${DISK_USAGE}% > ${DISK_THRESHOLD}%)\n"
fi



# 6. 로그 롤링 (최대 10MB / 10개 파일 유지)
if [ -f "${LOG_FILE}" ]; then
  CURRENT_SIZE="$(stat -c%s "${LOG_FILE}")"
  if [ "${CURRENT_SIZE}" -gt "${MAX_SIZE}" ]; then
    TS="$(date '+%Y%m%d%H%M%S')"
    mv "${LOG_FILE}" "${AGENT_LOG_DIR}/monitor.log.${TS}"
    touch "${LOG_FILE}"
  fi
fi



# 7. 로그 기록
printf '[%s] PID:%s PPID:%s STATE:%s ELAPSED:%s THREADS:%s ' \
  "$timestamp" "$APP_PID" "$APP_PPID" "$APP_STATE" "$APP_ELAPSED" "$THREAD_COUNT" >> "$LOG_FILE"

printf 'PROC_CPU:%s%% PROC_MEM:%s%% RSS:%sKB ' \
  "$APP_CPU" "$APP_MEM" "$APP_RSS" >> "$LOG_FILE"

printf 'SYS_CPU:%s%% SYS_MEM:%s%% DISK_USED:%s%% PORT:%s FIREWALL:%s CMD:%s\n' \
  "$CPU_USAGE" "$MEM_USAGE" "$DISK_USAGE" "$APP_PORT" "$FIREWALL_STATUS" "$APP_COMMAND" >> "$LOG_FILE"

mapfile -t LOG_ROLLED_FILES < <(ls -1t "${AGENT_LOG_DIR}"/monitor.log.* 2>/dev/null || true)
COUNT="${#LOG_ROLLED_FILES[@]}"

if [ "${COUNT}" -gt "${MAX_FILES}" ]; then
  for ((i=MAX_FILES; i<COUNT; i++)); do
    rm -f "${LOG_ROLLED_FILES[$i]}"
  done
fi



# 8. 콘솔 출력
echo "====== SYSTEM MONITOR RESULT ======"
echo
echo "[HEALTH CHECK]"
echo "Checking process '${APP_NAME}'... [OK] (PID: ${APP_PID})"
echo "Checking port ${APP_PORT}... [OK]"
echo
echo "[RESOURCE MONITORING]"
echo "Process state : ${APP_STATE}"
echo "Elapsed time  : ${APP_ELAPSED}"
echo "Thread count  : ${THREAD_COUNT}"
echo "Process CPU   : ${APP_CPU}%"
echo "Process MEM   : ${APP_MEM}%"
echo "Process RSS   : ${APP_RSS} KB"
echo
echo "System CPU    : ${CPU_USAGE}%"
echo "System MEM    : ${MEM_USAGE}%"
echo "DISK Used     : ${DISK_USAGE}%"
echo
echo "Firewall      : ${FIREWALL_STATUS}"
echo

if [ -n "$FIREWALL_WARNING" ]; then
  echo "$FIREWALL_WARNING"
fi

if [ -n "$RESOURCE_WARNINGS" ]; then
  printf "%b" "$RESOURCE_WARNINGS"
fi

echo
echo "[INFO] Log appended: $LOG_FILE"