#!/usr/bin/env bash

set -euo pipefail

AGENT_HOME="${AGENT_HOME:-/home/user/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-$AGENT_HOME/logs}"
LOG_FILE="${LOG_FILE:-${AGENT_LOG_DIR}/monitor.log}"
APP_NAME="${APP_NAME:-agent-leak-app-x86}"
APP_PORT="${APP_PORT:-15034}"

INTERVAL="${INTERVAL:-1}"
LOOP="${LOOP:-true}"

CPU_THRESHOLD=20
MEM_THRESHOLD=10
DISK_THRESHOLD=80

# 프로세스 CPU 경고 임계치는 미션 환경변수(CPU_MAX_OCCUPY)와 일치시킨다.
PROC_CPU_THRESHOLD="${CPU_MAX_OCCUPY:-80}"
PROC_RSS_THRESHOLD_KB=$((100 * 1024))

MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
MAX_FILES=10

# 순간 CPU 사용률 계산용 상태 (샘플 간 델타를 누적 보관)
CLK_TCK="$(getconf CLK_TCK 2>/dev/null || echo 100)"
CPU_SAMPLE_PID=""
CPU_SAMPLE_JIFFIES=""
CPU_SAMPLE_UPTIME=""
PROC_CPU_INST=""


# ps의 %cpu는 "프로세스 시작 이후 누적 평균"이므로 CPU 과점유 구간을 식별할 수 없다.
# /proc/<pid>/stat의 utime+stime을 직전 샘플과 비교하여 순간 사용률(코어 1개 기준 %)을 구한다.
sample_proc_cpu() {
  local pid="$1"
  local stat_rest now_jiffies now_uptime delta_jiffies

  PROC_CPU_INST=""
  [[ -r "/proc/$pid/stat" ]] || return 1

  # comm 필드에 공백·괄호가 들어갈 수 있으므로 마지막 ')' 뒤부터 파싱한다. (이후 12=utime, 13=stime)
  stat_rest="$(</proc/"$pid"/stat)"
  stat_rest="${stat_rest##*') '}"
  # shellcheck disable=SC2086
  set -- $stat_rest
  [[ $# -ge 13 ]] || return 1

  now_jiffies=$(( ${12} + ${13} ))
  now_uptime="$(awk '{print $1}' /proc/uptime)"

  if [[ "$CPU_SAMPLE_PID" == "$pid" && -n "$CPU_SAMPLE_JIFFIES" ]]; then
    delta_jiffies=$(( now_jiffies - CPU_SAMPLE_JIFFIES ))
    PROC_CPU_INST="$(
      awk -v dj="$delta_jiffies" -v t0="$CPU_SAMPLE_UPTIME" -v t1="$now_uptime" -v hz="$CLK_TCK" '
        BEGIN {
          dt = t1 - t0
          if (dt <= 0 || dj < 0) { print "0.0" }
          else { printf "%.1f", (dj / hz) / dt * 100 }
        }'
    )"
  fi

  CPU_SAMPLE_PID="$pid"
  CPU_SAMPLE_JIFFIES="$now_jiffies"
  CPU_SAMPLE_UPTIME="$now_uptime"
}


monitor_once() {
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  RESOURCE_WARNINGS=""

  # 0. 경로 체크 (AGENT_HOME)
  [[ -d "$AGENT_HOME" ]] || {
    echo "오류: AGENT_HOME 디렉터리가 없습니다: $AGENT_HOME" >&2
    return 1
  }

  # 0. AGENT_LOG_DIR 생성, 쓰기 권한 체크
  mkdir -p "$AGENT_LOG_DIR"

  [[ -w "$AGENT_LOG_DIR" ]] || {
    echo "오류: 로그 디렉터리에 쓰기 권한이 없습니다: $AGENT_LOG_DIR" >&2
    return 1
  }

  # 0. 파일 생성 실패 메시지
  touch "$LOG_FILE" || {
    echo "오류: 로그 파일을 만들 수 없습니다: $LOG_FILE" >&2
    return 1
  }


  # 1. 헬스 체크 - 프로세스 (APP_NAME, APP_PID)
  APP_PID="$(ps aux | grep "$APP_NAME" | grep -v grep | sort -k6 -nr | awk 'NR==1{print $2}')"

  if [ -z "${APP_PID:-}" ]; then
    echo "====== SYSTEM MONITOR RESULT ======"
    echo
    echo "[HEALTH CHECK]"
    echo "[ERROR] Process '${APP_NAME}' not running"
    return 1
  fi



  # 2. 헬스 체크 - 포트 (APP_PORT)
  # 포트번호는 숫자만 입력받음
  [[ "$APP_PORT" =~ ^[0-9]+$ ]] &&
    (( APP_PORT >= 1 && APP_PORT <= 65535 )) || {
    echo "오류: 유효하지 않은 포트입니다: $APP_PORT" >&2
    return 1
  }

  # 다른 프로세스가 사용중인지 검사 후 모니터링 결과 출력
  if ! ss -ltn | grep -q ":${APP_PORT} "; then
    echo "====== SYSTEM MONITOR RESULT ======"
    echo
    echo "[HEALTH CHECK]"
    echo "[ERROR] Port ${APP_PORT} is not listening"
    return 2
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

  # ps의 %cpu는 누적 평균이므로 보조 지표로만 남기고, 로그에는 순간 사용률을 기록한다.
  APP_CPU_AVG="$APP_CPU"
  sample_proc_cpu "$APP_PID" || true
  if [[ -n "$PROC_CPU_INST" ]]; then
    APP_CPU="$PROC_CPU_INST"
  fi



  # 3. 경고 체크 - 방화벽 활성화 여부
  FIREWALL_WARNING=""
  FIREWALL_STATUS="unknown"

  FIREWALL_STATUS_FILE="${AGENT_HOME}/firewall-status.txt"

  if [[ -r "$FIREWALL_STATUS_FILE" ]]; then
    FIREWALL_STATUS="$(cat "$FIREWALL_STATUS_FILE")"

    if [[ "$FIREWALL_STATUS" == "inactive" ]]; then
      FIREWALL_WARNING="[WARNING] Firewall is inactive"
    elif [[ "$FIREWALL_STATUS" == "not found" ]]; then
      FIREWALL_WARNING="[WARNING] No firewall tool detected"
    fi
  else
    FIREWALL_STATUS="unknown"
    FIREWALL_WARNING="[INFO] Firewall status file not found (run provision.sh as root first)"
  fi


  if awk "BEGIN {exit !(${APP_CPU} > ${PROC_CPU_THRESHOLD})}"; then
    RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] Process CPU threshold exceeded (${APP_CPU}% > CPU_MAX_OCCUPY ${PROC_CPU_THRESHOLD}%)\n"
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

  printf 'PROC_CPU:%s%% PROC_CPU_AVG:%s%% PROC_MEM:%s%% RSS:%sKB ' \
    "$APP_CPU" "$APP_CPU_AVG" "$APP_MEM" "$APP_RSS" >> "$LOG_FILE"

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
  echo "Process CPU   : ${APP_CPU}% (instant, 1 core=100%)"
  echo "Process CPU평균: ${APP_CPU_AVG}% (since start)"
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
}

if [[ "$LOOP" == "true" ]]; then
  echo "[INFO] Monitoring started: interval=${INTERVAL}s"
  echo "[INFO] Press Ctrl+C to stop."

  trap 'echo; echo "[INFO] Monitoring stopped."; exit 0' INT TERM

  while true; do
    monitor_once || true
    sleep "$INTERVAL"
  done
else
  monitor_once
fi