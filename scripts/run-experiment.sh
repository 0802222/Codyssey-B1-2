#!/usr/bin/env bash
# run-experiment.sh
# 사용법: bash scripts/run-experiment.sh <case-name>
# 예:    bash scripts/run-experiment.sh oom-before
#
# 동작:
#   1) 실험 시점 환경변수 스냅샷 저장
#   2) monitor.sh 백그라운드 실행 (앱 종료 시 자동 정지)
#   3) 앱 실행 (포그라운드, 종료까지 대기)
#   4) 로그 수집 + 시계열 CSV 추출 + 리포트 스니펫 생성

set -euo pipefail


# -----------------------------
# 0. 인자와 실행 계정 검증 (agentuser 로 실행)
# -----------------------------
CASE="${1:-}"
if [[ -z "$CASE" ]]; then
  echo "[ERROR] Usage: bash scripts/run-experiment.sh <case-name>" >&2
  echo "        example: bash scripts/run-experiment.sh oom-before" >&2
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
  echo "[ERROR] /workspace/runtime/agent.env not found. Run provision.sh first." >&2
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
MONITOR_SCRIPT="$WORKSPACE/scripts/monitor.sh"

mkdir -p "$CASE_DIR"

APP_LOG="$CASE_DIR/$PHASE-app.log"
MONITOR_STDOUT="$CASE_DIR/$PHASE-monitor-stdout.log"
ENV_SNAPSHOT="$CASE_DIR/$PHASE-env-snapshot.txt"
TIMESERIES_CSV="$CASE_DIR/$PHASE-timeseries.csv"
REPORT_SNIPPET="$CASE_DIR/$PHASE-report-snippet.md"

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
# 4. 모니터 백그라운드 실행
# -----------------------------
INTERVAL=1 bash "$MONITOR_SCRIPT" > "$MONITOR_STDOUT" 2>&1 &
MONITOR_PID=$!
echo "[INFO] Monitor started (PID: $MONITOR_PID)"


# 종료 시 정리 (Ctrl+C 등)
cleanup() {
  if kill -0 "$MONITOR_PID" 2>/dev/null; then
    kill "$MONITOR_PID" 2>/dev/null || true
    wait "$MONITOR_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM


# -----------------------------
# 5. 앱 실행 (종료까지 대기)
# -----------------------------
echo "[INFO] Starting app: $APP_PATH"
echo
"$APP_PATH" 2>&1 | tee "$APP_LOG" || true

# monitor.sh가 앱 종료를 감지하고 자체 종료할 시간 여유
sleep 2

# 모니터가 아직 살아있으면 정리
if kill -0 "$MONITOR_PID" 2>/dev/null; then
  kill "$MONITOR_PID" 2>/dev/null || true
  wait "$MONITOR_PID" 2>/dev/null || true
fi


# -----------------------------
# 6. 원본 모니터 로그 복사
# -----------------------------
if [[ -f "${AGENT_LOG_DIR}/monitor.log" ]]; then
  cp "${AGENT_LOG_DIR}/monitor.log" "$CASE_DIR/monitor.log"
  echo "[INFO] Monitor log copied: $CASE_DIR/monitor.log"
fi


# -----------------------------
# 7. 시계열 CSV 추출
# -----------------------------
if [[ -f "$CASE_DIR/monitor.log" ]]; then
  {
    echo "timestamp,proc_cpu,proc_mem,rss_kb,sys_cpu,sys_mem,threads,state"
    gawk '
      match($0, /\[([^]]+)\]/, ts) &&
      match($0, /PROC_CPU:([0-9.]+)%/, pc) &&
      match($0, /PROC_MEM:([0-9.]+)%/, pm) &&
      match($0, /RSS:([0-9]+)KB/, rss) &&
      match($0, /SYS_CPU:([0-9.]+)%/, sc) &&
      match($0, /SYS_MEM:([0-9.]+)%/, sm) &&
      match($0, /THREADS:([0-9]+)/, th) &&
      match($0, /STATE:([^ ]+)/, st) {
        print ts[1] "," pc[1] "," pm[1] "," rss[1] "," sc[1] "," sm[1] "," th[1] "," st[1]
      }
    ' "$CASE_DIR/monitor.log"
  } > "$TIMESERIES_CSV"
  ROWS=$(($(wc -l < "$TIMESERIES_CSV") - 1))
  echo "[INFO] Timeseries CSV: $TIMESERIES_CSV ($ROWS rows)"
fi


# -----------------------------
# 8. 리포트 스니펫 생성
# -----------------------------
APP_LAST_LINES=$(tail -n 20 "$APP_LOG" 2>/dev/null || echo "(no app log)")
MON_FIRST=$(head -n 3 "$CASE_DIR/monitor.log" 2>/dev/null || echo "")
MON_LAST=$(tail -n 3 "$CASE_DIR/monitor.log" 2>/dev/null || echo "")

# 생존 시간 (모니터 로그의 첫/끝 타임스탬프 차이)
SURVIVAL=""
if [[ -f "$CASE_DIR/monitor.log" ]]; then
  FIRST_TS=$(grep -oE '\[[0-9-]+ [0-9:]+\]' "$CASE_DIR/monitor.log" | head -n 1 | tr -d '[]')
  LAST_TS=$(grep -oE '\[[0-9-]+ [0-9:]+\]' "$CASE_DIR/monitor.log" | tail -n 1 | tr -d '[]')
  if [[ -n "$FIRST_TS" && -n "$LAST_TS" ]]; then
    FIRST_EPOCH=$(date -d "$FIRST_TS" +%s 2>/dev/null || echo 0)
    LAST_EPOCH=$(date -d "$LAST_TS" +%s 2>/dev/null || echo 0)
    if (( LAST_EPOCH > FIRST_EPOCH )); then
      SURVIVAL="$((LAST_EPOCH - FIRST_EPOCH)) seconds ($FIRST_TS ~ $LAST_TS)"
    fi
  fi
fi

cat > "$REPORT_SNIPPET" <<EOF
# 실험 스니펫: $CASE

_이 파일은 리포트 작성 시 관측 사실 인용에 사용하세요._
_"3. Root Cause Analysis"와 "4. Workaround & Verification"은 직접 작성이 필요합니다._

## 실험 조건

- 실험 시각: $(date '+%Y-%m-%d %H:%M:%S %Z')
- 케이스: \`$CASE\`
- 생존 시간: ${SURVIVAL:-측정 불가}

### 환경변수

\`\`\`
$(cat "$ENV_SNAPSHOT" | grep -v '^#')
\`\`\`

## 앱 로그 (마지막 20줄)

\`\`\`
$APP_LAST_LINES
\`\`\`

## 모니터 로그 발췌

**시작 부근:**
\`\`\`
$MON_FIRST
\`\`\`

**종료 부근:**
\`\`\`
$MON_LAST
\`\`\`

## 시계열 데이터

CSV 원본: [\`timeseries.csv\`](./timeseries.csv)

CSV를 스프레드시트로 열어 RSS, PROC_CPU 그래프를 리포트에 첨부하세요.

## 파일 목록

\`\`\`
$(ls -la "$CASE_DIR" | tail -n +2)
\`\`\`
EOF

echo "[INFO] Report snippet: $REPORT_SNIPPET"


# -----------------------------
# 9. 완료 요약
# -----------------------------
echo
echo "===== Experiment complete: $CASE ====="
echo "Files saved to $CASE_DIR:"
ls -la "$CASE_DIR"
echo
echo "Next steps:"
echo "  1) $REPORT_SNIPPET 을 열어 리포트에 인용"
echo "  2) $TIMESERIES_CSV 를 그래프로 시각화"
echo "  3) reports/*.md 의 원인 분석/조치 섹션 작성"