# Manual Install (Quick Start)

Prefer the interactive installer?

```bash
sudo ./install.sh
```

Or follow the steps below for fully manual setup.

This bundle contains the Raybridge scripts and config templates.

## 0) Prereqs
- Raspberry Pi OS Lite (32-bit) on Pi Zero W
- Orbic with Rayhunter v0.9.0+ already installed
- Pi has Wi-Fi Internet

## 1) Install packages
```bash
sudo apt update
sudo apt install -y jq curl lighttpd msmtp msmtp-mta mailutils cron
sudo systemctl enable --now lighttpd
```

## 2) Create directories
```bash
sudo mkdir -p /opt/raybridge/state /opt/raybridge
sudo mkdir -p /var/www/html/rayhunter/captures
```

## 3) Copy scripts into place
From this bundle directory:
```bash
sudo cp scripts/*.sh /opt/raybridge/
sudo chmod +x /opt/raybridge/*.sh
```

## 4) Configure email (msmtp)
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

## 5) Configure Raybridge env vars
```bash
sudo cp templates/raybridge.env.template /opt/raybridge/raybridge.env
sudo nano /opt/raybridge/raybridge.env
```

## 6) Test scripts (with env)
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

## 7) Cron (recommended)
Edit root crontab:
```bash
sudo crontab -e
```

Add (sources env first):
```cron
*/10 * * * * . /opt/raybridge/raybridge.env; /opt/raybridge/sync_captures.sh >/dev/null 2>&1
*/5 * * * * . /opt/raybridge/raybridge.env; /opt/raybridge/make_dashboard.sh >/dev/null 2>&1
0 8 * * * . /opt/raybridge/raybridge.env; /opt/raybridge/heartbeat.sh >/dev/null 2>&1
```