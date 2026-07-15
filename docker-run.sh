#!/usr/bin/env bash
# Repeatable helper for the local PilotFish eiPlatform Docker image.
#
# Usage:
#   ./docker-run.sh build          Build (or rebuild) the image
#   ./docker-run.sh start          Start/recreate the container
#   ./docker-run.sh stop           Stop the container
#   ./docker-run.sh restart        Stop + start
#   ./docker-run.sh status         Container status
#   ./docker-run.sh logs           Tail eip.log (waits until it appears)
#   ./docker-run.sh tomcat-logs    Tail Tomcat catalina.out
#   ./docker-run.sh shell          Open a shell in the running container
#   ./docker-run.sh url            Print the EIP URL
#
# Or just: ./docker-run.sh         (build if needed, then start, then follow eip.log)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-pilotfish-eip:23R1}"
CONTAINER_NAME="${CONTAINER_NAME:-pilotfish-eip}"
HOST_PORT="${HOST_PORT:-8080}"

DATA_DIR="${ROOT_DIR}/data"
LOGS_DIR="${ROOT_DIR}/logs"
DEBUG_TRACE_DIR="${ROOT_DIR}/debug-trace"

ensure_dirs() {
  mkdir -p \
    "${DATA_DIR}/input/staging" \
    "${DATA_DIR}/output" \
    "${DATA_DIR}/archive" \
    "${DATA_DIR}/database" \
    "${LOGS_DIR}" \
    "${DEBUG_TRACE_DIR}"

  for client in NSP-Multi PPS-Multi HAL-Multi NGP-Multi PPA-Multi; do
    mkdir -p \
      "${DATA_DIR}/input/${client}/in" \
      "${DATA_DIR}/input/${client}/out" \
      "${DATA_DIR}/input/${client}/archive"
  done
}

image_exists() {
  docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1
}

cmd_build() {
  echo "Building ${IMAGE_NAME} ..."
  docker build -t "${IMAGE_NAME}" "${ROOT_DIR}"
  echo "Build complete."
}

cmd_stop() {
  if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    echo "Stopping ${CONTAINER_NAME} ..."
    docker stop "${CONTAINER_NAME}" >/dev/null || true
    docker rm "${CONTAINER_NAME}" >/dev/null || true
  else
    echo "Container ${CONTAINER_NAME} is not present."
  fi
}

cmd_start() {
  ensure_dirs

  if ! image_exists; then
    cmd_build
  fi

  if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    echo "Container ${CONTAINER_NAME} is already running."
    cmd_url
    return 0
  fi

  # Recreate if a stopped container exists
  if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    docker rm "${CONTAINER_NAME}" >/dev/null
  fi

  echo "Starting ${CONTAINER_NAME} on port ${HOST_PORT} ..."
  docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${HOST_PORT}:8080" \
    -v "${DATA_DIR}/input:/opt/pilotfish/input" \
    -v "${DATA_DIR}/output:/opt/pilotfish/output" \
    -v "${DATA_DIR}/archive:/opt/pilotfish/archive" \
    -v "${DATA_DIR}/database:/opt/pilotfish/database" \
    -v "${LOGS_DIR}:/usr/local/tomcat/webapps/eip/logs" \
    -v "${DEBUG_TRACE_DIR}:/usr/local/tomcat/webapps/eip/eip-root/debug-trace" \
    "${IMAGE_NAME}"

  cmd_url
  echo
  echo "Data dirs : ${DATA_DIR}/{input,output,archive,database}"
  echo "EIP log   : ${LOGS_DIR}/eip.log   (or: ./docker-run.sh logs)"
  echo "Debug     : ${DEBUG_TRACE_DIR}"
}

cmd_restart() {
  cmd_stop
  cmd_start
}

cmd_status() {
  docker ps -a --filter "name=^${CONTAINER_NAME}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

cmd_url() {
  echo "EIP URL   : http://localhost:${HOST_PORT}/eip/"
  echo "Tomcat    : http://localhost:${HOST_PORT}/"
}

cmd_logs() {
  ensure_dirs
  local log_file="${LOGS_DIR}/eip.log"
  echo "Waiting for ${log_file} ..."
  local i=0
  while [[ ! -f "${log_file}" ]]; do
    if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
      echo "Container is not running. Start it with: ./docker-run.sh start" >&2
      exit 1
    fi
    i=$((i + 1))
    if (( i > 120 )); then
      echo "Timed out waiting for eip.log. Showing Tomcat logs instead:" >&2
      docker logs --tail 100 "${CONTAINER_NAME}" || true
      exit 1
    fi
    sleep 1
  done
  echo "Tailing ${log_file} (Ctrl-C to stop) ..."
  tail -n 200 -f "${log_file}"
}

cmd_tomcat_logs() {
  docker logs -f "${CONTAINER_NAME}"
}

cmd_shell() {
  docker exec -it "${CONTAINER_NAME}" bash
}

cmd_default() {
  if ! image_exists; then
    cmd_build
  fi
  cmd_start
  echo
  cmd_logs
}

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
  local action="${1:-}"
  case "${action}" in
    ""|run)     cmd_default ;;
    build)      cmd_build ;;
    start)      cmd_start ;;
    stop)       cmd_stop ;;
    restart)    cmd_restart ;;
    status)     cmd_status ;;
    logs)       cmd_logs ;;
    tomcat-logs) cmd_tomcat_logs ;;
    shell)      cmd_shell ;;
    url)        cmd_url ;;
    -h|--help|help) usage ;;
    *)
      echo "Unknown command: ${action}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
