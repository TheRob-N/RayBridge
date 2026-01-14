#!/bin/bash
set -e

WIFI_CONN="$(nmcli -t -f NAME,TYPE,DEVICE con show --active | awk -F: '$2=="wifi"{print $1; exit}')"
USB_CONN="$(nmcli -t -f NAME,TYPE,DEVICE con show --active | awk -F: '$3=="usb0"{print $1; exit}')"

if [ -z "$WIFI_CONN" ]; then
  echo "No active Wi-Fi connection found"
  exit 1
fi

echo "Locking Wi-Fi ($WIFI_CONN) as default route"
sudo nmcli con modify "$WIFI_CONN" ipv4.route-metric 100

if [ -n "$USB_CONN" ]; then
  echo "Restricting USB ($USB_CONN)"
  sudo nmcli con modify "$USB_CONN" ipv4.never-default yes
  sudo nmcli con modify "$USB_CONN" ipv4.route-metric 500
  sudo nmcli con down "$USB_CONN"
  sudo nmcli con up "$USB_CONN"
fi

sudo nmcli con down "$WIFI_CONN"
sudo nmcli con up "$WIFI_CONN"

ip route
