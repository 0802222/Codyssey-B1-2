#!/usr/bin/env bash
# 06-summarize-evidence.sh
# 사용법: bash scripts/06-summarize-evidence.sh <case-name>   (컨테이너 안에서 실행, GNU awk·date 필요)
# 예:    bash scripts/06-summarize-evidence.sh oom-before
#
# 04-run-experiment-case.sh 가 남긴 원본 로그로 아래 파일을 (다시) 만든다. 실험을 다시 돌리지 않아도 된다.
#   - <phase>-timeseries.csv    : monitor.log 시계열
#   - <phase>-report-snippet.md : 리포트 인용용 요약 (07 의 ps/top 스냅샷 첫·마지막 회차 포함)

set -euo pipefail    # 에러, 미정의 변수, 파이프 중간 실패 시 즉시 중단

CASE="${1:-}"    # 첫 번째 인자 = 케이스 이름 (예: oom-before)
# 인자가 없으면 사용법 출력 후 중단
if [[ -z "$CASE" ]]; then
  echo "[ERROR] Usage: bash scripts/06-summarize-evidence.sh <case-name>" >&2
  exit 1
fi


# -----------------------------
# 1. 경로 설정
# -----------------------------
WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"    # 레포 루트 절대경로 (scripts 폴더의 상위)

TYPE="${CASE%-*}"      # oom-after → oom
PHASE="${CASE##*-}"    # oom-after → after

CASE_DIR="$WORKSPACE/evidence/$TYPE"    # 케이스별 증적 폴더

APP_LOG="$CASE_DIR/$PHASE-app.log"                  # 앱 콘솔 출력
MONITOR_LOG="$CASE_DIR/$PHASE-monitor.log"          # 관제 로그
ENV_SNAPSHOT="$CASE_DIR/$PHASE-env-snapshot.txt"    # 실험 시점 환경변수
RUN_LOG="$CASE_DIR/$PHASE-run.log"                  # 04 실행 기록
SYSTOOLS_LOG="$CASE_DIR/$PHASE-systools.log"        # 07 ps/top 스냅샷
TIMESERIES_CSV="$CASE_DIR/$PHASE-timeseries.csv"    # 만들 CSV
REPORT_SNIPPET="$CASE_DIR/$PHASE-report-snippet.md" # 만들 요약 파일

# 04 를 먼저 실행해 스냅샷이 있어야 요약 가능
if [[ ! -f "$ENV_SNAPSHOT" ]]; then
  echo "[ERROR] $ENV_SNAPSHOT not found. Run 04-run-experiment-case.sh $CASE first." >&2
  exit 1
fi


# -----------------------------
# 2. 시계열 CSV 추출
# -----------------------------
if [[ -f "$MONITOR_LOG" ]]; then
  # monitor.log 각 줄에서 값만 뽑아 CSV 로 저장 (gawk 의 match 로 정규식 그룹 추출)
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
  ROWS=$(($(wc -l < "$TIMESERIES_CSV") - 1))    # 헤더 1줄을 뺀 데이터 행 수
  echo "[INFO] Timeseries CSV: $TIMESERIES_CSV ($ROWS rows)"
fi


# -----------------------------
# 3. 리포트 스니펫 생성
# -----------------------------
STARTED_AT=$(grep -m 1 '^# Timestamp:' "$ENV_SNAPSHOT" | sed 's/^# Timestamp: //')    # 실험 시작 시각
EXIT_MODE=$(grep -m 1 'Exit mode:' "$RUN_LOG" 2>/dev/null | sed 's/.*Exit mode: //' || true)    # 종료 방식 (앱 자체 종료 / 강제 종료)
EXIT_CODE=$(grep -m 1 'Exit code:' "$RUN_LOG" 2>/dev/null | sed 's/.*Exit code: //' || true)    # 예: 143 (SIGTERM)
# run 로그에서 요약에 넣을 주요 줄만 추출
RUN_LINES=$(grep -E '^\[(INFO|WARN)\] (App started|Run timeout|App still running|Exit mode|Exit code)' "$RUN_LOG" 2>/dev/null || true)

APP_LAST_LINES=$(tail -n 20 "$APP_LOG" 2>/dev/null || echo "(no app log)")    # 앱 로그 마지막 20줄
MON_FIRST=$(head -n 3 "$MONITOR_LOG" 2>/dev/null || echo "")                # 관제 로그 처음 3줄
MON_LAST=$(tail -n 3 "$MONITOR_LOG" 2>/dev/null || echo "")                 # 관제 로그 마지막 3줄

# ps/top 스냅샷: "===== " 로 시작하는 줄이 회차 구분선이므로, 첫 회차와 마지막 회차 블록만 꺼낸다
SYS_COUNT=$(grep -c '^===== ' "$SYSTOOLS_LOG" 2>/dev/null || true)    # 전체 회차 수
SYS_FIRST="(no system tools snapshot)"                                   # 첫 회차 (없을 때 기본 문구)
SYS_LAST="(no system tools snapshot)"                                    # 마지막 회차 (없을 때 기본 문구)
if [[ "${SYS_COUNT:-0}" -gt 0 ]]; then
  SYS_FIRST=$(awk '/^===== /{n++} n==1' "$SYSTOOLS_LOG")                           # 1번째 블록
  SYS_LAST=$(awk -v last="$SYS_COUNT" '/^===== /{n++} n==last && !/^# /' "$SYSTOOLS_LOG")    # 마지막 블록 (끝의 # 종료 안내 줄 제외)
fi

# 생존 시간 (모니터 로그의 첫/끝 타임스탬프 차이)
SURVIVAL=""
if [[ -f "$MONITOR_LOG" ]]; then
  FIRST_TS=$(grep -oE '\[[0-9-]+ [0-9:]+\]' "$MONITOR_LOG" | head -n 1 | tr -d '[]')    # 첫 타임스탬프
  LAST_TS=$(grep -oE '\[[0-9-]+ [0-9:]+\]' "$MONITOR_LOG" | tail -n 1 | tr -d '[]')     # 마지막 타임스탬프
  if [[ -n "$FIRST_TS" && -n "$LAST_TS" ]]; then
    FIRST_EPOCH=$(date -d "$FIRST_TS" +%s 2>/dev/null || echo 0)    # 초 단위 숫자로 변환
    LAST_EPOCH=$(date -d "$LAST_TS" +%s 2>/dev/null || echo 0)      # 초 단위 숫자로 변환
    if (( LAST_EPOCH > FIRST_EPOCH )); then
      SURVIVAL="$((LAST_EPOCH - FIRST_EPOCH)) seconds ($FIRST_TS ~ $LAST_TS)"    # 차이 = 생존 시간
    fi
  fi
fi

# 아래 내용으로 리포트 인용용 마크다운 파일 생성 ($변수와 $(명령)은 실제 값으로 바뀜)
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

## 시스템 도구 출력 (ps -ef / ps -L / top -H)

원본: [\`$PHASE-systools.log\`](./$PHASE-systools.log) (${SYS_COUNT:-0}회 수집)

**첫 회차:**
\`\`\`
$SYS_FIRST
\`\`\`

**마지막 회차:**
\`\`\`
$SYS_LAST
\`\`\`

## 시계열 데이터

CSV 원본: [\`$PHASE-timeseries.csv\`](./$PHASE-timeseries.csv)


## 파일 목록

\`\`\`
$(ls -la "$CASE_DIR" | tail -n +2)
\`\`\`
SNIPPET

echo "[INFO] Report snippet: $REPORT_SNIPPET"
