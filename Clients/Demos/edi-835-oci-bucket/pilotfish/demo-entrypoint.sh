#!/usr/bin/env bash
set -euo pipefail
umask 000
mkdir -p /opt/pilotfish/output/{archive,staged,json,oci-received,kickout}
chmod -R a+rwX /opt/pilotfish/output 2>/dev/null || true
exec /entrypoint.sh
