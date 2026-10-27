#!/usr/bin/env bash
# 06-summarize-evidence.sh
# 사용법: bash scripts/06-summarize-evidence.sh <case-name>   (컨테이너 안에서 실행, GNU awk·date 필요)
# 예:    bash scripts/06-summarize-evidence.sh oom-before
#
# 04-run-experiment-case.sh 가 남긴 원본 로그로 아래 파일을 (다시) 만든다. 실험을 다시 돌리지 않아도 된다.
#   - <phase>-timeseries.csv    : monitor.log 시계열
#   - <phase>-report-snippet.md : 리포트 인용용 요약

set -euo pipefail

CASE="${1:-}"
if [[ -z "$CASE" ]]; then
  echo "[ERROR] Usage: bash scripts/06-summarize-evidence.sh <case-name>" >&2
  exit 1
fi


# -----------------------------
# 1. 경로 설정
# -----------------------------
WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TYPE="${CASE%-*}"      # oom-after → oom
PHASE="${CASE##*-}"    # oom-after → after

CASE_DIR="$WORKSPACE/evidence/$TYPE"

APP_LOG="$CASE_DIR/$PHASE-app.log"
MONITOR_LOG="$CASE_DIR/$PHASE-monitor.log"
ENV_SNAPSHOT="$CASE_DIR/$PHASE-env-snapshot.txt"
RUN_LOG="$CASE_DIR/$PHASE-run.log"
TIMESERIES_CSV="$CASE_DIR/$PHASE-timeseries.csv"
REPORT_SNIPPET="$CASE_DIR/$PHASE-report-snippet.md"

if [[ ! -f "$ENV_SNAPSHOT" ]]; then
  echo "[ERROR] $ENV_SNAPSHOT not found. Run 04-run-experiment-case.sh $CASE first." >&2
  exit 1
fi


# -----------------------------
# 2. 시계열 CSV 추출
# -----------------------------
if [[ -f "$MONITOR_LOG" ]]; then
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
    ' "$MONITOR_LOG"
  } > "$TIMESERIES_CSV"
  ROWS=$(($(wc -l < "$TIMESERIES_CSV") - 1))
  echo "[INFO] Timeseries CSV: $TIMESERIES_CSV ($ROWS rows)"
fi


# -----------------------------
# 3. 리포트 스니펫 생성
# -----------------------------
STARTED_AT=$(grep -m 1 '^# Timestamp:' "$ENV_SNAPSHOT" | sed 's/^# Timestamp: //')
EXIT_MODE=$(grep -m 1 'Exit mode:' "$RUN_LOG" 2>/dev/null | sed 's/.*Exit mode: //' || true)
EXIT_CODE=$(grep -m 1 'Exit code:' "$RUN_LOG" 2>/dev/null | sed 's/.*Exit code: //' || true)    # 예: 143 (SIGTERM)
RUN_LINES=$(grep -E '^\[(INFO|WARN)\] (App started|Run timeout|App still running|Exit mode|Exit code)' "$RUN_LOG" 2>/dev/null || true)

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

cat > "$REPORT_SNIPPET" <<SNIPPET
# 실험 스니펫: $CASE

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: ${STARTED_AT:-기록 없음}
- 케이스: \`$CASE\`
- 생존 시간: ${SURVIVAL:-측정 불가}
- 종료 방식: ${EXIT_MODE:-기록 없음}
- 종료 코드: ${EXIT_CODE:-기록 없음}

### 환경변수

\`\`\`
$(grep -v '^#' "$ENV_SNAPSHOT")
\`\`\`

## 실행 스크립트 출력

\`\`\`sh
$RUN_LINES
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

CSV 원본: [\`$PHASE-timeseries.csv\`](./$PHASE-timeseries.csv)


## 파일 목록

\`\`\`
$(ls -la "$CASE_DIR" | tail -n +2)
\`\`\`
SNIPPET

echo "[INFO] Report snippet: $REPORT_SNIPPET"
