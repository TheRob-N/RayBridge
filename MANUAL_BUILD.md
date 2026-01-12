# Raybridge Manual Build Guide

This guide walks you through building Raybridge manually.

## 1. Flash the Pi
- Download Raspberry Pi OS Lite (32-bit)
- Use Raspberry Pi Imager
- Enable SSH and Wi-Fi

## 2. Connect Orbic
Plug Orbic into Pi USB.
Verify:
  ping 192.168.1.1

## 3. Install packages
sudo apt update
sudo apt install -y jq curl lighttpd msmtp msmtp-mta mailutils cron

## 4. Configure email
Edit /etc/msmtprc with your SMTP settings.

## 5. Create directories
sudo mkdir -p /opt/raybridge/state /var/www/html/rayhunter/captures

## 6. Install scripts
Place sync_captures.sh, make_dashboard.sh, heartbeat.sh in /opt/raybridge

## 7. Add cron jobs
*/10 * * * * /opt/raybridge/sync_captures.sh
*/5 * * * * /opt/raybridge/make_dashboard.sh
0 8 * * * /opt/raybridge/heartbeat.sh

## 8. Test
Visit http://<pi-ip>/rayhunter/
