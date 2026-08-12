#!/usr/bin/env bash
# Compatibility wrapper — XML→EDI 834 lives under Clients/Demos/xml-to-edi-834/
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${ROOT}/Clients/Demos/xml-to-edi-834/docker-run.sh" "$@"
