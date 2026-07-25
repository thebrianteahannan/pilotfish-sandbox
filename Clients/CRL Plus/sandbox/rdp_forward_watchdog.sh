#!/usr/bin/env bash
set -euo pipefail
PROXY="/Users/brianhannan/Documents/PilotFish Sandbox/Clients/CRL Plus/sandbox/rdp_forward.py"
LOG="/Users/brianhannan/Documents/PilotFish Sandbox/Clients/CRL Plus/sandbox/rdp_forward.log"
while true; do
  # Keep VM awake if paused
  state=$(prlctl status "Windows 11 (1)" 2>/dev/null || true)
  if echo "$state" | grep -qi paused; then
    prlctl resume "Windows 11 (1)" >/dev/null 2>&1 || true
  fi
  echo "$(date -Iseconds) starting rdp_forward" >>"$LOG"
  python3 "$PROXY" >>"$LOG" 2>&1 || true
  echo "$(date -Iseconds) rdp_forward exited; restarting in 2s" >>"$LOG"
  sleep 2
done
