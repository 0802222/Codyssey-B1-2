#!/usr/bin/env bash
# 07-capture-system-tools.sh
# 사용법: bash scripts/07-capture-system-tools.sh <output-file>   (04 가 백그라운드로 실행)
# 예:    SYSTOOLS_INTERVAL=3 bash scripts/07-capture-system-tools.sh evidence/deadlock/before-systools.log
#
# 동작:
#   앱이 살아 있는 동안 SYSTOOLS_INTERVAL 초마다 아래 명령의 출력을 그대로 파일에 쌓는다.
#     1) ps -ef | grep <APP_NAME>    : PID 존재, 부모-자식 관계
#     2) ps -L -p <PID> -o ...       : 스레드별 상태, CPU, 메모리, 커널 대기 함수(wchan)
#     3) top -H -b -n 2 -d 1 -p <PID>: 스레드별 순간 CPU (2번째 측정값만 저장)
#   앱이 한 번 잡힌 뒤 사라지면 스스로 끝난다.
#
# 앱은 PyInstaller 바이너리라 "부트로더(부모) → 실제 앱(자식)" 2개 프로세스로 뜬다.
# 부모도 같은 이름이라, 부모가 같은 이름인 프로세스(= 자식)를 실제 앱으로 고른다.

set -uo pipefail    # 미정의 변수, 파이프 중간 실패 감지 (앱 종료 순간 명령 실패로 중단되지 않게 -e 는 뺌)

OUT_FILE="${1:-}"    # 첫 번째 인자 = 저장할 파일 경로
if [[ -z "$OUT_FILE" ]]; then    # 인자가 없으면 사용법 출력 후 중단
  echo "[ERROR] Usage: bash scripts/07-capture-system-tools.sh <output-file>" >&2
  exit 1
fi

APP_NAME="${APP_NAME:-agent-leak-app-x86}"    # 감시할 프로세스 이름
INTERVAL="${SYSTOOLS_INTERVAL:-3}"            # 수집 간격 (초)
START_WAIT=10                                 # 앱이 뜰 때까지 기다리는 최대 시간 (초)

export LANG=C    # top, ps 출력 형식을 영어 기본값으로 고정


# 실제 앱 PID 찾기: 실행 경로에 APP_NAME 이 들어간 프로세스 중, 부모(PPID)도 그 목록에 있는 것
find_app_pid() {
  ps -eo pid=,ppid=,args= | awk -v name="$APP_NAME" '
    $3 ~ name { pid[$1] = $2 }                   # 3번째 열(실행 경로)에 앱 이름이 있으면 pid → ppid 저장 (script 래퍼는 3번째 열이 script 라 제외)
    END { for (p in pid) if (pid[p] in pid) { print p; exit } }    # 부모도 앱인 프로세스 = 실제 앱
  '
}


: > "$OUT_FILE"    # 출력 파일 비우기
{
  echo "# System tools snapshot"
  echo "# APP_NAME: $APP_NAME, interval: ${INTERVAL}s"
  echo "# Started at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
} >> "$OUT_FILE"

# 앱이 뜰 때까지 최대 START_WAIT 초 대기
APP_PID=""
for ((i = 0; i < START_WAIT; i++)); do
  APP_PID="$(find_app_pid)"    # 실제 앱 PID 찾기 (자식이 아직 안 떴으면 빈 값)
  [[ -n "$APP_PID" ]] && break    # 찾으면 대기 종료
  sleep 1
done

if [[ -z "$APP_PID" ]]; then    # 끝까지 못 찾으면 기록만 남기고 종료
  echo "# [ERROR] Process '$APP_NAME' not found within ${START_WAIT}s" >> "$OUT_FILE"
  exit 1
fi

SAMPLE=0    # 수집 회차 번호
while kill -0 "$APP_PID" 2>/dev/null; do    # 앱이 살아 있는 동안 반복
  SAMPLE=$((SAMPLE + 1))
  {
    echo
    echo "===== [$(date '+%Y-%m-%d %H:%M:%S')] sample $SAMPLE (app PID: $APP_PID) ====="

    echo "\$ ps -ef | grep $APP_NAME"
    ps -ef | grep "$APP_NAME" | grep -v grep    # 앱 관련 프로세스 전체 (script 래퍼, 부트로더, 실제 앱)

    echo
    echo "\$ ps -L -p $APP_PID -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm"
    # -L: 스레드마다 한 줄, wchan: 스레드가 커널 안에서 잠들어 있는 함수 이름 (futex_wait = Lock 대기)
    ps -L -p "$APP_PID" -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm

    echo
    echo "\$ top -H -b -n 2 -d 1 -p $APP_PID   (2nd iteration)"
    # -H: 스레드별, -b: 배치 출력, -n 2 -d 1: 1초 간격 2회 측정
    # 1회차는 누적값이라 버리고, 2회차(직전 1초 동안의 순간 CPU)의 표 부분만 남긴다
    top -H -b -n 2 -d 1 -p "$APP_PID" | awk '/^top -/{n++} n==2 && (/^ *PID/ || /^ *[0-9]+ /)'
  } >> "$OUT_FILE" 2>&1

  sleep "$INTERVAL"    # 다음 회차까지 대기
done

echo >> "$OUT_FILE"
echo "# [$(date '+%Y-%m-%d %H:%M:%S')] app PID $APP_PID exited. $SAMPLE samples captured." >> "$OUT_FILE"
