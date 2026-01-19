#!/bin/sh
# RayBridge: safe shutdown endpoint (POST only)
set -eu

# POST only
[ "${REQUEST_METHOD:-}" = "POST" ] || { echo "Status: 405"; echo; exit 0; }

# Localhost + LAN only
case "${REMOTE_ADDR:-}" in
  127.0.0.1|::1|192.168.1.*|::ffff:192.168.1.*) ;;
  *) echo "Status: 403"; echo; exit 0 ;;
esac

echo "Content-Type: application/json"
echo
echo '{"ok":true,"action":"poweroff"}'

# Shutdown in background so we can return HTTP response first
(sudo /sbin/shutdown -h now) >/dev/null 2>&1 &
