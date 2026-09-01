#!/usr/bin/env bash
set -euo pipefail

SERVICE_USER="${SERVICE_USER:-agentuser}"

AGENT_HOME="${AGENT_HOME:-/workspace/runtime}"
AGENT_PORT="${AGENT_PORT:-15034}"
APP_NAME="${APP_NAME:-agent-leak-app-x86}"

AGENT_UPLOAD_DIR="${AGENT_UPLOAD_DIR:-$AGENT_HOME/upload_files}"
AGENT_KEY_PATH="${AGENT_KEY_PATH:-$AGENT_HOME/api_keys}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-$AGENT_HOME/logs}"

MEMORY_LIMIT="${MEMORY_LIMIT:-100}"
CPU_MAX_OCCUPY="${CPU_MAX_OCCUPY:-50}"
MULTI_THREAD_ENABLE="${MULTI_THREAD_ENABLE:-true}"

APP_PATH="/workspace/bin/$APP_NAME"
ENV_FILE="/workspace/runtime/agent.env"
TZ="${TZ:-Asia/Seoul}"

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] provision.sh must be run as root." >&2
    echo "        Run it right after entering the container as root." >&2
    exit 1
  fi
}

validate_port() {
  [[ "$AGENT_PORT" =~ ^[0-9]+$ ]] &&
    (( AGENT_PORT >= 1 && AGENT_PORT <= 65535 )) || {
      echo "[ERROR] Invalid AGENT_PORT: $AGENT_PORT" >&2
      exit 1
    }
}

validate_range() {
  [[ "$MEMORY_LIMIT" =~ ^[0-9]+$ ]] &&
    (( MEMORY_LIMIT >= 50 && MEMORY_LIMIT <= 512 )) || {
      echo "[ERROR] MEMORY_LIMIT must be an integer from 50 to 512 MB." >&2
      exit 1
    }

  [[ "$CPU_MAX_OCCUPY" =~ ^[0-9]+$ ]] &&
    (( CPU_MAX_OCCUPY >= 10 && CPU_MAX_OCCUPY <= 100 )) || {
      echo "[ERROR] CPU_MAX_OCCUPY must be an integer from 10 to 100 percent." >&2
      exit 1
    }

  [[ "$MULTI_THREAD_ENABLE" == "true" ||
     "$MULTI_THREAD_ENABLE" == "false" ]] || {
      echo "[ERROR] MULTI_THREAD_ENABLE must be true or false." >&2
      exit 1
    }
}

install_packages() {
  echo "[INFO] Installing Linux tools..."
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    procps \
    psmisc \
    iproute2 \
    file \
    ca-certificates \
    tzdata \ 
    ufw

  ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
  echo "Asia/Seoul" > /etc/timezone
}



create_service_user() {
  if id "$SERVICE_USER" >/dev/null 2>&1; then
    echo "[INFO] User already exists: $SERVICE_USER"
  else
    useradd --create-home --shell /bin/bash "$SERVICE_USER"
    echo "[INFO] Created service user: $SERVICE_USER"
  fi
}

prepare_directories() {
  mkdir -p \
    "$AGENT_HOME" \
    "$AGENT_UPLOAD_DIR" \
    "$AGENT_KEY_PATH" \
    "$AGENT_LOG_DIR"

  printf '%s' 'agent_api_key_test' > "$AGENT_KEY_PATH/secret.key"

  chown -R "$SERVICE_USER:$SERVICE_USER" "$AGENT_HOME"
  chmod 700 "$AGENT_KEY_PATH"
  chmod 600 "$AGENT_KEY_PATH/secret.key"
  chmod 755 "$AGENT_UPLOAD_DIR" "$AGENT_LOG_DIR"

  echo "[INFO] Runtime directories and secret.key are ready."
}

prepare_app() {
  if [[ ! -f "$APP_PATH" ]]; then
    echo "[ERROR] App binary not found: $APP_PATH" >&2
    echo "        Put agent-leak-app-x86 in ./bin on your Mac project folder." >&2
    exit 1
  fi

  chmod +x "$APP_PATH"

  echo "[INFO] App binary check:"
  file "$APP_PATH"
  ls -l "$APP_PATH"
}

write_env_file() {
  cat > "$ENV_FILE" <<EOF
export AGENT_HOME="$AGENT_HOME"
export AGENT_PORT="$AGENT_PORT"
export APP_NAME="$APP_NAME"
export AGENT_UPLOAD_DIR="$AGENT_UPLOAD_DIR"
export AGENT_KEY_PATH="$AGENT_KEY_PATH"
export AGENT_LOG_DIR="$AGENT_LOG_DIR"
export MEMORY_LIMIT="$MEMORY_LIMIT"
export CPU_MAX_OCCUPY="$CPU_MAX_OCCUPY"
export MULTI_THREAD_ENABLE="$MULTI_THREAD_ENABLE"
TZ="${TZ:-Asia/Seoul}"
EOF

  chown "$SERVICE_USER:$SERVICE_USER" "$ENV_FILE"
  chmod 600 "$ENV_FILE"

  echo "[INFO] Environment file created: $ENV_FILE"
}

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
  ./scripts/monitor.sh

EOF
}

main() {
  require_root
  validate_port
  validate_range
  install_packages
  create_service_user
  prepare_directories
  prepare_app
  write_env_file
  print_result
}

main "$@"