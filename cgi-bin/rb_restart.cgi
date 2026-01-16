#!/bin/sh
# Local-only safe reboot endpoint (POST only)

set -eu

# POST only
[ "${REQUEST_METHOD:-}" = "POST" ] || { echo "Status: 405"; echo; exit 0; }

# Localhost only
case "${REMOTE_ADDR:-}" in
  127.0.0.1|::1) ;;
  *) echo "Status: 403"; echo; exit 0 ;;
esac

echo "Content-Type: application/json"
echo
echo '{"ok":true,"action":"restart"}'

# Reboot in background so we can return HTTP response first
(sudo /sbin/shutdown -r now) >/dev/null 2>&1 &
