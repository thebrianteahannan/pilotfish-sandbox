#!/usr/bin/env bash
set -euo pipefail
umask 000
mkdir -p /opt/pilotfish/input/inbound \
  /opt/pilotfish/output/{archive,approved,denied,incomplete,pended,responses,ehr-notices,debug,staged-decisions}
chmod -R a+rwX /opt/pilotfish/input /opt/pilotfish/output 2>/dev/null || true
exec /entrypoint.sh
