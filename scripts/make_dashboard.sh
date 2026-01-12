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

WLAN="$(ip -4 addr show wlan0 2>/dev/null | awk '/inet /{print $2}' | head -n1 || true)"
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

# List latest 15 bundles
BUNDLES_HTML="(none)"
if [ -d "$CAPDIR" ] && ls -1 "$CAPDIR"/*.zip >/dev/null 2>&1; then
  BUNDLES_HTML="$(ls -1t "$CAPDIR"/*.zip | head -n 15 | while read -r f; do
    b="$(basename "$f")"
    echo "<li><a href=\"/rayhunter/captures/$b\">$b</a></li>"
  done)"
fi

mkdir -p "$(dirname "$OUT")"

cat >"$OUT" <<HTML
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Raybridge Dashboard</title>
  <style>
    body { font-family: sans-serif; margin: 20px; }
    .card { padding: 12px 14px; border: 1px solid #ddd; border-radius: 10px; margin-bottom: 12px; }
    code { background: #f6f6f6; padding: 2px 6px; border-radius: 6px; }
  </style>
</head>
<body>
  <h1>Raybridge Dashboard</h1>

  <div class="card">
    <b>Updated:</b> ${NOW}<br>
    <b>Host:</b> ${HOST}<br>
    <b>Uptime:</b> ${UP}<br>
    <b>Disk:</b> ${DISK}<br>
    <b>wlan0:</b> ${WLAN}<br>
    <b>usb0:</b> ${USB}<br>
    <b>Orbic API:</b> ${ORBIC_OK} (${ORBIC_BASE})<br>
    <b>Latest bundle:</b> ${LAST_SYNC}<br>
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
