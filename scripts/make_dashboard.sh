#!/bin/bash
set -euo pipefail

# ---- Config (override via environment variables) ----
ORBIC_BASE="${ORBIC_BASE:-http://192.168.1.1:8080}"
OUT="${OUT:-/var/www/html/rayhunter/index.html}"
CAPDIR="${CAPDIR:-/var/www/html/rayhunter/captures}"
# ----------------------------------------------------

NOW="$(date -Is)"
HOST="$(hostname)"
UP="$(uptime -p || true)"

# Prefer active uplink IP if possible (still works on Wi-Fi portable)
UPLINK_IF="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
if [ -z "${UPLINK_IF:-}" ]; then UPLINK_IF="wlan0"; fi
UPLINK_IP="$(ip -4 addr show "$UPLINK_IF" 2>/dev/null | awk '/inet /{print $2}' | head -n1 || true)"
USB="$(ip -4 addr show usb0 2>/dev/null | awk '/inet /{print $2}' | head -n1 || true)"
DISK="$(df -h / | awk 'NR==2{print $4 " free of " $2 " (" $5 " used)"}')"

ORBIC_OK="DOWN"
if curl -fsS --max-time 3 "${ORBIC_BASE}/api/qmdl-manifest" >/dev/null 2>&1; then
  ORBIC_OK="OK"
fi

LAST_SYNC="(none)"
if [ -d "$CAPDIR" ] && ls -1 "$CAPDIR"/*.zip >/dev/null 2>&1; then
  LAST_SYNC="$(ls -1t "$CAPDIR"/*.zip | head -n1 | xargs -n1 basename)"
fi

# Recent capture list
BUNDLES_HTML="(none)"
if [ -d "$CAPDIR" ] && ls -1 "$CAPDIR"/*.zip >/dev/null 2>&1; then
  BUNDLES_HTML="$(ls -1t "$CAPDIR"/*.zip | head -n 12 | while read -r f; do
    b="$(basename "$f")"
    echo "<li><a href=\"/rayhunter/captures/$b\">$b</a></li>"
  done)"
fi

# --- ALERT LOGIC ---
# Rayhunter event endpoint differs by build; try a couple common ones.
EVENT_JSON=""
for ep in "/events" "/api/events" "/api/alerts"; do
  if EVENT_JSON="$(curl -fsS --max-time 3 "${ORBIC_BASE}${ep}" 2>/dev/null)"; then
    break
  fi
done

ALERT_ACTIVE="no"
ALERT_LINES="(none)"
if [ -n "${EVENT_JSON:-}" ]; then
  # Look for 'severity' == 'high' OR 'level' == 'high' OR 'risk' == 'high'
  # Keep it defensive: if schema changes, it just shows no alerts.
  ALERT_LINES="$(printf "%s" "$EVENT_JSON" \
    | jq -r '
      (.. | objects) as $o
      | select(($o.severity? // $o.level? // $o.risk? // "") | ascii_downcase == "high")
      | "\(($o.timestamp // $o.time // $o.date // "time?")) — \(($o.name // $o.type // $o.event // "high event"))"
    ' 2>/dev/null | tail -n 8 || true)"

  if [ -n "${ALERT_LINES:-}" ] && [ "${ALERT_LINES}" != "(none)" ]; then
    ALERT_ACTIVE="yes"
  else
    ALERT_LINES="(none)"
  fi
fi

ALERT_BANNER=""
if [ "$ALERT_ACTIVE" = "yes" ]; then
  ALERT_BANNER='<div class="alert">⚠️ ALERT: Suspicious cellular behavior detected (HIGH severity)</div>'
fi

mkdir -p "$(dirname "$OUT")"

cat >"$OUT" <<HTML
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="15">
  <title>Raybridge Dashboard</title>
  <style>
    body { font-family: sans-serif; margin: 20px; background: #0b0d10; color: #e6e6e6; }
    a { color: #7ee787; }
    .card { padding: 12px 14px; border: 1px solid #2a2f36; border-radius: 10px; margin-bottom: 12px; background: #10141a; }
    .alert {
      padding: 16px 18px;
      border-radius: 12px;
      margin-bottom: 14px;
      font-weight: 800;
      font-size: 22px;
      letter-spacing: 0.4px;
      background: #a40000;
      border: 2px solid #ff4d4d;
      color: #fff;
      text-align: center;
    }
    pre { white-space: pre-wrap; margin: 0; }
    .muted { color: #aab2bf; }
  </style>
</head>
<body>
  <h1>Raybridge</h1>
  ${ALERT_BANNER}

  <div class="card">
    <b>Updated:</b> ${NOW}<br>
    <b>Host:</b> ${HOST}<br>
    <b>Uptime:</b> ${UP}<br>
    <b>Disk:</b> ${DISK}<br>
    <b>Uplink:</b> ${UPLINK_IF} ${UPLINK_IP}<br>
    <b>usb0:</b> ${USB}<br>
    <b>Orbic API:</b> ${ORBIC_OK} (${ORBIC_BASE})<br>
    <b>Latest bundle:</b> ${LAST_SYNC}<br>
    <div class="muted">Auto-refresh: 15s</div>
  </div>

  <div class="card">
    <h2>High severity events (tail)</h2>
    <pre>${ALERT_LINES}</pre>
  </div>

  <div class="card">
    <h2>Recent capture bundles</h2>
    <ul>
      ${BUNDLES_HTML}
    </ul>
    <p><a href="/rayhunter/captures/">Browse all captures</a></p>
  </div>

  <div class="card">
    <h2>Links</h2>
    <ul>
      <li><a href="${ORBIC_BASE}/">Orbic Rayhunter UI</a></li>
      <li><a href="/rayhunter/captures/">Pi captures directory</a></li>
    </ul>
  </div>
</body>
</html>
HTML
