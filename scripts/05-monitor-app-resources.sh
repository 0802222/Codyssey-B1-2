#!/usr/bin/env bash

set -euo pipefail    # 에러, 미정의 변수, 파이프 중간 실패 시 즉시 중단

AGENT_HOME="${AGENT_HOME:-/home/user/agent-app}"          # 앱 런타임 폴더
AGENT_LOG_DIR="${AGENT_LOG_DIR:-$AGENT_HOME/logs}"        # 로그 폴더
LOG_FILE="${LOG_FILE:-${AGENT_LOG_DIR}/monitor.log}"      # 관제 로그 파일
APP_NAME="${APP_NAME:-agent-leak-app-x86}"                # 감시할 프로세스 이름
APP_PORT="${APP_PORT:-15034}"                             # 감시할 포트

INTERVAL="${INTERVAL:-1}"    # 반복 간격 (초)
LOOP="${LOOP:-true}"         # true 면 계속 반복, 아니면 1회만 실행

CPU_THRESHOLD=20     # 시스템 CPU 경고 기준 (%)
MEM_THRESHOLD=10     # 시스템 메모리 경고 기준 (%)
DISK_THRESHOLD=80    # 디스크 경고 기준 (%)

PROC_CPU_THRESHOLD=80                    # 앱 프로세스 CPU 경고 기준 (%)
PROC_RSS_THRESHOLD_KB=$((100 * 1024))    # 앱 프로세스 RSS 경고 기준 (100MB를 KB로)

MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
MAX_FILES=10                    # 보관할 지난 로그 파일 최대 개수


# 관제 1회 실행: 상태 확인 → 자원 수집 → 경고 판단 → 로그 기록 → 화면 출력
monitor_once() {
  local timestamp                                  # 이번 회차 기록 시각
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  RESOURCE_WARNINGS=""                             # 이번 회차 경고 메시지 모음

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
  # 이름이 맞는 프로세스 중 RSS(6번째 열)가 가장 큰 것의 PID 선택 (script 래퍼가 아닌 실제 앱)
  APP_PID="$(ps aux | grep "$APP_NAME" | grep -v grep | sort -k6 -nr | awk 'NR==1{print $2}')"

  if [ -z "${APP_PID:-}" ]; then    # 못 찾으면 에러 출력 후 이번 회차 종료
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
  # ss -ltn: 대기(LISTEN) 중인 TCP 포트를 숫자로 출력
  if ! ss -ltn | grep -q ":${APP_PORT} "; then
    echo "====== SYSTEM MONITOR RESULT ======"
    echo
    echo "[HEALTH CHECK]"
    echo "[ERROR] Port ${APP_PORT} is not listening"
    return 2
  fi

  # 대상 프로세스 자원·상태 수집
  # ps 로 부모 PID, 상태, 실행 시간, CPU%, MEM%, RSS, 실행 명령을 한 줄로 받아 변수 7개에 나눠 담는다
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

  THREAD_COUNT="$(ps -L -p "$APP_PID" --no-headers | wc -l)"    # 스레드 수 (-L: 스레드별로 한 줄씩)



  # 3. 경고 체크 - 방화벽 활성화 여부
  FIREWALL_WARNING=""            # 방화벽 경고 메시지
  FIREWALL_STATUS="unknown"      # 방화벽 상태 기본값

  FIREWALL_STATUS_FILE="${AGENT_HOME}/firewall-status.txt"    # 03 스크립트가 기록한 상태 파일

  if [[ -r "$FIREWALL_STATUS_FILE" ]]; then
    FIREWALL_STATUS="$(cat "$FIREWALL_STATUS_FILE")"    # 파일 내용 = 상태 값

    if [[ "$FIREWALL_STATUS" == "inactive" ]]; then
      FIREWALL_WARNING="[WARNING] Firewall is inactive"
    elif [[ "$FIREWALL_STATUS" == "not found" ]]; then
      FIREWALL_WARNING="[WARNING] No firewall tool detected"
    fi
  else
    FIREWALL_STATUS="unknown"
    FIREWALL_WARNING="[INFO] Firewall status file not found (run 03-configure-firewall.sh as root first)"
  fi


  # 앱 CPU% 가 기준보다 크면 경고 추가 (소수 비교라 awk 사용)
  if awk "BEGIN {exit !(${APP_CPU} > ${PROC_CPU_THRESHOLD})}"; then
    RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] Process CPU threshold exceeded (${APP_CPU}% > ${PROC_CPU_THRESHOLD}%)\n"
  fi

  # 앱 RSS 가 기준보다 크면 경고 추가
  if (( APP_RSS > PROC_RSS_THRESHOLD_KB )); then
    RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] Process RSS threshold exceeded (${APP_RSS}KB > ${PROC_RSS_THRESHOLD_KB}KB)\n"
  fi



  # 4. 자원 수집 - CPU 사용률
  CPU_IDLE_LINE="$(LANG=C top -bn1 | awk '/Cpu\(s\)/ {print}')"                                          # top 에서 CPU 요약 줄만 추출
  CPU_IDLE="$(echo "${CPU_IDLE_LINE}" | awk -F',' '{for(i=1;i<=NF;i++){if($i ~ /id/){print $i}}}' | awk '{print $1}')"    # idle(유휴) 값만 추출
  CPU_USAGE="$(awk "BEGIN {printf \"%.1f\", 100 - ${CPU_IDLE}}")"                                       # 사용률 = 100 - 유휴

  # 4. 자원 수집 - 메모리 사용률
  MEM_USAGE="$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')"    # 사용량 / 전체 * 100

  # 4. 자원 수집 - 디스크 사용률 (/ 기준)
  DISK_USAGE="$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')"    # 5번째 열(Use%)에서 % 제거



  # 5. 임계값 경고
  # 시스템 CPU 기준 초과
  if awk "BEGIN {exit !(${CPU_USAGE} > ${CPU_THRESHOLD})}"; then
    RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] CPU threshold exceeded (${CPU_USAGE}% > ${CPU_THRESHOLD}%)\n"
  fi

  # 시스템 메모리 기준 초과
  if awk "BEGIN {exit !(${MEM_USAGE} > ${MEM_THRESHOLD})}"; then
    RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] MEM threshold exceeded (${MEM_USAGE}% > ${MEM_THRESHOLD}%)\n"
  fi

  # 디스크 기준 초과
  if awk "BEGIN {exit !(${DISK_USAGE} > ${DISK_THRESHOLD})}"; then
    RESOURCE_WARNINGS="${RESOURCE_WARNINGS}[WARNING] DISK threshold exceeded (${DISK_USAGE}% > ${DISK_THRESHOLD}%)\n"
  fi



  # 6. 로그 롤링 (최대 10MB / 10개 파일 유지)
  if [ -f "${LOG_FILE}" ]; then
    CURRENT_SIZE="$(stat -c%s "${LOG_FILE}")"                         # 현재 로그 파일 크기 (바이트)
    if [ "${CURRENT_SIZE}" -gt "${MAX_SIZE}" ]; then                  # 10MB 를 넘으면
      TS="$(date '+%Y%m%d%H%M%S')"                                    # 파일명에 붙일 시각
      mv "${LOG_FILE}" "${AGENT_LOG_DIR}/monitor.log.${TS}"           # 기존 로그를 이름 바꿔 보관
      touch "${LOG_FILE}"                                             # 새 빈 로그 파일 생성
    fi
  fi



  # 7. 로그 기록
  # 프로세스 정보 (시각, PID, 부모 PID, 상태, 실행 시간, 스레드 수)
  printf '[%s] PID:%s PPID:%s STATE:%s ELAPSED:%s THREADS:%s ' \
    "$timestamp" "$APP_PID" "$APP_PPID" "$APP_STATE" "$APP_ELAPSED" "$THREAD_COUNT" >> "$LOG_FILE"

  # 프로세스 자원 (CPU%, MEM%, RSS)
  printf 'PROC_CPU:%s%% PROC_MEM:%s%% RSS:%sKB ' \
    "$APP_CPU" "$APP_MEM" "$APP_RSS" >> "$LOG_FILE"

  # 시스템 자원, 포트, 방화벽, 실행 명령 (줄 끝)
  printf 'SYS_CPU:%s%% SYS_MEM:%s%% DISK_USED:%s%% PORT:%s FIREWALL:%s CMD:%s\n' \
    "$CPU_USAGE" "$MEM_USAGE" "$DISK_USAGE" "$APP_PORT" "$FIREWALL_STATUS" "$APP_COMMAND" >> "$LOG_FILE"

  mapfile -t LOG_ROLLED_FILES < <(ls -1t "${AGENT_LOG_DIR}"/monitor.log.* 2>/dev/null || true)    # 보관된 로그를 최신순으로 배열에 담기
  COUNT="${#LOG_ROLLED_FILES[@]}"                                                                # 보관 파일 개수

  # 10개를 넘으면 오래된 파일부터 삭제
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

  # 방화벽 경고가 있으면 출력
  if [ -n "$FIREWALL_WARNING" ]; then
    echo "$FIREWALL_WARNING"
  fi

  # 자원 경고가 있으면 출력 (%b: \n 을 줄바꿈으로 해석)
  if [ -n "$RESOURCE_WARNINGS" ]; then
    printf "%b" "$RESOURCE_WARNINGS"
  fi

  echo
  echo "[INFO] Log appended: $LOG_FILE"
}

# LOOP=true 면 INTERVAL 초마다 반복, 아니면 1회만 실행
if [[ "$LOOP" == "true" ]]; then
  echo "[INFO] Monitoring started: interval=${INTERVAL}s"
  echo "[INFO] Press Ctrl+C to stop."

  trap 'echo; echo "[INFO] Monitoring stopped."; exit 0' INT TERM    # Ctrl+C·종료 신호를 받으면 안내 후 정상 종료

  while true; do
    monitor_once || true    # 한 회차가 실패해도 관제는 계속
    sleep "$INTERVAL"       # 다음 회차까지 대기
  done
else
  monitor_once
fi
