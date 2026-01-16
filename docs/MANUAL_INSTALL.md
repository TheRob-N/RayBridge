# Manual Install (Quick Start)

Prefer the interactive installer?

```bash
sudo ./install.sh
```

Or follow the steps below for fully manual setup.

This bundle contains the Raybridge scripts, LCD UI, and config templates.

## 0) Prereqs
- Raspberry Pi OS Lite (32-bit) on Pi Zero W / Pi 4
- Orbic with Rayhunter installed
- Pi has Wi-Fi Internet

## 1) Install packages
```bash
sudo apt update
sudo apt install -y jq curl lighttpd msmtp msmtp-mta mailutils cron ca-certificates
sudo systemctl enable --now lighttpd
```

## 2) Create directories
```bash
sudo mkdir -p /opt/raybridge/state /opt/raybridge
sudo mkdir -p /var/www/html/rayhunter/captures
```

## 3) Install Rayhunter web UI (dashboard + LCD)
From this bundle directory:
```bash
sudo mkdir -p /var/www/html/rayhunter
sudo cp -a web/rayhunter/* /var/www/html/rayhunter/
```

LCD:
- http://<pi-ip>/rayhunter/lcd/

## 4) Install CGI endpoints for LCD Power / Restart
These endpoints are **localhost-only** (so remote users can’t reboot/shutdown your Pi from the web UI).

From this bundle directory:
```bash
sudo mkdir -p /usr/lib/cgi-bin
sudo cp -f cgi-bin/*.cgi /usr/lib/cgi-bin/
sudo chmod +x /usr/lib/cgi-bin/*.cgi

sudo lighty-enable-mod cgi || true
sudo systemctl restart lighttpd
```

Allow `www-data` to run shutdown/reboot (CGI scripts still enforce localhost-only):
```bash
sudo tee /etc/sudoers.d/raybridge-power >/dev/null <<'SUDOEOF'
www-data ALL=NOPASSWD: /sbin/shutdown -h now
www-data ALL=NOPASSWD: /sbin/shutdown -r now
SUDOEOF
sudo chmod 440 /etc/sudoers.d/raybridge-power
```

## 5) Copy scripts into place
From this bundle directory:
```bash
sudo cp scripts/*.sh /opt/raybridge/
sudo chmod +x /opt/raybridge/*.sh
```

## 6) Configure email (msmtp)
Copy the template and edit:
```bash
sudo cp templates/msmtprc.template /etc/msmtprc
sudo nano /etc/msmtprc
sudo chown root:root /etc/msmtprc
sudo chmod 600 /etc/msmtprc
```

Test mail:
```bash
echo "raybridge mail test" | mail -s "raybridge: mail ok" you@example.com
```

## 7) Configure Raybridge env vars
```bash
sudo cp templates/raybridge.env.template /opt/raybridge/raybridge.env
sudo nano /opt/raybridge/raybridge.env
```

## 8) Test scripts (with env)
```bash
set -a
source /opt/raybridge/raybridge.env
set +a

sudo -E /opt/raybridge/sync_captures.sh
sudo -E /opt/raybridge/make_dashboard.sh
sudo -E /opt/raybridge/heartbeat.sh
```

Dashboard:
- http://<pi-ip>/rayhunter/
Captures:
- http://<pi-ip>/rayhunter/captures/

## 9) Cron (recommended)
Edit root crontab:
```bash
sudo crontab -e
```

Add:
```cron
# --- Raybridge ---
*/10 * * * * . /opt/raybridge/raybridge.env; /opt/raybridge/sync_captures.sh >/dev/null 2>&1
*/5 * * * * . /opt/raybridge/raybridge.env; /opt/raybridge/make_dashboard.sh >/dev/null 2>&1
0 8 * * * . /opt/raybridge/raybridge.env; /opt/raybridge/heartbeat.sh >/dev/null 2>&1
0 3 * * * /sbin/shutdown -r now >/dev/null 2>&1
# --- /Raybridge ---
```
