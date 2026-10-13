#!/usr/bin/env bash
# 01-setup-container.sh
# 사용법: bash scripts/01-setup-container.sh   (호스트에서 실행)
#
# 동작:
#   1) 컨테이너 생성 (없을 때만) 및 시작
#   2) 02-provision-runtime.sh, 03-configure-firewall.sh 실행 (root)

set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-codyssey-b1-2-lab}"

# 레포 루트 기준으로 마운트 (어디서 실행해도 동일)
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# 앱 바이너리가 x86-64 이므로 Apple Silicon 에서도 amd64 로 실행
docker inspect "$CONTAINER_NAME" >/dev/null 2>&1 || \
  docker create --name "$CONTAINER_NAME" --platform linux/amd64 --cap-add=NET_ADMIN -p 15034:15034 \
    -v "$PWD:/workspace" -w /workspace ubuntu:24.04 sleep infinity
docker start "$CONTAINER_NAME"

docker exec "$CONTAINER_NAME" ./scripts/02-provision-runtime.sh
docker exec "$CONTAINER_NAME" ./scripts/03-configure-firewall.sh
