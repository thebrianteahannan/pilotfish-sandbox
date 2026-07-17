#!/bin/bash
# Serve Orbit Disc on LAN port 5174 via Docker (avoids bind-mount issues with spaces in path).
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
STAGE="/tmp/spaceship-disc-golf"
IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo YOUR-MAC-IP)"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$SRC"/* "$STAGE"/

docker rm -f orbit-disc-lan >/dev/null 2>&1 || true
docker run -d --name orbit-disc-lan -p 5174:80 \
  -v "${STAGE}:/usr/share/nginx/html:ro" \
  -v "${STAGE}/nginx-default.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:alpine >/dev/null

echo "Orbit Disc LAN: http://${IP}:5174/?v=$(date +%s)"
