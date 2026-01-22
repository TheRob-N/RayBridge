#!/bin/bash
set -euo pipefail

# Raybridge LCD status generator
# Writes: /var/www/html/rayhunter/lcd/status.json

OUT_DIR="/var/www/html/rayhunter/lcd"
OUT_FILE="${OUT_DIR}/status.json"

# Defaults (can be overridden by /opt/raybridge/raybridge.env)
CAP_DIR_DEFAULT="/var/www/html/rayhunter/captures"
STATE_DIR_DEFAULT="/opt/raybridge/state"
ORBIC_URL_DEFAULT="http://192.168.1.1:8080"
ORBIC_IFACE_DEFAULT="usb0"

# Load config if present
ENV_FILE="/opt/raybridge/raybridge.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

CAP_DIR="${CAP_DIR:-$CAP_DIR_DEFAULT}"
STATE_DIR="${STATE_DIR:-$STATE_DIR_DEFAULT}"

ALERT_FLAG="${ALERT_FLAG:-$STATE_DIR/alert.flag}"
ALERT_MSG_FILE="${ALERT_MSG_FILE:-$STATE_DIR/alert.msg}"
LAST_EVENT_FILE="${LAST_EVENT_FILE:-$STATE_DIR/last_event.iso}"
VERSION_FILE="${VERSION_FILE:-/opt/raybridge/VERSION}"

# Demo overlay state (written by demo CGI endpoints)
DEMO_FILE="${DEMO_FILE:-$STATE_DIR/demo.json}"

# Orbic / Rayhunter reachability
ORBIC_URL="${ORBIC_URL:-$ORBIC_URL_DEFAULT}"
ORBIC_IFACE="${ORBIC_IFACE:-$ORBIC_IFACE_DEFAULT}"

mkdir -p "$OUT_DIR" "$STATE_DIR"

# Reachability: force traffic out usb0 to avoid wlan0/usb0 same-subnet ambiguity
ORBIC_OK="false"
if curl -fsS --interface "$ORBIC_IFACE" --max-time 2 "${ORBIC_URL}/" >/dev/null 2>&1; then
  ORBIC_OK="true"
fi

# Last sync: newest capture file mtime as proxy (fallback to "now")
NOW_ISO="$(date -Is)"

LAST_SYNC="$NOW_ISO"
if [ -d "$CAP_DIR" ]; then
  newest="$(ls -t "$CAP_DIR" 2>/dev/null | head -n 1 || true)"
  if [ -n "$newest" ] && [ -f "$CAP_DIR/$newest" ]; then
    LAST_SYNC="$(date -Is -r "$CAP_DIR/$newest" 2>/dev/null || true)"
  fi
fi

# Capture count
CAP_COUNT=0
if [ -d "$CAP_DIR" ]; then
  CAP_COUNT="$(find "$CAP_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
fi

# Alert state (set by your detection pipeline)
ALERT_ACTIVE="false"
ALERT_MESSAGE=""
if [ -f "$ALERT_FLAG" ]; then
  ALERT_ACTIVE="true"
  if [ -f "$ALERT_MSG_FILE" ]; then
    ALERT_MESSAGE="$(head -n 1 "$ALERT_MSG_FILE" | tr -d '\r')"
  fi
fi

# Last event timestamp (optional)
LAST_EVENT=""
if [ -f "$LAST_EVENT_FILE" ]; then
  LAST_EVENT="$(head -n 1 "$LAST_EVENT_FILE" | tr -d '\r')"
fi

# Version (optional)
VER="0.9-beta"
if [ -f "$VERSION_FILE" ]; then
  VER="$(head -n 1 "$VERSION_FILE" | tr -d '\r')"
fi

# Health heuristic (base)
HEALTH="degraded"
SUMMARY="CHECK SYSTEM"

if [ "$ORBIC_OK" = "true" ]; then
  HEALTH="ok"
  SUMMARY="Nominal"
fi

if [ "$ALERT_ACTIVE" = "true" ]; then
  HEALTH="alert"
  SUMMARY="ALERT ACTIVE"
fi

tmp="$(mktemp)"

# Write base JSON (proper escaping) using env vars (portable)
export RB_VER="$VER"
export RB_HEALTH="$HEALTH"
export RB_SUMMARY="$SUMMARY"
export RB_ORBIC_OK="$ORBIC_OK"
export RB_LAST_SYNC="$LAST_SYNC"
export RB_CAP_COUNT="$CAP_COUNT"
export RB_LAST_EVENT="$LAST_EVENT"
export RB_ALERT_ACTIVE="$ALERT_ACTIVE"
export RB_ALERT_MESSAGE="$ALERT_MESSAGE"

python3 - <<'PY' >"$tmp"
import json, os, sys

def to_bool(s: str) -> bool:
    return str(s).strip().lower() in ("1", "true", "yes", "y", "on")

def empty_to_none(s: str):
    s = (s or "").strip()
    return None if s == "" else s

cap_count_raw = (os.environ.get("RB_CAP_COUNT", "0") or "0").strip()
try:
    cap_count = int(cap_count_raw)
except Exception:
    cap_count = 0

data = {
  "version": os.environ.get("RB_VER", "dev"),
  "health": os.environ.get("RB_HEALTH", "unknown"),
  "summary": os.environ.get("RB_SUMMARY", ""),
  "orbic_reachable": to_bool(os.environ.get("RB_ORBIC_OK", "false")),
  "last_sync": empty_to_none(os.environ.get("RB_LAST_SYNC", "")),
  "capture_count": cap_count,
  "last_event": empty_to_none(os.environ.get("RB_LAST_EVENT", "")),
  "alert_active": to_bool(os.environ.get("RB_ALERT_ACTIVE", "false")),
  "alert_message": os.environ.get("RB_ALERT_MESSAGE", ""),
}

json.dump(data, sys.stdout, indent=2)
print()
PY

# --- DEMO overlay (optional) ---
python3 - <<'PY' "$tmp" "$DEMO_FILE"
import json, sys, time

out_json = sys.argv[1]
demo_file = sys.argv[2]

try:
    with open(out_json, "r") as f:
        s = json.load(f)
except Exception:
    s = {}

try:
    with open(demo_file, "r") as f:
        demo = json.load(f)
except Exception:
    demo = {}

now = int(time.time())
active = bool(demo.get("active")) and int(demo.get("until", 0) or 0) > now

if active:
    msg = (demo.get("message") or "STINGRAY DETECTED • DEMO").strip()
    s["alert_active"] = True
    s["health"] = "alert"
    s["summary"] = msg
    s["alert_message"] = msg

with open(out_json, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
PY

mv "$tmp" "$OUT_FILE"
chmod 0644 "$OUT_FILE"
