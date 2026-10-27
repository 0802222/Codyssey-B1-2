#!/usr/bin/env bash
set -euo pipefail    # 에러, 미정의 변수, 파이프 중간 실패 시 즉시 중단

SERVICE_USER="${SERVICE_USER:-agentuser}"    # 앱을 실행할 일반 계정

AGENT_HOME="${AGENT_HOME:-/workspace/runtime}"    # 앱 런타임 기본 폴더
AGENT_PORT="${AGENT_PORT:-15034}"                 # 앱 포트
APP_NAME="${APP_NAME:-agent-leak-app-x86}"        # 앱 바이너리 이름

AGENT_UPLOAD_DIR="${AGENT_UPLOAD_DIR:-$AGENT_HOME/upload_files}"    # 업로드 파일 폴더
AGENT_KEY_PATH="${AGENT_KEY_PATH:-$AGENT_HOME/api_keys}"            # 키 파일 폴더
AGENT_LOG_DIR="${AGENT_LOG_DIR:-$AGENT_HOME/logs}"                  # 로그 폴더

MEMORY_LIMIT="${MEMORY_LIMIT:-100}"                  # 앱 메모리 상한 (MB)
CPU_MAX_OCCUPY="${CPU_MAX_OCCUPY:-50}"               # 앱 CPU 점유 상한 (%)
MULTI_THREAD_ENABLE="${MULTI_THREAD_ENABLE:-true}"   # 멀티스레드 사용 여부

APP_PATH="/workspace/bin/$APP_NAME"         # 앱 바이너리 전체 경로
ENV_FILE="/workspace/runtime/agent.env"     # 생성할 환경변수 파일
TZ="${TZ:-Asia/Seoul}"                      # 시간대

# root 로 실행했는지 확인
require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then                                       # UID 0 = root
    echo "[ERROR] 02-provision-runtime.sh must be run as root." >&2
    echo "        Run it right after entering the container as root." >&2
    exit 1
  fi
}

# 포트가 1~65535 사이 숫자인지 확인
validate_port() {
  [[ "$AGENT_PORT" =~ ^[0-9]+$ ]] &&
    (( AGENT_PORT >= 1 && AGENT_PORT <= 65535 )) || {
      echo "[ERROR] Invalid AGENT_PORT: $AGENT_PORT" >&2
      exit 1
    }
}

# 실험 변수 3개가 과제에서 정한 범위 안인지 확인
validate_range() {
  # MEMORY_LIMIT: 50~512 MB
  [[ "$MEMORY_LIMIT" =~ ^[0-9]+$ ]] &&
    (( MEMORY_LIMIT >= 50 && MEMORY_LIMIT <= 512 )) || {
      echo "[ERROR] MEMORY_LIMIT must be an integer from 50 to 512 MB." >&2
      exit 1
    }

  # CPU_MAX_OCCUPY: 10~100 %
  [[ "$CPU_MAX_OCCUPY" =~ ^[0-9]+$ ]] &&
    (( CPU_MAX_OCCUPY >= 10 && CPU_MAX_OCCUPY <= 100 )) || {
      echo "[ERROR] CPU_MAX_OCCUPY must be an integer from 10 to 100 percent." >&2
      exit 1
    }

  # MULTI_THREAD_ENABLE: true 또는 false
  [[ "$MULTI_THREAD_ENABLE" == "true" ||
     "$MULTI_THREAD_ENABLE" == "false" ]] || {
      echo "[ERROR] MULTI_THREAD_ENABLE must be true or false." >&2
      exit 1
    }
}

# 관제·실험에 필요한 리눅스 도구 설치
install_packages() {
  echo "[INFO] Installing Linux tools..."
  apt-get update    # 패키지 목록 갱신
  # 질문 없이 설치: ps/top(procps), killall(psmisc), ss(iproute2), file, 인증서, 시간대, 방화벽, awk, 편집기
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    procps \
    psmisc \
    iproute2 \
    file \
    ca-certificates \
    tzdata \
    ufw \
    gawk \
    nano

  ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime    # 시스템 시간을 한국 시간으로 설정
  echo "Asia/Seoul" > /etc/timezone                        # 시간대 이름 기록
}



# 앱 실행용 일반 계정 생성 (이미 있으면 건너뜀)
create_service_user() {
  if id "$SERVICE_USER" >/dev/null 2>&1; then                       # 계정 존재 여부 확인
    echo "[INFO] User already exists: $SERVICE_USER"
  else
    useradd --create-home --shell /bin/bash "$SERVICE_USER"         # 홈 폴더와 bash 셸로 계정 생성
    echo "[INFO] Created service user: $SERVICE_USER"
  fi
}

# 런타임 폴더와 테스트용 키 파일 준비, 권한 설정
prepare_directories() {
  # 필요한 폴더 한 번에 생성 (이미 있으면 그대로)
  mkdir -p \
    "$AGENT_HOME" \
    "$AGENT_UPLOAD_DIR" \
    "$AGENT_KEY_PATH" \
    "$AGENT_LOG_DIR"

  printf '%s' 'agent_api_key_test' > "$AGENT_KEY_PATH/secret.key"    # 실습용 더미 키 파일 생성

  chown -R "$SERVICE_USER:$SERVICE_USER" "$AGENT_HOME"     # 런타임 폴더 전체 소유자를 서비스 계정으로
  chmod 700 "$AGENT_KEY_PATH"                              # 키 폴더: 소유자만 접근
  chmod 600 "$AGENT_KEY_PATH/secret.key"                   # 키 파일: 소유자만 읽기·쓰기
  chmod 755 "$AGENT_UPLOAD_DIR" "$AGENT_LOG_DIR"           # 업로드·로그 폴더: 다른 사용자는 읽기만

  echo "[INFO] Runtime directories and secret.key are ready."
}

# 앱 바이너리 존재 확인 및 실행 권한 부여
prepare_app() {
  if [[ ! -f "$APP_PATH" ]]; then                                             # 바이너리가 없으면 중단
    echo "[ERROR] App binary not found: $APP_PATH" >&2
    echo "        Put agent-leak-app-x86 in ./bin on your Mac project folder." >&2
    exit 1
  fi

  chmod +x "$APP_PATH"    # 실행 권한 추가

  echo "[INFO] App binary check:"
  file "$APP_PATH"        # 바이너리 종류(x86-64 ELF 등) 확인
  ls -l "$APP_PATH"       # 권한·소유자 확인
}

# 앱과 스크립트가 읽을 agent.env 생성
# 실험 변수 3개는 \${VAR:-기본값} 형태로 저장해 실행 시 외부 값으로 덮어쓸 수 있게 한다
write_env_file() {
  cat > "$ENV_FILE" <<EOF
export AGENT_HOME="$AGENT_HOME"
export AGENT_PORT="$AGENT_PORT"
export APP_NAME="$APP_NAME"
export AGENT_UPLOAD_DIR="$AGENT_UPLOAD_DIR"
export AGENT_KEY_PATH="$AGENT_KEY_PATH"
export AGENT_LOG_DIR="$AGENT_LOG_DIR"
export MEMORY_LIMIT="\${MEMORY_LIMIT:-$MEMORY_LIMIT}"
export CPU_MAX_OCCUPY="\${CPU_MAX_OCCUPY:-$CPU_MAX_OCCUPY}"
export MULTI_THREAD_ENABLE="\${MULTI_THREAD_ENABLE:-$MULTI_THREAD_ENABLE}"
TZ="${TZ:-Asia/Seoul}"
EOF

  chown "$SERVICE_USER:$SERVICE_USER" "$ENV_FILE"    # 서비스 계정 소유로 변경
  chmod 600 "$ENV_FILE"                              # 소유자만 읽기·쓰기

  echo "[INFO] Environment file created: $ENV_FILE"
}

# 방화벽 상태를 파일로 기록 (agentuser 는 ufw 를 직접 못 보므로 05 관제 스크립트가 이 파일을 읽음)
check_firewall_status() {
  local status="unknown"    # 기본값

  if command -v ufw >/dev/null 2>&1; then                            # ufw 가 있으면
    if ufw status 2>/dev/null | grep -q "Status: active"; then
      status="active"
    else
      status="inactive"
    fi
  elif command -v firewall-cmd >/dev/null 2>&1; then                 # firewalld 가 있으면
    if firewall-cmd --state 2>/dev/null | grep -q "running"; then
      status="active"
    else
      status="inactive"
    fi
  else
    status="not found"                                               # 방화벽 도구가 없음
  fi

  echo "$status" > "$AGENT_HOME/firewall-status.txt"                      # 상태 파일 기록
  chown "$SERVICE_USER:$SERVICE_USER" "$AGENT_HOME/firewall-status.txt"   # 서비스 계정이 읽을 수 있게
}

# 준비 결과와 다음에 할 명령 안내 출력
print_result() {
  cat <<EOF

====== B1-2 PROVISION COMPLETE ======

Service user : $SERVICE_USER
App path     : $APP_PATH
AGENT_HOME   : $AGENT_HOME
Log directory: $AGENT_LOG_DIR
Port         : $AGENT_PORT

Next commands:

  su - $SERVICE_USER
  source $ENV_FILE
  cd /workspace
  ./bin/$APP_NAME

For monitoring in another container terminal:

  docker exec -it -u $SERVICE_USER codyssey-b1-2 bash
  source $ENV_FILE
  cd /workspace
  ./scripts/05-monitor-app-resources.sh

EOF
}

# 전체 순서: 권한 확인 → 값 검증 → 설치 → 계정 → 폴더 → 앱 → env 파일 → 방화벽 상태 → 결과 출력
main() {
  require_root
  validate_port
  validate_range
  install_packages
  create_service_user
  prepare_directories
  prepare_app
  write_env_file
  check_firewall_status
  print_result
}

main "$@"    # 스크립트 시작점
