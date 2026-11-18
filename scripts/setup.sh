#!/bin/bash
#
# setup.sh — Host setup for Internetless on Topton N100/N150 (Proxmox VE or Debian 12)
#
# Usage: sudo ./scripts/setup.sh
#
# This script:
#   1. Installs required tools: i2c-tools, lm-sensors
#   2. Loads and enables the I2C interface for the OLED
#   3. Optionally installs Docker + Compose on plain Debian
#
# Run the OLED daemon after this completes.

set -e

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (sudo ./scripts/setup.sh)"
  exit 1
fi

IS_PROXMOX=0
[ -f "/etc/pve/.version" ] && IS_PROXMOX=1

echo "=== Internetless Host Setup (N100/N150) ==="
echo

# Install required packages
echo "[1/3] Installing system tools..."
apt-get update -qq
apt-get install -y i2c-tools lm-sensors python3-smbus

if [ "$IS_PROXMOX" -eq 0 ]; then
  echo "[2/3] Installing Docker + Compose..."
  if ! command -v docker >/dev/null 2>&1; then
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  else
    echo "    Docker already installed"
  fi
else
  echo "[2/3] Proxmox VE detected — skipping Docker install"
fi

# Enable I2C
echo "[3/3] Enabling I2C interface..."
modprobe i2c-dev
if ! grep -q "i2c-dev" /etc/modules 2>/dev/null; then
  echo "i2c-dev" >> /etc/modules
fi

echo
echo "=== Setup Complete ==="
echo
echo "Installed: i2c-tools, lm-sensors, python3-smbus"
[ "$IS_PROXMOX" -eq 0 ] && echo "           Docker + Compose"
echo
echo "Next steps:"
echo "  1. Verify I2C:  i2cdetect -y 0   (or -y 1, bus varies by board)"
echo "  2. Start the OLED daemon: python3 src/display_daemon.py"
echo "  3. Deploy the service stack: cd services && docker compose up -d"
