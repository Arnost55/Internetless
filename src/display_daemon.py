#!/usr/bin/env python3
"""
display_daemon.py — Internetless OLED Status Monitor

Renders live system stats on 0.96" SSD1306 OLED:
  • CPU temperature
  • RAM usage (%)
  • UPS battery percentage
  • Active PCIe module count

Requires: luma.oled, psutil

Usage:
    sudo python3 display_daemon.py

Run as root for I2C access on the board's SMBus header.
"""

import time
import subprocess
from pathlib import Path

try:
    from luma.oled.device import ssd1306
    from luma.core.interface.serial import i2c
    from luma.core.render import canvas
    from PIL import ImageFont
except ImportError:
    print("Error: luma.oled not installed. Run: pip install luma.oled")
    exit(1)

try:
    import psutil
except ImportError:
    print("Error: psutil not installed. Run: pip install psutil")
    exit(1)

# Configuration
# I2C bus number varies by board: check with `i2cdetect -l`
I2C_PORT = 0
I2C_ADDRESS = 0x3C
REFRESH_INTERVAL = 1.0  # seconds

# Battery monitoring (adjust for your UPS baseplate)
# Preferred: SMBus fuel gauge on the battery pack; fallback: ADC + divider
BATTERY_MAX_VOLTAGE = 4.2
BATTERY_MIN_VOLTAGE = 3.0


class SystemMonitor:
    """Collects system metrics for display."""

    @staticmethod
    def get_cpu_temp() -> float:
        """Return CPU temperature in Celsius."""
        try:
            # Coretemp sysfs (Intel N100 via lm-sensors) or thermal zone
            for pattern in ("/sys/class/hwmon/hwmon*/temp1_input",
                            "/sys/class/thermal/thermal_zone0/temp"):
                for path in Path("/sys/class").glob(pattern.replace("/sys/class/", "")):
                    try:
                        return float(path.read_text().strip()) / 1000.0
                    except (OSError, ValueError):
                        continue
        except OSError:
            pass

        # Fallback: lm-sensors
        try:
            result = subprocess.run(
                ["sensors"],
                capture_output=True,
                text=True,
                timeout=2
            )
            for line in result.stdout.splitlines():
                if "Package id 0" in line and "+" in line:
                    temp_str = line.split("+")[1].split("°")[0]
                    return float(temp_str)
        except (subprocess.SubprocessError, ValueError, IndexError):
            pass

        return 0.0

    @staticmethod
    def get_ram_usage() -> float:
        """Return RAM usage percentage."""
        return psutil.virtual_memory().percent

    @staticmethod
    def get_battery_percent() -> int:
        """
        Return battery percentage (0-100).

        TODO: Implement based on your UPS baseplate hardware.
        Options:
          - Read from SMBus fuel gauge IC (e.g., BQ20Zxx)
          - Read from ADC pin with voltage divider
        """
        # Placeholder: implement for your specific UPS

        # Stub: return 100% if not implemented
        return 100

    @staticmethod
    def get_pcie_device_count() -> int:
        """Return count of PCIe devices (excluding root)."""
        try:
            result = subprocess.run(
                ["lspci"],
                capture_output=True,
                text=True,
                timeout=2
            )
            # lspci returns one line per device
            lines = result.stdout.strip().split("\n")
            # Filter out empty lines and root bridge
            devices = [l for l in lines if l and "PCI bridge" not in l]
            return len(devices)
        except subprocess.SubprocessError:
            return 0


class OLEDDisplay:
    """Manages SSD1306 OLED display."""

    def __init__(self, i2c_port: int = 1, address: int = 0x3C):
        """Initialize OLED display."""
        serial = i2c(port=i2c_port, address=address)
        self.device = ssd1306(serial)
        self.font = ImageFont.load_default()
        self.monitor = SystemMonitor()

    def render(self):
        """Render current system stats to display."""
        with canvas(self.device) as draw:
            # Gather metrics
            cpu_temp = self.monitor.get_cpu_temp()
            ram_usage = self.monitor.get_ram_usage()
            battery = self.monitor.get_battery_percent()
            pcie_count = self.monitor.get_pcie_device_count()

            # Layout: 4 lines on 128x64 display
            y_offset = 0
            line_height = 16

            # Line 1: CPU Temp
            draw.text((0, y_offset), f"CPU: {cpu_temp:.1f}C", font=self.font, fill="white")
            y_offset += line_height

            # Line 2: RAM Usage
            draw.text((0, y_offset), f"RAM: {ram_usage:.1f}%", font=self.font, fill="white")
            y_offset += line_height

            # Line 3: Battery
            draw.text((0, y_offset), f"BAT: {battery}%", font=self.font, fill="white")
            y_offset += line_height

            # Line 4: PCIe Modules
            draw.text((0, y_offset), f"PCIe: {pcie_count} mod(s)", font=self.font, fill="white")

    def run(self, interval: float = 1.0):
        """Main loop: refresh display at interval."""
        print("Internetless OLED Daemon started")
        print("Press Ctrl+C to stop")

        try:
            while True:
                self.render()
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\nDaemon stopped")


def main():
    """Entry point."""
    display = OLEDDisplay(i2c_port=I2C_PORT, address=I2C_ADDRESS)
    display.run(interval=REFRESH_INTERVAL)


if __name__ == "__main__":
    main()