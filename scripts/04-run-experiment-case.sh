#!/usr/bin/env bash
# 04-run-experiment-case.sh
# 사용법: bash scripts/04-run-experiment-case.sh <case-name>
# 예:    bash scripts/04-run-experiment-case.sh oom-before
#
# 동작:
#   1) 실험 시점 환경변수 스냅샷 저장
#   2) 앱과 05-monitor-app-resources.sh 실행, RUN_TIMEOUT 지정 시 시간 초과 후 강제 종료
#   3) 원본 로그(app, monitor, run) 저장
#   4) 06-summarize-evidence.sh 로 CSV·리포트 스니펫 생성

set -euo pipefail


# -----------------------------
# 0. 인자와 실행 계정 검증 (agentuser 로 실행)
# -----------------------------
CASE="${1:-}"
if [[ -z "$CASE" ]]; then
  echo "[ERROR] Usage: bash scripts/04-run-experiment-case.sh <case-name>" >&2
  echo "        example: bash scripts/04-run-experiment-case.sh oom-before" >&2
  exit 1
fi

if [[ "$(id -un)" != "agentuser" ]]; then
  echo "[ERROR] Run this as agentuser." >&2
  echo "        docker exec -it -u agentuser codyssey-b1-2 bash" >&2
  exit 1
fi

# 환경변수 로드
if [[ -f /workspace/runtime/agent.env ]]; then
  # shellcheck disable=SC1091
  set -a
  source /workspace/runtime/agent.env
  set +a
else
  echo "[ERROR] /workspace/runtime/agent.env not found. Run 02-provision-runtime.sh first." >&2
  exit 1
fi


# -----------------------------
# 1. 경로 설정
# -----------------------------
WORKSPACE="/workspace"
EVIDENCE_ROOT="$WORKSPACE/evidence"

TYPE="${CASE%-*}"      # oom-after → oom
PHASE="${CASE##*-}"    # oom-after → after

CASE_DIR="$EVIDENCE_ROOT/$TYPE"

APP_PATH="$WORKSPACE/bin/${APP_NAME:-agent-leak-app-x86}"
MONITOR_SCRIPT="$WORKSPACE/scripts/05-monitor-app-resources.sh"
COLLECT_SCRIPT="$WORKSPACE/scripts/06-summarize-evidence.sh"

mkdir -p "$CASE_DIR"

APP_LOG="$CASE_DIR/$PHASE-app.log"
MONITOR_STDOUT="$CASE_DIR/$PHASE-monitor-stdout.log"
MONITOR_LOG="$CASE_DIR/$PHASE-monitor.log"
ENV_SNAPSHOT="$CASE_DIR/$PHASE-env-snapshot.txt"
RUN_LOG="$CASE_DIR/$PHASE-run.log"

# 이 스크립트의 콘솔 출력도 증적으로 남긴다 (RUN_TIMEOUT 강제 종료 기록 포함)
: > "$RUN_LOG"
exec > >(tee -a "$RUN_LOG") 2>&1

echo "===== Experiment: $CASE ====="
echo "Started at   : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Evidence dir : $CASE_DIR"
echo


# -----------------------------
# 2. 환경변수 스냅샷 저장
# -----------------------------
{
  echo "# Experiment env snapshot"
  echo "# Case: $CASE"
  echo "# Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo
  env | grep -E '^(AGENT_|MEMORY_LIMIT|CPU_MAX_OCCUPY|MULTI_THREAD_ENABLE|APP_NAME)=' | sort
} > "$ENV_SNAPSHOT"

echo "[INFO] Env snapshot saved: $ENV_SNAPSHOT"


# -----------------------------
# 3. 이전 로그 초기화
# -----------------------------
: > "${AGENT_LOG_DIR}/agent_app.log" 2>/dev/null || true
: > "${AGENT_LOG_DIR}/monitor.log" 2>/dev/null || true


# -----------------------------
# 4. 앱과 모니터 실행
# -----------------------------
echo "[INFO] Starting app: $APP_PATH"
echo

PYTHONUNBUFFERED=1 "$APP_PATH" > "$APP_LOG" 2>&1 &
APP_PID=$!

echo "[INFO] App started (PID: $APP_PID)"

INTERVAL=1 bash "$MONITOR_SCRIPT" > "$MONITOR_STDOUT" 2>&1 &
MONITOR_PID=$!

echo "[INFO] Monitor started (PID: $MONITOR_PID, target app PID: $APP_PID)"


# 종료 시 모니터 & 앱 정리
cleanup() {
  if kill -0 "$MONITOR_PID" 2>/dev/null; then
    kill "$MONITOR_PID" 2>/dev/null || true
  fi

  if kill -0 "$APP_PID" 2>/dev/null; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM


# RUN_TIMEOUT(초)이 지정되면 그 시간 후 앱을 강제 종료 (Deadlock 등 무응답 대비)
TIMEOUT_PID=""
TIMEOUT_MARK="$(mktemp -u /tmp/run-timeout.XXXXXX)"
if [[ "${RUN_TIMEOUT:-0}" -gt 0 ]]; then
  ( sleep "$RUN_TIMEOUT"
    if kill -0 "$APP_PID" 2>/dev/null; then
      echo "[WARN] App still running after ${RUN_TIMEOUT}s. Killing (PID: $APP_PID)"
      touch "$TIMEOUT_MARK"
      kill "$APP_PID" 2>/dev/null || true
    fi ) &
  TIMEOUT_PID=$!
  echo "[INFO] Run timeout: ${RUN_TIMEOUT}s"
fi

# 앱 종료까지 대기
wait "$APP_PID" || true

# 타이머가 앱을 종료했으면 표시 파일이 남는다
EXIT_MODE="앱 자체 종료"
if [[ -n "$TIMEOUT_PID" ]]; then
  kill "$TIMEOUT_PID" 2>/dev/null || true
  if [[ -e "$TIMEOUT_MARK" ]]; then
    EXIT_MODE="RUN_TIMEOUT(${RUN_TIMEOUT}s) 강제 종료"
    rm -f "$TIMEOUT_MARK"
  fi
fi
echo "[INFO] Exit mode: $EXIT_MODE"

# 앱 종료를 monitor가 감지하고 마지막 상태를 기록할 시간
sleep 2

# 모니터가 살아 있으면 종료
cleanup


# -----------------------------
# 5. 원본 모니터 로그 복사
# -----------------------------
if [[ -f "${AGENT_LOG_DIR}/monitor.log" ]]; then
  cp "${AGENT_LOG_DIR}/monitor.log" "$MONITOR_LOG"
  echo "[INFO] Monitor log copied: $MONITOR_LOG"
else
  echo "[WARN] Monitor log not found: ${AGENT_LOG_DIR}/monitor.log"  
fi


# -----------------------------
# 6. CSV·리포트 스니펫 생성
# -----------------------------
bash "$COLLECT_SCRIPT" "$CASE"

echo
echo "===== Experiment complete: $CASE ====="
