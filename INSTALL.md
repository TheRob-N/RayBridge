# RayBridge Installation (Raspberry Pi)

This guide explains how to install RayBridge on a Raspberry Pi for use with an Orbic device running Rayhunter. https://github.com/EFForg/rayhunter

RayBridge provides:
- A web dashboard (accessible from the LAN)
- Optional LCD dashboard support (SPI display) - https://www.amazon.com/dp/B07V9WW96D
- System health + Orbic connectivity awareness
- PCAP counting / timestamp tracking / alerting

Web UI (after install):
    http://<pi-ip>/rayhunter/

---

## Supported Platform

Recommended:
- Raspberry Pi 3 or newer
- Raspberry Pi OS (Trixie 64-bit Lite)
- Internet access during install

---

## ▶️ Installer Prompts Explained

### Linux Username
User that owns and runs RayBridge services.

### Heartbeat Email
Where daily system status emails are sent.

### SMTP Settings
Used only for sending heartbeat alerts.

---

## 🖥️ LCD Notes

- Runs Chromium in kiosk mode
- Fixed resolution: 480×300
- Touch input refreshes display

## Quick Install (Recommended)

### Use Raspberry Pi Imager to install recommeded OS
  - Be sure to set your region, username & password, wifi, and enable SSH
  - DO NOT connect the Rayhuner! (you won't be able to connect to the Pi if you do)

### 1) Update your Pi and install prerequisites

```bash
sudo apt update && sudo apt upgrade -y
```

### 2) Pull directly from GitHub

```bash
cd ~
wget https://github.com/TheRob-N/RayBridge/archive/refs/heads/main.zip -O RayBridge-main.zip
```

### 3) Run the installer

```bash
unzip RayBridge-main.zip
cd RayBridge-main
chmod +x install.sh
sudo ./install.sh
```
“If prompted to enable AppArmor support for msmtp, select No.”
“When prompted Enter the Orbic / Rayhunter base URL. The default value works for most users.”
```bash
Orbic/Rayhunter base URL [http://192.168.1.1:8080]:
```
  - Press "Enter" for the default
“When prompted Choose the directory where captures will be stored. The default web-accessible path is recommended.”
```bash
Capture output dir [/var/www/html/rayhunter/captures]:
```
  - Press "Enter" for the default
“When prompted Choose the directory used to store RayBridge runtime state. Default is recommended.”
```bash
State dir [/opt/raybridge/state]:
```
  - Press "Enter" for the default
“When prompted Enter the email address that will receive heartbeat and alert notifications.”
```bash
Heartbeat recipient email [you@example.com]: 
```
  - Enter your email address here
“Email alerts are optional during install and can be configured later.”
  - To configure later
```bash
[+] Configure email sending with msmtp
    You can skip this and edit /etc/msmtprc later if you prefer.
Configure /etc/msmtprc now? (y/N):
```
  - Enter "y" to configure now
“Enter the following details or press "Enter" for the default. Gmail is shown as a common example.”
```bash
SMTP host [smtp.gmail.com]:
SMTP port [587]:
From address [test@localhost]:
SMTP username [test@localhost]:
SMTP password (for Gmail use an App Password):
```
“Enable cron jobs to automatically update status and send alerts.”
```bash
Install cron entries now? (y/N):
```
  -This will automate screen refreshes and reboots
“Enable LCD kiosk mode to boot directly into the RayBridge dashboard on startup.”
```bash
[+] Optional: LCD kiosk mode (Chromium dashboard + dimmer)
    If you have a small LCD and have already installed its driver/overlay,
    this will configure the Pi to boot into the Raybridge dashboard.
Run screeninstall.sh now? (y/N):
```
  - Enter "y" if you have the recommended screen

  

### 4) Reboot
Attach the Rayhunter to the Pi and reboot
```bash
sudo reboot
```

### 5) Verify installation

After reboot, open:

    http://<pi-ip>/rayhunter/

Optional checks:

```bash
systemctl --failed
ip a
ip r
```

---

## Networking Notes

Typical interfaces:
- Orbic: usb0
- Pi Wi-Fi: wlan0

If routing issues occur:

```bash
ip a
ip r
nmcli dev status || true
```

---

## Reinstall / Fresh SD Card

```bash
cd ~/RayBridge
sudo ./install.sh
```

---

## Troubleshooting

Check logs:

```bash
journalctl -xe --no-pager | tail -n 200
```

---

## Future
Step by step install guide with screenshots.

---
See README.md for feature overview and roadmap.
