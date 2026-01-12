# Raybridge
Out-of-band monitoring, archiving, and alerting for EFF Rayhunter

Raybridge turns an Orbic hotspot running **EFF Rayhunter** into a remote, autonomous cellular‑surveillance detection node.

## Features
- PCAP and QMDL archiving
- Web dashboard
- Daily heartbeat emails
- Out-of-band uplink via Wi‑Fi

## Architecture
Orbic (Rayhunter) → USB → Raspberry Pi Zero W → Wi‑Fi → Internet → Email & Dashboard

## Requirements
- Orbic hotspot running Rayhunter v0.9.0+
- Raspberry Pi Zero W
- 8GB+ microSD
- Wi‑Fi internet for the Pi

## Manual Setup (Summary)
1. Flash Raspberry Pi OS Lite (32‑bit)
2. Configure Wi‑Fi and SSH
3. Plug Orbic into Pi USB
4. Install packages: jq, curl, lighttpd, msmtp, cron
5. Configure SMTP in /etc/msmtprc
6. Install Raybridge scripts under /opt/raybridge
7. Add cron jobs for sync, dashboard, heartbeat
8. Access dashboard at http://<pi-ip>/rayhunter/

This file is a placeholder until the full GitHub project is synced.
