#!/bin/bash
set -euo pipefail
EIP="/usr/local/tomcat/webapps/eip"
ROOT="${EIP}/eip-root"

mkdir -p /opt/pilotfish/input/sqlxml /opt/pilotfish/input/examorder \
  /opt/pilotfish/input/staging /opt/pilotfish/output /opt/pilotfish/archive \
  /opt/pilotfish/errors /opt/pilotfish/staging/image \
  /opt/pilotfish/staging/aig /opt/pilotfish/staging/axa \
  /opt/pilotfish/staging/prudential /opt/pilotfish/staging/teledex \
  /opt/pilotfish/staging/captures /usr/local/tomcat/webapps/eip/logs \
  /opt/pilotfish/input/ail /opt/pilotfish/input/PACT /opt/pilotfish/input/PRUX \
  /opt/pilotfish/input/AXA /opt/pilotfish/input/LADDER /opt/pilotfish/input/AIGP \
  /opt/pilotfish/input/AIGLegacy /opt/pilotfish/input/FGLI-resonant \
  /opt/pilotfish/input/ELFP /opt/pilotfish/input/ERIE /opt/pilotfish/input/TDEX \
  /opt/pilotfish/input/GL /opt/pilotfish/input/GLNY /opt/pilotfish/input/NIL \
  /opt/pilotfish/input/LNL /opt/pilotfish/input/LINC /opt/pilotfish/input/METL \
  /opt/pilotfish/input/MLFP /opt/pilotfish/input/METD /opt/pilotfish/input/MLFE \
  /opt/pilotfish/input/GRBR /opt/pilotfish/input/AIE /opt/pilotfish/input/FGLI \
  /opt/pilotfish/input/EQUIT /opt/pilotfish/input/VALICP /opt/pilotfish/input/VALICI \
  /opt/pilotfish/input/UFLA /opt/pilotfish/input/UBOS /opt/pilotfish/input/LADD
# Windows paths hard-coded in a few test listeners
mkdir -p '/usr/local/tomcat/C:\Pilotfish\eip-root\data\in\PACT-1122-POST-TEST' \
  '/usr/local/tomcat/C:\Pilotfish\eip-root\data\in\test-converter' \
  '/usr/local/tomcat/C:\Pilotfish\staging\Teledex\_REPROCESS_INCOMING_ORDERS' \
  '/usr/local/tomcat/C:\Pilotfish\errors' \
  '/usr/local/tomcat/C:\Pilotfish\EOI1122-Test' \
  '/usr/local/tomcat/C:\Pilotfish\staging\holding-AIGLegacy' \
  '/usr/local/tomcat/C:\Pilotfish\staging\holding-ERIE' \
  '/usr/local/tomcat/C:\Pilotfish\staging\holding-ELFP'

if [[ -f /opt/sandbox/environment-settings.conf ]]; then
  cp /opt/sandbox/environment-settings.conf "${ROOT}/environment-settings.conf"
fi

if [[ -d "${ROOT}/lib" ]]; then
  cp -n "${ROOT}/lib/"*.jar "${EIP}/WEB-INF/lib/" 2>/dev/null || true
fi

if [[ -f /opt/sandbox/lib-src/TabDelimitedFileUtil.java ]]; then
  mkdir -p /tmp/tdu
  javac -cp "${EIP}/WEB-INF/lib/xalan-2.7.3.jar" -d /tmp/tdu /opt/sandbox/lib-src/TabDelimitedFileUtil.java
  jar cf "${EIP}/WEB-INF/lib/tabular-file-util-sandbox.jar" -C /tmp/tdu .
fi

chmod -R a+rwX /opt/pilotfish "${EIP}/logs" 2>/dev/null || true
echo "Starting CRL Plus eiPlatform (eip-root bind-mounted)..."
echo "  EIP  : http://localhost:8080/eip/"
exec catalina.sh run
