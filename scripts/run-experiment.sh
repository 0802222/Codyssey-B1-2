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
MONITOR_LOG="$CASE_DIR/$PHASE-monitor.log"
ENV_SNAPSHOT="$CASE_DIR/$PHASE-env-snapshot.txt"
TIMESERIES_CSV="$CASE_DIR/$PHASE-timeseries.csv"
REPORT_SNIPPET="$CASE_DIR/$PHASE-report-snippet.md"
CMD_SNAPSHOT="$CASE_DIR/$PHASE-cmd-snapshot.txt"

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

"$APP_PATH" > "$APP_LOG" 2>&1 &
LAUNCHER_PID=$!

echo "[INFO] App launcher started (PID: $LAUNCHER_PID)"

# 앱은 실제 에이전트를 자식 프로세스로 띄운다.
# $! 는 런처 PID이므로, monitor.sh와 동일한 기준(RSS 최대)으로 관측 대상 PID를 찾는다.
APP_PID=""
for _ in $(seq 1 10); do
  APP_PID="$(ps aux | grep "${APP_NAME:-agent-leak-app-x86}" | grep -v grep | sort -k6 -nr | awk 'NR==1{print $2}')"
  [[ -n "$APP_PID" && "$APP_PID" != "$LAUNCHER_PID" ]] && break
  sleep 1
done
APP_PID="${APP_PID:-$LAUNCHER_PID}"

echo "[INFO] Target agent process resolved (PID: $APP_PID)"

INTERVAL=1 bash "$MONITOR_SCRIPT" > "$MONITOR_STDOUT" 2>&1 &
MONITOR_PID=$!

echo "[INFO] Monitor started (PID: $MONITOR_PID, target app PID: $APP_PID)"


# -----------------------------
# 4-1. Linux 명령어 출력 증적 수집 (리포트 템플릿의 "Linux 명령어 출력" 항목)
# -----------------------------
{
  echo "# Linux command evidence"
  echo "# Case: $CASE / App PID: $APP_PID"
  echo
} > "$CMD_SNAPSHOT"

(
  while kill -0 "$APP_PID" 2>/dev/null; do
    {
      echo "===== [$(date '+%Y-%m-%d %H:%M:%S')] ====="
      echo "--- ps -ef | grep agent-leak-app ---"
      ps -ef | grep "[a]gent-leak-app" || true
      echo "--- ps -p $APP_PID -o pid,ppid,stat,etime,%cpu,%mem,rss,cmd ---"
      ps -p "$APP_PID" -o pid,ppid,stat,etime,%cpu,%mem,rss,cmd 2>/dev/null || true
      echo "--- top -bn1 -p $APP_PID ---"
      top -bn1 -p "$APP_PID" 2>/dev/null | tail -n 5 || true
      echo "--- ps -L -p $APP_PID -o pid,tid,stat,%cpu,%mem,etime,comm ---"
      ps -L -p "$APP_PID" -o pid,tid,stat,%cpu,%mem,etime,comm 2>/dev/null || true
      echo
    } >> "$CMD_SNAPSHOT"
    sleep 3
  done
) &
SNAPSHOT_PID=$!

echo "[INFO] Command snapshot collector started (PID: $SNAPSHOT_PID)"


# 종료 시 모니터 정리
cleanup() {
  if kill -0 "$MONITOR_PID" 2>/dev/null; then
    kill "$MONITOR_PID" 2>/dev/null || true
    wait "$MONITOR_PID" 2>/dev/null || true
  fi
  if kill -0 "$SNAPSHOT_PID" 2>/dev/null; then
    kill "$SNAPSHOT_PID" 2>/dev/null || true
    wait "$SNAPSHOT_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM


# 앱 종료까지 대기 (런처가 끝나면 에이전트도 종료된 것)
wait "$LAUNCHER_PID" || true

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
# 6. 시계열 CSV 추출
# -----------------------------
if [[ -f "$MONITOR_LOG" ]]; then
  {
    echo "timestamp,proc_cpu,proc_cpu_avg,proc_mem,rss_kb,sys_cpu,sys_mem,threads,state"
    gawk '
      match($0, /\[([^]]+)\]/, ts) &&
      match($0, /PROC_CPU:([0-9.]+)%/, pc) &&
      match($0, /PROC_MEM:([0-9.]+)%/, pm) &&
      match($0, /RSS:([0-9]+)KB/, rss) &&
      match($0, /SYS_CPU:([0-9.]+)%/, sc) &&
      match($0, /SYS_MEM:([0-9.]+)%/, sm) &&
      match($0, /THREADS:([0-9]+)/, th) &&
      match($0, /STATE:([^ ]+)/, st) {
        avg = ""
        if (match($0, /PROC_CPU_AVG:([0-9.]+)%/, pa)) { avg = pa[1] }
        print ts[1] "," pc[1] "," avg "," pm[1] "," rss[1] "," sc[1] "," sm[1] "," th[1] "," st[1]
      }
    ' "$MONITOR_LOG"
  } > "$TIMESERIES_CSV"
  ROWS=$(($(wc -l < "$TIMESERIES_CSV") - 1))
  echo "[INFO] Timeseries CSV: $TIMESERIES_CSV ($ROWS rows)"
fi


# -----------------------------
# 7. 리포트 스니펫 생성
# -----------------------------
APP_LAST_LINES=$(tail -n 20 "$APP_LOG" 2>/dev/null || echo "(no app log)")
MON_FIRST=$(head -n 3 "$MONITOR_LOG" 2>/dev/null || echo "")
MON_LAST=$(tail -n 3 "$MONITOR_LOG" 2>/dev/null || echo "")

# 생존 시간 (모니터 로그의 첫/끝 타임스탬프 차이)
SURVIVAL=""
if [[ -f "$MONITOR_LOG" ]]; then
  FIRST_TS=$(grep -oE '\[[0-9-]+ [0-9:]+\]' "$MONITOR_LOG" | head -n 1 | tr -d '[]')
  LAST_TS=$(grep -oE '\[[0-9-]+ [0-9:]+\]' "$MONITOR_LOG" | tail -n 1 | tr -d '[]')
  if [[ -n "$FIRST_TS" && -n "$LAST_TS" ]]; then
    FIRST_EPOCH=$(date -d "$FIRST_TS" +%s 2>/dev/null || echo 0)
    LAST_EPOCH=$(date -d "$LAST_TS" +%s 2>/dev/null || echo 0)
    if (( LAST_EPOCH > FIRST_EPOCH )); then
      SURVIVAL="$((LAST_EPOCH - FIRST_EPOCH)) seconds ($FIRST_TS ~ $LAST_TS)"
    fi
  fi
fi

# 관측 피크값 (리포트의 "관측된 최대 CPU 사용률" 등에 인용)
PEAK_SUMMARY="(측정 불가)"
if [[ -s "$TIMESERIES_CSV" ]]; then
  PEAK_SUMMARY="$(
    awk -F',' 'NR > 1 {
      if ($2 + 0 > maxcpu) { maxcpu = $2 + 0; maxcpu_ts = $1 }
      if ($5 + 0 > maxrss) { maxrss = $5 + 0; maxrss_ts = $1 }
      if ($8 + 0 > maxth)  { maxth  = $8 + 0 }
      rows++
    }
    END {
      if (rows == 0) { print "(측정 불가)"; exit }
      printf "- 최대 프로세스 CPU: **%.1f%%** (%s)\n", maxcpu, maxcpu_ts
      printf "- 최대 RSS: **%d KB** (~%.1f MB, %s)\n", maxrss, maxrss / 1024, maxrss_ts
      printf "- 최대 스레드 수: **%d**\n", maxth
      printf "- 수집 행수: %d\n", rows
    }' "$TIMESERIES_CSV"
  )"
fi

cat > "$REPORT_SNIPPET" <<EOF
# 실험 스니펫: $CASE

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: $(date '+%Y-%m-%d %H:%M:%S %Z')
- 케이스: \`$CASE\`
- 생존 시간: ${SURVIVAL:-측정 불가}

## 관측 피크값

$PEAK_SUMMARY

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

## Linux 명령어 출력 (마지막 스냅샷)

\`\`\`
$(tail -n 20 "$CMD_SNAPSHOT" 2>/dev/null || echo "(no command snapshot)")
\`\`\`

전체 스냅샷: [\`$PHASE-cmd-snapshot.txt\`](./$PHASE-cmd-snapshot.txt)

## 시계열 데이터

CSV 원본: [\`$PHASE-timeseries.csv\`](./$PHASE-timeseries.csv)


## 파일 목록

\`\`\`
$(ls -la "$CASE_DIR" | tail -n +2)
\`\`\`
EOF

echo "[INFO] Report snippet: $REPORT_SNIPPET"


# -----------------------------
# 8. 완료 요약
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