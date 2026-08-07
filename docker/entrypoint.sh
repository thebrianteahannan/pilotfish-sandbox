#!/usr/bin/env bash
set -euo pipefail

# PilotFish filesystem layout used by environment-settings.conf and routes
mkdir -p \
  /opt/pilotfish/input/staging \
  /opt/pilotfish/output \
  /opt/pilotfish/archive \
  /opt/pilotfish/database \
  /usr/local/tomcat/webapps/eip/logs

for client in NSP-Multi PPS-Multi HAL-Multi NGP-Multi PPA-Multi; do
  mkdir -p "/opt/pilotfish/input/${client}/in" \
           "/opt/pilotfish/input/${client}/out" \
           "/opt/pilotfish/input/${client}/archive"
done

# Seed the H2 DB into the mounted volume when missing or still the tiny empty stub
DB_FILE="/opt/pilotfish/database/medreceivables.mv.db"
SEED_DB="/opt/pilotfish/seed/medreceivables.mv.db"
if [ -f "${SEED_DB}" ]; then
  if [ ! -f "${DB_FILE}" ] || [ "$(wc -c < "${DB_FILE}")" -lt 100000 ]; then
    echo "Seeding H2 database from ${SEED_DB} -> ${DB_FILE}"
    rm -f /opt/pilotfish/database/medreceivables.trace.db \
          /opt/pilotfish/database/medreceivables.lock.db
    cp -f "${SEED_DB}" "${DB_FILE}"
  else
    echo "Using existing H2 database: ${DB_FILE} ($(wc -c < "${DB_FILE}") bytes)"
  fi
fi

# Ensure EIP / Tomcat can write data + logs
chmod -R a+rwX /opt/pilotfish /usr/local/tomcat/webapps/eip/logs 2>/dev/null || true

# Force debug-trace OFF on every route (historical XML exports blow disk/RAM)
# Skip backups/ folders. Uses grep+sed so we only touch files that need it.
EIP_ROOT="/usr/local/tomcat/webapps/eip/eip-root"
if [ -d "${EIP_ROOT}/interfaces" ]; then
  n=0
  while IFS= read -r -d '' f; do
    case "$f" in
      */backups/*) continue ;;
    esac
    if grep -q 'debuggingTrace="true"' "$f" 2>/dev/null; then
      sed -i 's/debuggingTrace="true"/debuggingTrace="false"/g' "$f"
      n=$((n + 1))
    fi
  done < <(find "${EIP_ROOT}/interfaces" -name 'route.xml' -print0 2>/dev/null)
  echo "Debug-trace: forced off on ${n} route.xml file(s)"
fi
mkdir -p "${EIP_ROOT}/debug-trace"
# Prefer empty debug-trace dir (bind mounts may still receive writes if somehow re-enabled)
rm -rf "${EIP_ROOT}/debug-trace"/* 2>/dev/null || true

echo "Starting Tomcat with eiPlatform..."
echo "  EIP root : /usr/local/tomcat/webapps/eip/eip-root"
echo "  Data     : /opt/pilotfish/{input,output,archive,database}"
echo "  Database : ${DB_FILE}"
echo "  EIP log  : /usr/local/tomcat/webapps/eip/logs/eip.log"
echo "  Tomcat   : http://localhost:8080/eip/"

exec catalina.sh run
