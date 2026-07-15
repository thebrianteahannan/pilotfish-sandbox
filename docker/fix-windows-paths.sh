#!/bin/sh
# Convert hardcoded Windows PilotFish paths in eip-root to Linux paths.
set -eu

ROOT="${1:-/usr/local/tomcat/webapps/eip/eip-root}"

find "$ROOT" -type f \( -name '*.xml' -o -name '*.conf' -o -name '*.xslt' -o -name '*.txt' -o -name '*.properties' \) \
  | while IFS= read -r file; do
      if grep -Fq 'PilotFish' "$file" 2>/dev/null && grep -Eq 'C:\\PilotFish|C:/PilotFish|C:\\Program Files\\PilotFish|C:/Program Files/PilotFish' "$file" 2>/dev/null; then
        perl -i -pe '
          s#C:\\Program Files\\PilotFish Technology\\eiPlatform Windows\\eip-root#/usr/local/tomcat/webapps/eip/eip-root#g;
          s#C:/Program Files/PilotFish Technology/eiPlatform Windows/eip-root#/usr/local/tomcat/webapps/eip/eip-root#g;
          s#C:\\PilotFish\\#/opt/pilotfish/#g;
          s#C:\\PilotFish#/opt/pilotfish#g;
          s#C:/PilotFish/#/opt/pilotfish/#g;
          s#C:/PilotFish#/opt/pilotfish#g;
          s#\\#/#g;
        ' "$file"
        echo "updated: $file"
      fi
    done

echo "path conversion complete under $ROOT"
SAMPLE="$ROOT/interfaces/Flat File to HL7 and Kickout Reports/routes/1a - PPA Multi/route.xml"
if [ -f "$SAMPLE" ]; then
  echo "sample PollingDirectory lines:"
  grep -n 'PollingDirectory' "$SAMPLE" | head -3 || true
fi
