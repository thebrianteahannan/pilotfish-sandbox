#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

NAME="${DISC_GOLF_NAME:-chainshot-disc-golf}"
PORT="${DISC_GOLF_PORT:-8787}"

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker build -t "$NAME" .
docker run -d --name "$NAME" -p "0.0.0.0:${PORT}:80" "$NAME"

LAN_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || true)"
echo "Chainshot is running in Docker."
echo "Local:  http://127.0.0.1:${PORT}/"
if [[ -n "${LAN_IP:-}" ]]; then
  echo "LAN:    http://${LAN_IP}:${PORT}/"
fi
