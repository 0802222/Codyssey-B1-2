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

set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-codyssey-b1-2-lab}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASES_FILE="$SCRIPT_DIR/experiment-cases.conf"

if [[ "${SKIP_SETUP:-0}" == "1" ]]; then
  echo "[INFO] SKIP_SETUP=1: container setup skipped"
else
  bash "$SCRIPT_DIR/01-setup-container.sh"
fi

ONLY=" $* "
while read -r case_name vars; do
  [[ -z "$case_name" || "$case_name" == \#* ]] && continue
  [[ "$ONLY" == "  " || "$ONLY" == *" $case_name "* ]] || continue

  env_args=()
  for kv in $vars; do
    env_args+=(-e "$kv")
  done

  docker exec -u agentuser "${env_args[@]}" "$CONTAINER_NAME" \
    ./scripts/04-run-experiment-case.sh "$case_name" < /dev/null
done < "$CASES_FILE"
