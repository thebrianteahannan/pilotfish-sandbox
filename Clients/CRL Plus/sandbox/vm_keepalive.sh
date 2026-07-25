#!/usr/bin/env bash
# Keep the Parallels Windows VM from staying paused (Pause idle is on).
# LaunchAgents often lack HOME/PATH — use absolute paths only.

PRLCTL="/usr/local/bin/prlctl"
VM_NAME="Windows 11 (1)"
LOG="/Users/brianhannan/bin/vm_keepalive.out"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S')  $*" >>"$LOG" 2>/dev/null
}

if [[ ! -x "$PRLCTL" ]]; then
  log "ERROR: prlctl missing at $PRLCTL"
  # Do not exit — KeepAlive would tight-loop; sleep and retry.
  while true; do sleep 60; done
fi

log "keepalive start (prlctl=$PRLCTL)"

while true; do
  st="$("$PRLCTL" status "$VM_NAME" 2>/dev/null || true)"
  if echo "$st" | grep -Eiq 'paused|suspended|stopped'; then
    log "VM not running ($st) — resume/start"
    "$PRLCTL" resume "$VM_NAME" >/dev/null 2>&1
    "$PRLCTL" start "$VM_NAME" >/dev/null 2>&1
  fi
  "$PRLCTL" send-key-event "$VM_NAME" -k 0x2A --event press 2>/dev/null
  "$PRLCTL" send-key-event "$VM_NAME" -k 0x2A --event release 2>/dev/null
  sleep 45
done
