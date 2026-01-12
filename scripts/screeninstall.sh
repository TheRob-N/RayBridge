#!/bin/bash
set -euo pipefail

# screeninstall.sh — Raybridge kiosk + dimmer setup for Raspberry Pi OS
#
# What it does:
#  - Installs minimal GUI + LightDM + Chromium (if not already present)
#  - Sets up LXDE autostart to launch Raybridge dashboard in Chromium kiosk mode
#  - Installs an idle-dimmer service (dims screen after inactivity, restores on input)
#
# What it does NOT do:
#  - Install your 3.5" LCD kernel/DT overlay driver (model-specific). Do that first.
#
# Usage:
#   sudo ./screeninstall.sh
#
# Optional environment overrides:
#   DASH_URL="http://127.0.0.1/rayhunter/"
#   IDLE_SECS=180
#   DIM_LEVEL=0.25
#   BRIGHT_LEVEL=1.0
#   USERNAME=pi

DASH_URL="${DASH_URL:-http://127.0.0.1/rayhunter/}"
IDLE_SECS="${IDLE_SECS:-180}"
DIM_LEVEL="${DIM_LEVEL:-0.25}"
BRIGHT_LEVEL="${BRIGHT_LEVEL:-1.0}"
USERNAME="${USERNAME:-pi}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

echo "[+] Installing kiosk packages (GUI + Chromium) ..."
apt update
apt install -y \
  xserver-xorg xinit \
  lightdm raspberrypi-ui-mods \
  chromium-browser \
  xprintidle x11-xserver-utils

echo "[+] Enabling display manager (lightdm) ..."
systemctl enable lightdm

echo "[+] Installing dimmer script ..."
install -d /usr/local/bin
cat >/usr/local/bin/raybridge-dimmer.sh <<'EOF'
#!/bin/bash
set -euo pipefail

# Dims the first connected display output after idle time, restores on activity.
IDLE_SECS="${IDLE_SECS:-180}"
DIM_LEVEL="${DIM_LEVEL:-0.25}"
BRIGHT_LEVEL="${BRIGHT_LEVEL:-1.0}"

export DISPLAY="${DISPLAY:-:0}"

OUTPUT="$(xrandr 2>/dev/null | awk '/ connected/{print $1; exit}')"
if [ -z "${OUTPUT:-}" ]; then
  exit 0
fi

dimmed="no"
while true; do
  idle_ms="$(xprintidle 2>/dev/null || echo 0)"
  idle_s=$((idle_ms / 1000))

  if [ "$idle_s" -ge "$IDLE_SECS" ]; then
    if [ "$dimmed" != "yes" ]; then
      xrandr --output "$OUTPUT" --brightness "$DIM_LEVEL" || true
      dimmed="yes"
    fi
  else
    if [ "$dimmed" = "yes" ]; then
      xrandr --output "$OUTPUT" --brightness "$BRIGHT_LEVEL" || true
      dimmed="no"
    fi
  fi

  sleep 2
done
EOF
chmod +x /usr/local/bin/raybridge-dimmer.sh

echo "[+] Writing LXDE autostart for user: $USERNAME"
HOME_DIR="$(getent passwd "$USERNAME" | cut -d: -f6)"
if [ -z "${HOME_DIR:-}" ] || [ ! -d "$HOME_DIR" ]; then
  echo "Could not determine home directory for user '$USERNAME'." >&2
  exit 2
fi

AUTOSTART_DIR="$HOME_DIR/.config/lxsession/LXDE-pi"
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"

install -d -m 0755 "$AUTOSTART_DIR"
cat >"$AUTOSTART_FILE" <<EOF
@xset s off
@xset -dpms
@xset s noblank

@env IDLE_SECS=${IDLE_SECS} DIM_LEVEL=${DIM_LEVEL} BRIGHT_LEVEL=${BRIGHT_LEVEL} /usr/local/bin/raybridge-dimmer.sh

@chromium-browser \\
  --kiosk \\
  --incognito \\
  --disable-infobars \\
  --noerrdialogs \\
  --disable-session-crashed-bubble \\
  ${DASH_URL}
EOF

chown -R "$USERNAME:$USERNAME" "$HOME_DIR/.config"
chmod 0644 "$AUTOSTART_FILE"

echo
echo "[✓] Kiosk configured."
echo "    Dashboard URL: $DASH_URL"
echo "    Dim after:     ${IDLE_SECS}s  (DIM_LEVEL=${DIM_LEVEL}, BRIGHT_LEVEL=${BRIGHT_LEVEL})"
echo
echo "Next:"
echo "  1) Reboot: sudo reboot"
echo "  2) After boot, you should see Chromium kiosk on the LCD."
echo
echo "Troubleshooting:"
echo "  - If you get a black screen, confirm your LCD driver/overlay is installed."
echo "  - If Chromium doesn't start, verify user '$USERNAME' logs into LXDE (LightDM)."
