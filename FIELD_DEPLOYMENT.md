# Raybridge Field Deployment Guide

This guide covers full end-to-end deployment of Raybridge in the field.

## 1. Hardware Prep
- Orbic hotspot with Rayhunter v0.9.0 installed
- Raspberry Pi Zero W
- 8GB+ microSD
- USB cable
- Power source

## 2. Flash Pi
Use Raspberry Pi Imager to install Raspberry Pi OS Lite (32-bit).
Enable:
- SSH
- Wi-Fi
- Set hostname

## 3. Boot and Update
ssh into the Pi and run:
sudo apt update && sudo apt upgrade -y

## 4. Connect Orbic
Plug Orbic into Pi USB.
Verify with:
ping 192.168.1.1

## 5. Install dependencies
sudo apt install -y jq curl lighttpd msmtp msmtp-mta mailutils cron

## 6. Configure Email
Edit /etc/msmtprc with SMTP credentials.
Test with:
echo test | mail -s test you@example.com

## 7. Install Raybridge directories
sudo mkdir -p /opt/raybridge/state /var/www/html/rayhunter/captures

## 8. Install scripts
Copy:
- sync_captures.sh
- make_dashboard.sh
- heartbeat.sh
to /opt/raybridge and chmod +x

## 9. Cron Jobs
sudo crontab -e
Add:
*/10 * * * * /opt/raybridge/sync_captures.sh
*/5 * * * * /opt/raybridge/make_dashboard.sh
0 8 * * * /opt/raybridge/heartbeat.sh

## 10. Verify
- Dashboard: http://<pi-ip>/rayhunter/
- PCAPs appear in captures/
- Heartbeat email arrives daily

## 11. Field Checklist
- Pi powered
- Orbic powered
- Wi-Fi reachable
- Email tested
- Storage free space checked

## 12. Data Handling
Download ZIPs from dashboard regularly and archive securely.

## 13. Legal Notice
Follow all local laws when operating Rayhunter.

