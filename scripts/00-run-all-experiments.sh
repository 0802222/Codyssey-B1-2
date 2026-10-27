#!/usr/bin/env bash
# 00-run-all-experiments.sh
# 사용법: bash scripts/00-run-all-experiments.sh [case-name...]   (호스트에서 실행)
# 예:    bash scripts/00-run-all-experiments.sh                       # 셋업 + 전체 실행
#        bash scripts/00-run-all-experiments.sh cpu-before cpu-after  # 셋업 + 지정한 케이스만 실행
#        SKIP_SETUP=1 bash scripts/00-run-all-experiments.sh cpu-before  # 셋업 생략 (컨테이너가 이미 준비된 경우)
#
# 동작:
#   1) 01-setup-container.sh 로 컨테이너 준비
#   2) experiment-cases.conf 의 케이스를 순서대로 04-run-experiment-case.sh 로 실행 (agentuser)

set -euo pipefail    # 에러, 미정의 변수, 파이프 중간 실패 시 즉시 중단

CONTAINER_NAME="${CONTAINER_NAME:-codyssey-b1-2-lab}"          # 실험용 컨테이너 이름 (기본값)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"     # 이 스크립트가 있는 폴더의 절대경로
CASES_FILE="$SCRIPT_DIR/experiment-cases.conf"                 # 실험 케이스 목록 파일

# SKIP_SETUP=1 이면 컨테이너 셋업을 건너뛴다
if [[ "${SKIP_SETUP:-0}" == "1" ]]; then
  echo "[INFO] SKIP_SETUP=1: container setup skipped"    # 생략 안내
else
  bash "$SCRIPT_DIR/01-setup-container.sh"               # 컨테이너 생성·프로비전·방화벽 설정
fi

ONLY=" $* "    # 인자로 받은 케이스 이름들 (앞뒤 공백을 붙여 단어 단위로 비교)
# 케이스 파일을 한 줄씩 읽는다 (첫 단어 = 케이스 이름, 나머지 = 환경변수들)
while read -r case_name vars; do
  [[ -z "$case_name" || "$case_name" == \#* ]] && continue               # 빈 줄과 주석 줄은 건너뜀
  [[ "$ONLY" == "  " || "$ONLY" == *" $case_name "* ]] || continue      # 인자가 있으면 지정한 케이스만 실행

  env_args=()                  # docker exec 에 넘길 -e 옵션 배열
  for kv in $vars; do          # VAR=VALUE 하나씩 꺼내서
    env_args+=(-e "$kv")       # -e VAR=VALUE 형태로 추가
  done

  # 컨테이너 안에서 agentuser 계정으로 케이스 하나 실행 (stdin 은 비워서 while read 와 섞이지 않게 함)
  docker exec -u agentuser "${env_args[@]}" "$CONTAINER_NAME" \
    ./scripts/04-run-experiment-case.sh "$case_name" < /dev/null
done < "$CASES_FILE"
