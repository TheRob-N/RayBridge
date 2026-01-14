# RayBridge • Stingray Sentinel

![RayBridge Logo](./assets/raybridge-logo-nbg.png)

## 🛰️ Overview

**RayBridge** is an off-grid security sentinel that bridges an **Orbic device running Rayhunter** with a Raspberry Pi–based dashboard and optional LCD display.

It continuously monitors system health, packet capture activity, and Orbic connectivity, providing both a **web dashboard** and a **dedicated LCD UI** for field deployment.

This project is designed for **low-connectivity, portable, and surveillance-focused environments**.

---

## ✨ Core Features

- Real-time system health monitoring
- Orbic connectivity detection
- Packet capture counting & event tracking
- Web dashboard (desktop & mobile)
- Dedicated **LCD UI** for Raspberry Pi displays
- USB / Wi-Fi routing awareness
- Daily heartbeat email notifications
- Alert state visualization

---

## 🛠️ Hardware & Software Requirements

| Component | Notes |
|---------|------|
| Raspberry Pi 4 | 64-bit OS recommended |
| Optional 3.5″ SPI LCD | Waveshare / Spotpear Rev2.0 |
| Orbic device | Running Rayhunter |
| Raspberry Pi OS | Debian-based (Bookworm / Trixie) |
| Local network access | Wi-Fi or Ethernet |

---

## ⚙️ Installation Overview

RayBridge is installed using an **interactive installer script** that will prompt you for several values.  
Understanding these inputs ahead of time will make installation smoother.

> **Nothing sensitive is uploaded to GitHub.**  
> All credentials remain local to the Pi.

---

## 🧾 Installer Prompts Explained

During installation, you will be asked for the following:

---

### 🔹 1. Username

**Prompt example:**
