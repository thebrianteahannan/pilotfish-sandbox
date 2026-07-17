#!/bin/bash
cd "$(dirname "$0")"
IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 'YOUR-MAC-IP')"
echo ""
echo "===================================================="
echo "  Jet's Pizza clone — LAN access"
echo "  On your phone/iPad open:"
echo "    http://${IP}:5173/"
echo "  Keep this window open. Press Ctrl+C to stop."
echo "===================================================="
echo ""
exec python3 -m http.server 5173 --bind 0.0.0.0
