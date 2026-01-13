#!/bin/bash
set -euo pipefail

# Raybridge interactive installer (manual-friendly)
# - Installs dependencies
# - Copies scripts to /opt/raybridge
# - Sets up lighttpd capture directory
# - Creates /etc/msmtprc from prompts (or you can skip and edit later)
# - Creates /opt/raybridge/raybridge.env from prompts
# - Optionally installs root cron entries

echo "Ensuring USB tether cannot steal the network..."
bash scripts/fix-usb-routing.sh || true


require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root: sudo $0" >&2
    exit 1
  fi
}

prompt_default() {
  local var="$1"
  local prompt="$2"
  local def="$3"
  local val
  read -r -p "$prompt [$def]: " val
  if [ -z "$val" ]; then
    val="$def"
  fi
  printf -v "$var" "%s" "$val"
}

prompt_secret() {
  local var="$1"
  local prompt="$2"
  local val
  read -r -s -p "$prompt: " val
  echo
  printf -v "$var" "%s" "$val"
}

require_root

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[+] Raybridge installer starting..."
echo "    Bundle dir: $SCRIPT_DIR"

echo "[+] Installing packages..."
apt update
apt install -y jq curl lighttpd msmtp msmtp-mta mailutils cron ca-certificates

echo "[+] Creating directories..."
mkdir -p /opt/raybridge/state /opt/raybridge
mkdir -p /var/www/html/rayhunter/captures
systemctl enable --now lighttpd

echo "[+] Copying scripts..."
cp -f "$SCRIPT_DIR/scripts/"*.sh /opt/raybridge/
chmod +x /opt/raybridge/*.sh

echo
echo "[+] Create /opt/raybridge/raybridge.env (config used by cron and scripts)"
prompt_default ORBIC_BASE "Orbic/Rayhunter base URL" "http://192.168.1.1:8080"
prompt_default OUT_DIR "Capture output dir" "/var/www/html/rayhunter/captures"
prompt_default STATE_DIR "State dir" "/opt/raybridge/state"
prompt_default TO "Heartbeat recipient email" "you@example.com"

cat >/opt/raybridge/raybridge.env <<EOF
# raybridge.env
ORBIC_BASE="${ORBIC_BASE}"
OUT_DIR="${OUT_DIR}"
STATE_DIR="${STATE_DIR}"
TO="${TO}"
EOF
chmod 600 /opt/raybridge/raybridge.env

echo
echo "[+] Configure email sending with msmtp"
echo "    You can skip this and edit /etc/msmtprc later if you prefer."
read -r -p "Configure /etc/msmtprc now? (y/N): " DO_MAIL
DO_MAIL="${DO_MAIL:-N}"

if [[ "$DO_MAIL" =~ ^[Yy]$ ]]; then
  prompt_default SMTP_HOST "SMTP host" "smtp.gmail.com"
  prompt_default SMTP_PORT "SMTP port" "587"
  prompt_default FROM_ADDR "From address" "${TO}"
  prompt_default SMTP_USER "SMTP username" "${FROM_ADDR}"
  prompt_secret  SMTP_PASS "SMTP password (for Gmail use an App Password)"

  cat >/etc/msmtprc <<EOF
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile /var/log/msmtp.log

account smtp
host ${SMTP_HOST}
port ${SMTP_PORT}
from ${FROM_ADDR}
user ${SMTP_USER}
password ${SMTP_PASS}

account default : smtp
EOF
  chown root:root /etc/msmtprc
  chmod 600 /etc/msmtprc

  echo "[+] Testing email..."
  if echo "Raybridge msmtp test from $(hostname) at $(date -Is)" | mail -s "raybridge: mail test" "${TO}"; then
    echo "    Mail sent (check inbox/spam)."
  else
    echo "    Mail test failed. Review /var/log/msmtp.log and /etc/msmtprc" >&2
  fi
else
  echo "    Skipped /etc/msmtprc creation."
  echo "    Template is in templates/msmtprc.template"
fi

echo
echo "[+] Prime dashboard once (optional)"
set -a
# shellcheck disable=SC1091
source /opt/raybridge/raybridge.env
set +a
/opt/raybridge/make_dashboard.sh || true

echo
echo "[+] Set up cron (root) to automate sync/dashboard/heartbeat"
echo "    - Sync captures every 10 minutes"
echo "    - Update dashboard every 5 minutes"
echo "    - Heartbeat daily at 08:00"
read -r -p "Install cron entries now? (y/N): " DO_CRON
DO_CRON="${DO_CRON:-N}"

if [[ "$DO_CRON" =~ ^[Yy]$ ]]; then
  TMP_CRON="$(mktemp)"
  crontab -l 2>/dev/null > "$TMP_CRON" || true

  # Remove old raybridge lines if present
  grep -v "raybridge.env; /opt/raybridge/" "$TMP_CRON" > "${TMP_CRON}.new" || true
  mv "${TMP_CRON}.new" "$TMP_CRON"

  cat >>"$TMP_CRON" <<'EOF'

# --- Raybridge ---
*/10 * * * * . /opt/raybridge/raybridge.env; /opt/raybridge/sync_captures.sh >/dev/null 2>&1
*/5 * * * * . /opt/raybridge/raybridge.env; /opt/raybridge/make_dashboard.sh >/dev/null 2>&1
0 8 * * * . /opt/raybridge/raybridge.env; /opt/raybridge/heartbeat.sh >/dev/null 2>&1
# --- /Raybridge ---

EOF
  crontab "$TMP_CRON"
  rm -f "$TMP_CRON"
  echo "    Cron installed."
else
  echo "    Cron not installed. See docs/MANUAL_INSTALL.md for entries."
fi


echo
echo "[+] Optional: LCD kiosk mode (Chromium dashboard + dimmer)"
echo "    If you have a small LCD and have already installed its driver/overlay,"
echo "    this will configure the Pi to boot into the Raybridge dashboard."
read -r -p "Run screeninstall.sh now? (y/N): " DO_SCREEN
DO_SCREEN="${DO_SCREEN:-N}"
if [[ "$DO_SCREEN" =~ ^[Yy]$ ]]; then
  if [ -f "$SCRIPT_DIR/screeninstall.sh" ]; then
    bash "$SCRIPT_DIR/screeninstall.sh"
  else
    echo "screeninstall.sh not found in bundle directory. Skipping." >&2
  fi
fi

echo
echo "[✓] Done."
echo "Dashboard:  http://<pi-ip>/rayhunter/"
echo "Captures:   http://<pi-ip>/rayhunter/captures/"
echo "Notes:"
echo " - If email fails, check /var/log/msmtp.log"
echo " - If Orbic isn't reachable, confirm usb0 is up and ping 192.168.1.1"
