#!/usr/bin/env bash
set -euo pipefail
umask 000
mkdir -p /opt/pilotfish/output/{requests,270,271,responses}
chmod -R a+rwX /opt/pilotfish/output 2>/dev/null || true
exec /entrypoint.sh
