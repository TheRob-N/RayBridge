#!/bin/bash
set -euo pipefail

# screeninstall.sh — Raybridge kiosk + dimmer setup for Raspberry Pi OS / Debian / Ubuntu
#
# What it does:
#  - Installs a minimal X/desktop stack + LightDM + Chromium (auto-detects package name)
#  - Enables LightDM (so the Pi boots into a GUI login/session)
#  - Writes an LXDE autostart file that launches Raybridge in Chromium kiosk mode
#  - Installs an idle-dimmer loop (dims after inactivity, restores on input)
#
# What it does NOT do:
#  - Install your LCD driver/overlay (model-specific). Do that first.
#
# Optional env overrides:
#   DASH_URL="http://127.0.0.1/rayhunter/"
#   IDLE_SECS=180
#   DIM_LEVEL=0.25
#   BRIGHT_LEVEL=1.0
#
# GOTCHA (important):
#  - On Raspberry Pi OS *Lite* images, there is no GUI stack by default. This script installs:
#      xserver-xorg, xinit, openbox, lightdm, and Chromium.
#    If you still get a black screen after reboot, it’s usually because the LCD driver/overlay
#    is not installed or the display output isn’t configured.

DASH_URL="${DASH_URL:-http://127.0.0.1/rayhunter/}"
IDLE_SECS="${IDLE_SECS:-180}"
DIM_LEVEL="${DIM_LEVEL:-0.25}"
BRIGHT_LEVEL="${BRIGHT_LEVEL:-1.0}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

# Auto-pick a sensible default kiosk user:
# 1) If invoked with sudo, use the original user (SUDO_USER)
# 2) Else fall back to "pi" only if it exists
# 3) Else fall back to the first real login user (UID >= 1000)
DEFAULT_USER=""
if [ -n "${SUDO_USER:-}" ] && getent passwd "${SUDO_USER}" >/dev/null; then
  DEFAULT_USER="${SUDO_USER}"
elif getent passwd pi >/dev/null; then
  DEFAULT_USER="pi"
else
  DEFAULT_USER="$(awk -F: '$3>=1000 && $1!="nobody"{print $1; exit}' /etc/passwd)"
fi

USERNAME="${USERNAME:-$DEFAULT_USER}"

if [ -z "${USERNAME}" ] || ! getent passwd "${USERNAME}" >/dev/null; then
  echo "[!] Could not determine a valid kiosk user." >&2
  echo "    Run with: sudo USERNAME=<youruser> $0" >&2
  exit 2
fi

export DEBIAN_FRONTEND=noninteractive
APT_INSTALL_FLAGS=(-yq -o Dpkg::Options::="--force-confnew")

have_cmd() { command -v "$1" >/dev/null 2>&1; }

pick_chromium_cmd() {
  if have_cmd chromium; then
    echo chromium
    return 0
  fi
  if have_cmd chromium-browser; then
    echo chromium-browser
    return 0
  fi
  echo ""
  return 1
}

pick_chromium_pkg() {
  # Raspberry Pi OS / Debian Bookworm commonly uses "chromium"
  if apt-cache show chromium >/dev/null 2>&1; then
    echo chromium
    return 0
  fi
  # Some Ubuntu variants historically used "chromium-browser" (may be snap-backed)
  if apt-cache show chromium-browser >/dev/null 2>&1; then
    echo chromium-browser
    return 0
  fi
  echo ""
  return 1
}

echo "[+] Updating apt cache..."
apt-get update

echo "[+] Installing kiosk packages (X + LightDM + tools)..."
apt-get "${APT_INSTALL_FLAGS[@]}" install \
  lightdm \
  xserver-xorg \
  xinit \
  openbox \
  xprintidle \
  x11-xserver-utils \
  ca-certificates

# Install Chromium (package name differs across distros)
CHROMIUM_PKG="$(pick_chromium_pkg || true)"
if [[ -z "${CHROMIUM_PKG}" ]]; then
  echo "[!] Chromium package not found in apt repositories (chromium / chromium-browser)." >&2
  echo "    Try: apt-cache search chromium | head" >&2
  exit 3
fi

echo "[+] Installing browser package: ${CHROMIUM_PKG} ..."
apt-get "${APT_INSTALL_FLAGS[@]}" install "${CHROMIUM_PKG}"

CHROME_CMD="$(pick_chromium_cmd || true)"
if [[ -z "${CHROME_CMD}" ]]; then
  echo "[!] Chromium installed but no executable found (chromium/chromium-browser)." >&2
  echo "    Debug: ls -l /usr/bin/chromium* 2>/dev/null || true" >&2
  exit 4
fi
echo "[+] Using browser command: ${CHROME_CMD}"

echo "[+] Enabling display manager (lightdm) ..."
systemctl enable --now lightdm

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
  exit 5
fi

# Prefer Raspberry Pi OS session dir, otherwise fall back to generic LXDE
AUTOSTART_DIR="$HOME_DIR/.config/lxsession/LXDE-pi"
if [ ! -d "$AUTOSTART_DIR" ]; then
  AUTOSTART_DIR="$HOME_DIR/.config/lxsession/LXDE"
fi
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"

install -d -m 0755 "$AUTOSTART_DIR"
cat >"$AUTOSTART_FILE" <<EOF
@xset s off
@xset -dpms
@xset s noblank

@env IDLE_SECS=${IDLE_SECS} DIM_LEVEL=${DIM_LEVEL} BRIGHT_LEVEL=${BRIGHT_LEVEL} /usr/local/bin/raybridge-dimmer.sh

@${CHROME_CMD} \\
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
echo "    User:          ${USERNAME}"
echo "    Browser:       ${CHROME_CMD}"
echo "    Dashboard URL: ${DASH_URL}"
echo "    Dim after:     ${IDLE_SECS}s  (DIM_LEVEL=${DIM_LEVEL}, BRIGHT_LEVEL=${BRIGHT_LEVEL})"
echo
echo "Next:"
echo "  1) Reboot: sudo reboot"
echo "  2) After boot, you should see the dashboard in kiosk mode."
echo
echo "Troubleshooting:"
echo "  - Raspberry Pi OS Lite: this script installs the GUI stack, but you still must install"
echo "    your LCD driver/overlay (Waveshare/DSI/HDMI config) separately."
echo "  - If kiosk doesn't start: check LightDM: sudo systemctl status lightdm --no-pager"
echo "  - If screen is black: confirm LCD overlay/driver and output settings."
