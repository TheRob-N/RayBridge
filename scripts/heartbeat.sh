#!/bin/bash
set -euo pipefail

# ---- Config (override via environment variables) ----
TO="${TO:-__SET_ME__}"
ORBIC_BASE="${ORBIC_BASE:-http://192.168.1.1:8080}"
CAPDIR="${CAPDIR:-/var/www/html/rayhunter/captures}"
SEEN="${SEEN:-/opt/raybridge/state/seen.txt}"
# ----------------------------------------------------

if [ "$TO" = "__SET_ME__" ]; then
  echo "ERROR: Set TO (recipient email). Example: TO='you@example.com' /opt/raybridge/heartbeat.sh" >&2
  exit 2
fi

NOW="$(date -Is)"
HOST="$(hostname)"
UP="$(uptime -p || true)"
WLAN="$(ip -4 addr show wlan0 2>/dev/null | awk '/inet /{print $2}' | head -n1 || true)"
USB="$(ip -4 addr show usb0 2>/dev/null | awk '/inet /{print $2}' | head -n1 || true)"
DISK="$(df -h / | awk 'NR==2{print $4 " free of " $2 " (" $5 " used)"}')"

ORBIC_OK="DOWN"
if curl -fsS --max-time 3 "${ORBIC_BASE}/api/qmdl-manifest" >/dev/null 2>&1; then
  ORBIC_OK="OK"
fi

COUNT="0"
if [ -d "$CAPDIR" ]; then
  COUNT="$(ls -1 "$CAPDIR"/*.zip 2>/dev/null | wc -l | tr -d ' ')"
fi

LAST="(none)"
if [ -d "$CAPDIR" ] && ls -1 "$CAPDIR"/*.zip >/dev/null 2>&1; then
  LAST="$(ls -1t "$CAPDIR"/*.zip | head -n1 | xargs -n1 basename)"
fi

SEEN_COUNT="0"
if [ -f "$SEEN" ]; then
  SEEN_COUNT="$(wc -l < "$SEEN" | tr -d ' ')"
fi

PI_IP="${WLAN%%/*}"

SUBJ="raybridge heartbeat: ${HOST} (Orbic ${ORBIC_OK})"
BODY=$(cat <<TXT
Time: ${NOW}
Host: ${HOST}
Uptime: ${UP}
Disk: ${DISK}

wlan0: ${WLAN}
usb0: ${USB}

Orbic API: ${ORBIC_OK} (${ORBIC_BASE})
Bundles on Pi: ${COUNT}
Recordings seen: ${SEEN_COUNT}
Latest bundle: ${LAST}

Dashboard: http://${PI_IP}/rayhunter/
Captures:  http://${PI_IP}/rayhunter/captures/
TXT
)

echo "$BODY" | mail -s "$SUBJ" "$TO"
