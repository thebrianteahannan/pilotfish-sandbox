#!/usr/bin/env bash
set -euo pipefail
# Demo output is shared with the web UI container via bind mount.
umask 000
chmod -R a+rwX /opt/pilotfish/output 2>/dev/null || true
exec /entrypoint.sh
