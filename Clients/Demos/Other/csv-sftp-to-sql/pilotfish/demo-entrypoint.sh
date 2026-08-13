#!/usr/bin/env bash
set -euo pipefail
umask 000
chmod -R a+rwX /opt/pilotfish/output /opt/pilotfish/input 2>/dev/null || true
exec /entrypoint.sh
