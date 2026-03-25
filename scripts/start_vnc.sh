#!/usr/bin/env bash
set -euo pipefail
# load env if present
source "$(dirname "$0")/_env_loader.sh"

SESSION=${1:-debug}
DISPLAY_VAL=${2:-${VNC_DISPLAY:-:99}}
RES=${3:-${VNC_RESOLUTION:-1366x768}}
WORKDIR=/tmp/${SESSION}_vnc
LOG=${TMP_LOG_DIR:-/tmp}/x11vnc_${SESSION}.log
mkdir -p "$WORKDIR"
export DISPLAY="$DISPLAY_VAL"
# Launch Xvfb if not present
if ! pgrep -f "Xvfb $DISPLAY_VAL" >/dev/null 2>&1; then
  Xvfb "$DISPLAY_VAL" -screen 0 ${RES}x24 &> "$LOG" &
  echo "Xvfb started on $DISPLAY_VAL"
  sleep 1
fi
# Start fluxbox if available
if command -v fluxbox >/dev/null 2>&1; then
  if ! pgrep -f "fluxbox" >/dev/null 2>&1; then
    fluxbox &>> "$LOG" &
    sleep 0.5
  fi
fi
# Determine VNC implementation and passfile handling
VNC_PASS_FILE=${VNC_PASSFILE:-${WORKDIR}/vncpasswd}
VNC_IMPL=${VNC_IMPLEMENTATION:-auto}

echo "Using VNC implementation: $VNC_IMPL"
# If passfile already exists, prefer it
if [ -f "$VNC_PASS_FILE" ]; then
  echo "Using existing VNC passfile: $VNC_PASS_FILE"
else
  # create directory
  mkdir -p "$(dirname "$VNC_PASS_FILE")"
  # If no password in env, prompt user securely (do not echo)
  if [ -z "${VNC_PASSWORD:-}" ]; then
    echo "No VNC password configured."
    # Prompt user to select implementation if auto
    if [ "${VNC_IMPL}" = "auto" ]; then
      echo
      echo "Select VNC implementation (enter number):"
      echo "  1) tigervnc"
      echo "  2) tightvnc"
      echo "  3) realvnc"
      read -p "Choice [1-3] (default 1): " choice
      case "$choice" in
        2) VNC_IMPL=tightvnc ;;
        3) VNC_IMPL=realvnc ;;
        *) VNC_IMPL=tigervnc ;;
      esac
    else
      echo "VNC implementation: $VNC_IMPL (from .env)"
    fi

    # prompt for password without echo, with up to 3 retries
    retries=0
    while [ $retries -lt 3 ]; do
      echo -n "Enter VNC password (input hidden): "
      read -s USER_VNC_PW || true
      echo
      echo -n "Confirm VNC password: "
      read -s USER_VNC_PW2 || true
      echo
      if [ "$USER_VNC_PW" = "$USER_VNC_PW2" ] && [ -n "$USER_VNC_PW" ]; then
        VNC_PASSWORD="$USER_VNC_PW"
        break
      fi
      echo "Passwords do not match or empty — try again." >&2
      retries=$((retries+1))
    done
    if [ -z "${VNC_PASSWORD:-}" ]; then
      echo "Failed to set VNC password after retries. Aborting." >&2
      exit 1
    fi
  fi

  # Now write passfile according to implementation
  case "$VNC_IMPL" in
    tigervnc|tightvnc)
      if command -v vncpasswd >/dev/null 2>&1; then
        echo "Detected vncpasswd; generating rfbauth using vncpasswd"
        # use vncpasswd binary but avoid printing password
        printf '%s\n%s\n' "$VNC_PASSWORD" "$VNC_PASSWORD" | vncpasswd -f > "$VNC_PASS_FILE" || true
        echo "Wrote rfbauth to $VNC_PASS_FILE"
      else
        echo "vncpasswd not found; writing plain passfile (less secure)" >&2
        echo "$VNC_PASSWORD" > "$VNC_PASS_FILE"
        echo "Wrote plain passfile to $VNC_PASS_FILE (consider installing tigervnc/tightvnc for rfbauth)" >&2
      fi
      ;;
    realvnc)
      echo "RealVNC selected. Recommended: generate password with realvnc tools and set VNC_PASSFILE in .env to the realvnc-managed password file."
      read -p "Create a local fallback passfile now? (y/N): " create_fallback
      if [[ "$create_fallback" = "y" || "$create_fallback" = "Y" ]]; then
        echo "Writing local fallback passfile at $VNC_PASS_FILE (may not integrate with realvnc service)"
        echo "$VNC_PASSWORD" > "$VNC_PASS_FILE"
      else
        echo "Skipping local passfile creation. Please set VNC_PASSFILE in .env to a valid realvnc password file and restart";
      fi
      ;;
    *)
      echo "Unknown VNC_IMPLEMENTATION '$VNC_IMPL' — defaulting to tigervnc behavior"
      if command -v vncpasswd >/dev/null 2>&1; then
        printf '%s\n%s\n' "$VNC_PASSWORD" "$VNC_PASSWORD" | vncpasswd -f > "$VNC_PASS_FILE" || true
      else
        echo "$VNC_PASSWORD" > "$VNC_PASS_FILE"
      fi
      ;;
  esac
  chmod 600 "$VNC_PASS_FILE" || true
fi

# Start x11vnc
if ! pgrep -f "x11vnc.*${DISPLAY_VAL}" >/dev/null 2>&1; then
  setsid x11vnc -display "$DISPLAY_VAL" -rfbauth "$VNC_PASS_FILE" -forever -shared -o "$LOG" &
  echo "x11vnc started (log: $LOG)"
fi

# Report actual listening sockets for VNC (helpful when DISPLAY -> port mapping varies)
# Print complete info: process line, listening sockets, and inferred port
echo "--- VNC listener inspection ---"
# process info
pid=$(pgrep -f "x11vnc.*${DISPLAY_VAL}" | head -n1 || true)
if [ -n "$pid" ]; then
  ps -o pid,cmd -p "$pid" 2>/dev/null || true
else
  echo "(no x11vnc process found)"
fi
# list listening TCP sockets for x11vnc (if any)
ss -ltnp 2>/dev/null | egrep ':(5900|5901|59[0-9]{2})\s' || true
# Try to extract the listening port for the x11vnc pid (prefer IPv4)
LISTEN_PORT=""
if [ -n "$pid" ]; then
  # search ss lines for this pid and extract the port number
  LISTEN_PORT=$(ss -ltnp 2>/dev/null | grep -F "pid=$pid" | sed -n 's/.*:\([0-9]\{4,5\}\) .*/\1/p' | head -n1 || true)
fi
# fallback: try to infer port from display number
DISPLAY_NUM=${DISPLAY_VAL#:}
if [ -z "$LISTEN_PORT" ] && [[ "$DISPLAY_NUM" =~ ^[0-9]+$ ]]; then
  INFER_PORT=$((5900 + DISPLAY_NUM))
  LISTEN_PORT="${INFER_PORT} (inferred)"
fi
if [ -n "$LISTEN_PORT" ]; then
  echo "VNC listening on port: $LISTEN_PORT"
else
  echo "VNC listening port: unknown"
fi

echo "--- end VNC listener inspection ---"

echo "VNC session $SESSION on display $DISPLAY_VAL started. VNC pass file: $VNC_PASS_FILE"