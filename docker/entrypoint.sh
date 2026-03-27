#!/usr/bin/env bash
set -euo pipefail
cd /opt/headful-browser-vnc
# load .env if present
if [ -f ".env" ]; then
  set -a; . ./.env; set +a
fi
SESSION=${1:-debug}
DISPLAY_VAL=${2:-${VNC_DISPLAY:-:99}}
RES=${3:-${VNC_RESOLUTION:-1366x768}}
# start VNC
./scripts/start_vnc.sh "$SESSION" "$DISPLAY_VAL" "$RES"
# keep container alive (supervisor or tail on log)
tail -f /tmp/x11vnc_${SESSION}.log
