# RayBridge • Stingray Sentinel

![RayBridge Logo](./assets/raybridge-logo-nbg.png)

## 🛰️ Overview

**RayBridge** is a monitoring and visualization system designed to pair a
**Raspberry Pi** with an **Orbic device running Rayhunter**.

### LCD Dashboard (Live)

![RayBridge LCD Dashboard](docs/screenshots/raybridge-lcd.gif)

The LCD dashboard runs in a Chromium kiosk on a Raspberry Pi and provides:
- Real-time system and capture status
- Orbic connectivity state
- Alert indicators with visual emphasis during events
- Touch interaction for expanded diagnostics and “Nerd Stats”
- Continuous system health and connectivity awareness

RayBridge is built for **portable, low-connectivity, and security-focused environments**.

---

## ✨ Features

- System health state (OK / CHECK / ALERT)
- Orbic connectivity monitoring
- Packet capture counting
- Event timestamp tracking
- Web-based dashboard
- Dedicated LCD UI (SPI display)
- USB + Wi-Fi routing awareness
- Daily heartbeat email
- Visual alert overlay mode

---

## 🖥️ Interfaces

### Web Dashboard
Accessible from any browser on the local network:

```
http://<pi-ip>/rayhunter/
```

---

### LCD Dashboard (Optional)
Optimized for **480×300 SPI displays**.

Features:
- Orbic connection indicator
- Three live metric cards
- Touch-based Nerd Stats
- Alert overlay

---

## 🧪 Future Development

### 📡 Meshtastic
- Integrate with Meshtastic for off-grid situational awareness
- Broadcast alert messages to nearby nodes when RayBridge enters an alert state

### 🔔 Beep / Alarm
Optional GPIO-based audible alerts.

---

## 📄 License

MIT License — see `LICENSE` for details.
