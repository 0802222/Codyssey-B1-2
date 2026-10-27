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

set -euo pipefail    # 에러, 미정의 변수, 파이프 중간 실패 시 즉시 중단


# -----------------------------
# 0. 인자와 실행 계정 검증 (agentuser 로 실행)
# -----------------------------
CASE="${1:-}"    # 첫 번째 인자 = 케이스 이름 (예: oom-before)
if [[ -z "$CASE" ]]; then    # 인자가 없으면 사용법 출력 후 중단
  echo "[ERROR] Usage: bash scripts/04-run-experiment-case.sh <case-name>" >&2
  echo "        example: bash scripts/04-run-experiment-case.sh oom-before" >&2
  exit 1
fi

if [[ "$(id -un)" != "agentuser" ]]; then    # 현재 계정이 agentuser 가 아니면 중단
  echo "[ERROR] Run this as agentuser." >&2
  echo "        docker exec -it -u agentuser codyssey-b1-2-lab bash" >&2
  exit 1
fi

# 환경변수 로드
if [[ -f /workspace/runtime/agent.env ]]; then
  # shellcheck disable=SC1091
  set -a                                 # 이후 정의되는 변수를 자동으로 export
  source /workspace/runtime/agent.env    # 02 에서 만든 환경변수 파일 읽기
  set +a                                 # 자동 export 끄기
else
  echo "[ERROR] /workspace/runtime/agent.env not found. Run 02-provision-runtime.sh first." >&2
  exit 1
fi


# -----------------------------
# 1. 경로 설정
# -----------------------------
WORKSPACE="/workspace"                  # 컨테이너 안 레포 경로
EVIDENCE_ROOT="$WORKSPACE/evidence"     # 증적 저장 최상위 폴더

TYPE="${CASE%-*}"      # oom-after → oom
PHASE="${CASE##*-}"    # oom-after → after

CASE_DIR="$EVIDENCE_ROOT/$TYPE"    # 케이스별 증적 폴더 (예: evidence/oom)

APP_PATH="$WORKSPACE/bin/${APP_NAME:-agent-leak-app-x86}"            # 앱 바이너리 경로
MONITOR_SCRIPT="$WORKSPACE/scripts/05-monitor-app-resources.sh"      # 관제 스크립트
COLLECT_SCRIPT="$WORKSPACE/scripts/06-summarize-evidence.sh"         # 증적 요약 스크립트

mkdir -p "$CASE_DIR"    # 증적 폴더 생성

APP_LOG="$CASE_DIR/$PHASE-app.log"                    # 앱 콘솔 출력
MONITOR_STDOUT="$CASE_DIR/$PHASE-monitor-stdout.log"  # 관제 스크립트 콘솔 출력
MONITOR_LOG="$CASE_DIR/$PHASE-monitor.log"            # 관제 로그 원본 복사본
ENV_SNAPSHOT="$CASE_DIR/$PHASE-env-snapshot.txt"      # 실험 시점 환경변수
RUN_LOG="$CASE_DIR/$PHASE-run.log"                    # 이 스크립트의 실행 기록

# 이 스크립트의 콘솔 출력도 증적으로 남긴다 (RUN_TIMEOUT 강제 종료 기록 포함)
: > "$RUN_LOG"                          # 실행 로그 파일 비우기
exec > >(tee -a "$RUN_LOG") 2>&1        # 이후 모든 출력을 화면과 파일에 동시에 기록

echo "===== Experiment: $CASE ====="
echo "Started at   : $(date '+%Y-%m-%d %H:%M:%S %Z')"    # 시작 시각
echo "Evidence dir : $CASE_DIR"
echo


# -----------------------------
# 2. 환경변수 스냅샷 저장
# -----------------------------
# 중괄호 안의 출력을 한 번에 스냅샷 파일로 저장
{
  echo "# Experiment env snapshot"
  echo "# Case: $CASE"
  echo "# Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo
  env | grep -E '^(AGENT_|MEMORY_LIMIT|CPU_MAX_OCCUPY|MULTI_THREAD_ENABLE|APP_NAME)=' | sort    # 실험 관련 변수만 골라 정렬
} > "$ENV_SNAPSHOT"

echo "[INFO] Env snapshot saved: $ENV_SNAPSHOT"


# -----------------------------
# 3. 이전 로그 초기화
# -----------------------------
: > "${AGENT_LOG_DIR}/agent_app.log" 2>/dev/null || true    # 이전 앱 로그 비우기 (실패해도 계속)
: > "${AGENT_LOG_DIR}/monitor.log" 2>/dev/null || true      # 이전 관제 로그 비우기 (실패해도 계속)


# -----------------------------
# 4. 앱과 모니터 실행
# -----------------------------
echo "[INFO] Starting app: $APP_PATH"
echo

# 앱은 stdout이 파일이면 print 출력을 버퍼에 모아 두는데, 자가 종료(SIGTERM/SIGKILL) 시
# 이 버퍼가 비워지지 않아 "WATCHDOG ... (SIGTERM)", "SELF-TERMINATED" 배너가 사라진다.
# script 로 가상 터미널(pty)을 붙여 줄 단위 출력이 되게 하고, -e 로 앱의 종료 코드를 그대로 돌려받는다.
#   -q: 시작/종료 안내문 생략, -e: 자식 종료 코드 반환, -f: 매 출력마다 flush, -c: 실행할 명령
#   typescript 파일은 /dev/null 로 버리고, script 의 stdout 을 앱 로그 파일로 받는다.
script -qefc "exec $APP_PATH" /dev/null > "$APP_LOG" 2>&1 &
APP_PID=$!    # script 프로세스 PID (앱은 이 프로세스의 자식)

echo "[INFO] App started (PID: $APP_PID)"

INTERVAL=1 bash "$MONITOR_SCRIPT" > "$MONITOR_STDOUT" 2>&1 &    # 1초 간격 관제를 백그라운드로 실행
MONITOR_PID=$!    # 관제 스크립트 PID

echo "[INFO] Monitor started (PID: $MONITOR_PID, target app PID: $APP_PID)"


# 종료 시 모니터 & 앱 정리
cleanup() {
  if kill -0 "$MONITOR_PID" 2>/dev/null; then    # 관제 스크립트가 살아 있으면
    kill "$MONITOR_PID" 2>/dev/null || true      # 종료
  fi

  if kill -0 "$APP_PID" 2>/dev/null; then
    pkill -TERM -f "^$APP_PATH" 2>/dev/null || true    # pty 안의 실제 앱 프로세스 종료
    wait "$APP_PID" 2>/dev/null || true                 # script 프로세스 회수
  fi
}
trap cleanup EXIT INT TERM    # 정상 종료, Ctrl+C, 종료 신호 때 항상 정리 실행


# RUN_TIMEOUT(초)이 지정되면 그 시간 후 앱을 강제 종료 (Deadlock 등 무응답 대비)
TIMEOUT_PID=""                                          # 타이머 프로세스 PID (없으면 빈 값)
TIMEOUT_MARK="$(mktemp -u /tmp/run-timeout.XXXXXX)"     # 타이머가 종료시켰는지 표시할 파일 이름
if [[ "${RUN_TIMEOUT:-0}" -gt 0 ]]; then
  # 백그라운드 타이머: 시간이 지나도 앱이 살아 있으면 표시 파일을 만들고 종료시킨다
  ( sleep "$RUN_TIMEOUT"
    if kill -0 "$APP_PID" 2>/dev/null; then
      echo "[WARN] App still running after ${RUN_TIMEOUT}s. Killing (PID: $APP_PID)"
      touch "$TIMEOUT_MARK"
      # script 가 아닌 앱 본체에 SIGTERM 을 보내야 종료 코드(143)가 그대로 기록된다
      pkill -TERM -f "^$APP_PATH" 2>/dev/null || true
    fi ) &
  TIMEOUT_PID=$!    # 타이머 PID 저장
  echo "[INFO] Run timeout: ${RUN_TIMEOUT}s"
fi

# 앱 종료까지 대기하고 종료 코드 저장
APP_EXIT=0                              # 정상 종료면 0 유지
wait "$APP_PID" || APP_EXIT=$?          # 0이 아니면 종료 코드 저장 (set -e 로 중단되지 않게 || 사용)

# 128보다 크면 시그널로 종료된 것 (예: 143 = 128 + 15 SIGTERM, 137 = 128 + 9 SIGKILL)
EXIT_DESC="$APP_EXIT"
if (( APP_EXIT > 128 )); then
  EXIT_DESC="$APP_EXIT (SIG$(kill -l $((APP_EXIT - 128))))"    # 시그널 번호를 이름으로 변환
fi

# pty 출력은 줄 끝이 \r\n 이므로 \r 을 제거해 일반 텍스트 로그로 정리
sed -i 's/\r$//' "$APP_LOG"

# 타이머가 앱을 종료했으면 표시 파일이 남는다
EXIT_MODE="앱 자체 종료"
if [[ -n "$TIMEOUT_PID" ]]; then
  kill "$TIMEOUT_PID" 2>/dev/null || true    # 남아 있는 타이머 정리
  if [[ -e "$TIMEOUT_MARK" ]]; then          # 표시 파일이 있으면 타이머가 종료시킨 것
    EXIT_MODE="RUN_TIMEOUT(${RUN_TIMEOUT}s) 강제 종료"
    rm -f "$TIMEOUT_MARK"                    # 표시 파일 삭제
  fi
fi
echo "[INFO] Exit mode: $EXIT_MODE"
echo "[INFO] Exit code: $EXIT_DESC"

# 앱 종료를 monitor가 감지하고 마지막 상태를 기록할 시간
sleep 2

# 모니터가 살아 있으면 종료
cleanup


# -----------------------------
# 5. 원본 모니터 로그 복사
# -----------------------------
if [[ -f "${AGENT_LOG_DIR}/monitor.log" ]]; then
  cp "${AGENT_LOG_DIR}/monitor.log" "$MONITOR_LOG"    # 런타임 로그를 증적 폴더로 복사
  echo "[INFO] Monitor log copied: $MONITOR_LOG"
else
  echo "[WARN] Monitor log not found: ${AGENT_LOG_DIR}/monitor.log"  
fi


# -----------------------------
# 6. CSV·리포트 스니펫 생성
# -----------------------------
bash "$COLLECT_SCRIPT" "$CASE"    # 06 스크립트로 CSV와 요약 파일 생성

echo
echo "===== Experiment complete: $CASE ====="
