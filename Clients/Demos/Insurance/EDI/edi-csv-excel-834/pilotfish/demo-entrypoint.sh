#!/usr/bin/env bash
set -euo pipefail
umask 000
mkdir -p /opt/pilotfish/input/{inbound,edi} \
         /opt/pilotfish/output/{834,csv,kickout,archive/csv,archive/edi}
chmod -R a+rwX /opt/pilotfish/output /opt/pilotfish/input 2>/dev/null || true
exec /entrypoint.sh
