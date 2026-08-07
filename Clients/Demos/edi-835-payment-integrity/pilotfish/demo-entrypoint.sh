#!/usr/bin/env bash
set -euo pipefail
umask 000
mkdir -p /opt/pilotfish/input/inbound \
  /opt/pilotfish/output/{archive,matched,exceptions,underpay,debug,staged-decisions}
if [[ ! -s /opt/pilotfish/output/underpay/underpay_alerts.csv ]]; then
  printf '%s\n' 'ClaimControlNumber,PatientName,ExpectedPaid,PaidAmount,Variance,CasCodes,Reason,SourceFile' \
    > /opt/pilotfish/output/underpay/underpay_alerts.csv
fi
chmod -R a+rwX /opt/pilotfish/input /opt/pilotfish/output 2>/dev/null || true
exec /entrypoint.sh
