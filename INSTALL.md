# RayBridge Installation (Raspberry Pi)

This guide explains how to install RayBridge on a Raspberry Pi for use with an Orbic device running Rayhunter.

RayBridge provides:
- A web dashboard (accessible from the LAN)
- Optional LCD dashboard support (SPI display)
- System health + Orbic connectivity awareness
- PCAP counting / timestamp tracking / alerting

Web UI (after install):
    http://<pi-ip>/rayhunter/

---

## Supported Platform

Recommended:
- Raspberry Pi 4+
- Raspberry Pi OS (Bookworm) 64-bit or another Debian-based OS
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

### 1) Update your Pi and install prerequisites

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git
```

### 2) Clone the repo

```bash
cd ~
git clone https://github.com/TheRob-N/RayBridge.git
cd RayBridge
```

### 3) Run the installer

```bash
chmod +x install.sh
sudo ./install.sh
```

To review what the installer does:

```bash
sed -n '1,200p' install.sh
```

### 4) Reboot

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

See README.md for feature overview and roadmap.
