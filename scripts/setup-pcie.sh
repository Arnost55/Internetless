#!/bin/bash
#
# setup-pcie.sh — Enable PCIe Gen 3 and install system tools for Internetless
#
# Usage: sudo ./scripts/setup-pcie.sh
#
# This script:
#   1. Enables PCIe Gen 3 mode in /boot/firmware/config.txt
#   2. Installs required tools: pciutils, i2c-tools, lm-sensors, dtc
#   3. Enables I2C interface for OLED and power monitoring
#
# Reboot required after running.

set -e

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (sudo ./scripts/setup-pcie.sh)"
  exit 1
fi

CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_FILE="/boot/firmware/config.txt.backup.$(date +%Y%m%d%H%M%S)"

echo "=== Internetless PCIe Gen 3 Setup ==="
echo

# Backup config.txt
if [ -f "$CONFIG_FILE" ]; then
  echo "[1/4] Backing up $CONFIG_FILE to $BACKUP_FILE"
  cp "$CONFIG_FILE" "$BACKUP_FILE"
else
  echo "[1/4] Warning: $CONFIG_FILE not found, creating new file"
  touch "$CONFIG_FILE"
fi

# Check if PCIe Gen 3 already enabled
if grep -q "^dtparam=pciex1_gen=3" "$CONFIG_FILE"; then
  echo "[2/4] PCIe Gen 3 already enabled in $CONFIG_FILE"
else
  echo "[2/4] Enabling PCIe Gen 3 in $CONFIG_FILE"
  echo "" >> "$CONFIG_FILE"
  echo "# Internetless PCIe Gen 3 Configuration" >> "$CONFIG_FILE"
  echo "dtparam=pciex1_gen=3" >> "$CONFIG_FILE"
fi

# Enable I2C if not already enabled
if grep -q "^dtparam=i2c_arm=on" "$CONFIG_FILE"; then
  echo "[2/4] I2C already enabled"
else
  echo "[2/4] Enabling I2C interface"
  echo "dtparam=i2c_arm=on" >> "$CONFIG_FILE"
fi

# Install required packages
echo "[3/4] Installing system tools..."
apt-get update -qq
apt-get install -y pciutils i2c-tools lm-sensors device-tree-compiler

# Load I2C kernel modules
echo "[4/4] Loading I2C kernel modules..."
modprobe i2c-dev
modprobe i2c-bcm2835

# Add to modules-load if not present
if ! grep -q "i2c-dev" /etc/modules 2>/dev/null; then
  echo "i2c-dev" >> /etc/modules
fi

echo
echo "=== Setup Complete ==="
echo
echo "Changes made:"
echo "  • PCIe Gen 3 enabled (dtparam=pciex1_gen=3)"
echo "  • I2C interface enabled (dtparam=i2c_arm=on)"
echo "  • Installed: pciutils, i2c-tools, lm-sensors, dtc"
echo
echo "Next steps:"
echo "  1. Reboot: sudo reboot"
echo "  2. Verify PCIe: lspci"
echo "  3. Verify I2C: i2cdetect -y 1"
echo "  4. Start display daemon: python3 src/display_daemon.py"
echo
echo "Backup saved to: $BACKUP_FILE"