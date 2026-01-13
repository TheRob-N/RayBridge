# Prevent USB Tether from Breaking Wi-Fi (Critical)

When an Orbic (or any USB-tethered modem) is plugged into a Raspberry Pi, Linux often switches the default route from Wi-Fi to the USB device. This breaks:

• SSH  
• Internet  
• GitHub  
• Email  
• Raybridge uploads  

Raybridge requires:
- `wlan0` → Internet
- `usb0` → Orbic only

This guide enforces that split.

---

## Symptoms

Plugging in the Orbic causes:
- SSH disconnects
- Pi disappears from LAN
- No internet access

---

## Fix for Raspberry Pi OS (NetworkManager)

### 1. Identify your Wi-Fi profile

```bash
nmcli connection show --active
