#!/usr/bin/env bash
# Run the XML -> EDI 834 PilotFish sandbox (separate eip-root + data dirs).
#
# Usage:
#   ./docker-run-834.sh build|start|stop|restart|status|logs|shell|url|demo
#   ./docker-run-834.sh          # start (build if needed), then follow eip.log
#   ./docker-run-834.sh demo     # start, drop sample XML, wait for .834 output

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-pilotfish-eip:23R1}"
CONTAINER_NAME="${CONTAINER_NAME:-pilotfish-eip-834}"
HOST_PORT="${HOST_PORT:-8081}"

EIP_ROOT_DIR="${ROOT_DIR}/eip-root-834"
DATA_DIR="${ROOT_DIR}/data-834"
LOGS_DIR="${ROOT_DIR}/logs-834"
DEBUG_TRACE_DIR="${ROOT_DIR}/debug-trace-834"
SAMPLE_XML="${EIP_ROOT_DIR}/interfaces/XML to EDI 834/samples/enrollment_batch.xml"

ensure_dirs() {
  mkdir -p \
    "${DATA_DIR}/input" \
    "${DATA_DIR}/output" \
    "${DATA_DIR}/archive" \
    "${DATA_DIR}/database" \
    "${LOGS_DIR}" \
    "${DEBUG_TRACE_DIR}"
}

image_exists() {
  docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1
}

cmd_build() {
  echo "Building ${IMAGE_NAME} (base image; eip-root-834 is mounted at runtime) ..."
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

cmd_url() {
  echo "EIP URL   : http://localhost:${HOST_PORT}/eip/"
  echo "Tomcat    : http://localhost:${HOST_PORT}/"
  echo "EIP root  : ${EIP_ROOT_DIR}"
  echo "Data dirs : ${DATA_DIR}/{input,output,archive}"
}

cmd_start() {
  ensure_dirs

  if [[ ! -d "${EIP_ROOT_DIR}" ]]; then
    echo "Missing EIP root: ${EIP_ROOT_DIR}" >&2
    exit 1
  fi

  if ! image_exists; then
    cmd_build
  fi

  if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    echo "Container ${CONTAINER_NAME} is already running."
    cmd_url
    return 0
  fi

  if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    docker rm "${CONTAINER_NAME}" >/dev/null
  fi

  echo "Starting ${CONTAINER_NAME} on port ${HOST_PORT} ..."
  docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${HOST_PORT}:8080" \
    -v "${EIP_ROOT_DIR}:/usr/local/tomcat/webapps/eip/eip-root" \
    -v "${DATA_DIR}/input:/opt/pilotfish/input" \
    -v "${DATA_DIR}/output:/opt/pilotfish/output" \
    -v "${DATA_DIR}/archive:/opt/pilotfish/archive" \
    -v "${DATA_DIR}/database:/opt/pilotfish/database" \
    -v "${LOGS_DIR}:/usr/local/tomcat/webapps/eip/logs" \
    -v "${DEBUG_TRACE_DIR}:/usr/local/tomcat/webapps/eip/eip-root/debug-trace" \
    "${IMAGE_NAME}"

  cmd_url
  echo
  echo "EIP log   : ${LOGS_DIR}/eip.log   (or: ./docker-run-834.sh logs)"
}

cmd_restart() {
  cmd_stop
  cmd_start
}

cmd_status() {
  docker ps -a --filter "name=^${CONTAINER_NAME}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

cmd_logs() {
  ensure_dirs
  local log_file="${LOGS_DIR}/eip.log"
  echo "Waiting for ${log_file} ..."
  local i=0
  while [[ ! -f "${log_file}" ]]; do
    if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
      echo "Container is not running. Start it with: ./docker-run-834.sh start" >&2
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

cmd_shell() {
  docker exec -it "${CONTAINER_NAME}" bash
}

cmd_demo() {
  cmd_start

  echo
  echo "Waiting for EIP startup ..."
  local i=0
  while true; do
    local code
    code="$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${HOST_PORT}/eip/" 2>/dev/null || echo 000)"
    if [[ "${code}" == "200" || "${code}" == "302" || "${code}" == "401" || "${code}" == "403" ]]; then
      break
    fi
    i=$((i + 1))
    if (( i > 90 )); then
      echo "Timed out waiting for EIP HTTP." >&2
      docker logs --tail 80 "${CONTAINER_NAME}" || true
      exit 1
    fi
    sleep 2
  done

  i=0
  while [[ ! -f "${LOGS_DIR}/eip.log" ]] || ! grep -q 'startup complete' "${LOGS_DIR}/eip.log" 2>/dev/null; do
    i=$((i + 1))
    if (( i > 90 )); then
      break
    fi
    sleep 1
  done

  if [[ ! -f "${SAMPLE_XML}" ]]; then
    echo "Missing sample: ${SAMPLE_XML}" >&2
    exit 1
  fi

  rm -f "${DATA_DIR}/output/"*.834 2>/dev/null || true
  local dest="${DATA_DIR}/input/enrollment_batch.xml"
  cp "${SAMPLE_XML}" "${dest}"
  touch -t 202601010000 "${dest}" 2>/dev/null || touch "${dest}"
  echo "Dropped sample into ${dest}"

  echo "Waiting for EDI 834 output ..."
  i=0
  while true; do
    local out
    out="$(ls -1t "${DATA_DIR}/output/"*.834 2>/dev/null | head -1 || true)"
    if [[ -n "${out}" ]]; then
      echo
      echo "=== Generated: ${out} ==="
      cat "${out}"
      echo
      return 0
    fi
    i=$((i + 1))
    if (( i > 90 )); then
      echo "Timed out waiting for .834 output." >&2
      echo "--- recent eip.log ---" >&2
      tail -n 80 "${LOGS_DIR}/eip.log" 2>/dev/null || true
      exit 1
    fi
    sleep 2
  done
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
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
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
    shell)      cmd_shell ;;
    url)        cmd_url ;;
    demo)       cmd_demo ;;
    -h|--help|help) usage ;;
    *)
      echo "Unknown command: ${action}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
