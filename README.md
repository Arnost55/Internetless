# Internetless

**Compact 1.1L Modular SFF Travel Server and Router**  
145mm × 130mm × 60mm | Raspberry Pi 5 (16GB)

A portable, battery-backed networking and compute platform designed for homelab, travel, and edge deployments.

---

## Overview

Internetless is a fully modular small-form-factor server built around a Raspberry Pi 5. It combines routing, storage, compute, and connectivity into a palm-sized package with hot-swappable modules and built-in UPS.

```
┌─────────────────────────────────────────────────────────────┐
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐     ┌──────────────┐  │
│  │ M.2 │  │ M.2 │  │ M.2 │  │ M.2 │     │   0.96" OLED │  │
│  │ #1  │  │ #2  │  │ #3  │  │ #4  │     │   (I2C)      │  │
│  └─────┘  └─────┘  └─────┘  └─────┘     └──────────────┘  │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐                       │
│  │ M.2 │  │ M.2 │  │ M.2 │  │ M.2 │     Raspberry Pi 5    │
│  │ #5  │  │ #6  │  │ #7  │  │ #8  │     (16GB RAM)        │
│  └─────┘  └─────┘  └─────┘  └─────┘                       │
│                    2×4 Cartridge Matrix                     │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│          Hot-Swappable UPS Baseplate (14mm)                │
│                 Pogo-Pin Connector                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Specifications

| Component | Details |
|-----------|---------|
| **Dimensions** | 145 × 130 × 60 mm (1.1L) |
| **Core** | Raspberry Pi 5 (16GB) |
| **Backplane** | 8-port PCIe via ASMedia ASM1187E packet switch |
| **Cartridge Slots** | 8 × USB-C quick-swap (Waveshare HATs / M.2 modules) |
| **UPS** | Detachable 14mm hot-swap battery baseplate |
| **Display** | 0.96" OLED (I2C, flush-mounted top) |
| **Chassis** | 3D-printed PETG with TPU bumpers |

---

## Supported Modules

The 8-cartridge matrix supports hot-swap modules including:

- **5G LTE / eSIM** — Mobile broadband connectivity
- **NVMe SSD** — High-speed storage (via PCIe/NVMe HATs)
- **Wi-Fi 6E** — Wireless AP and client modes
- **Coral AI TPU** — Edge ML inference
- **SDR** — Software-defined radio (RTL-SDR, HackRF)
- **2.5GbE LAN** — Additional wired networking

---

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    Raspberry Pi 5 (16GB)                       │
├────────────────────────────────────────────────────────────────┤
│  PCIe Gen 3 ×1 ──► ASMedia ASM1187E ──► 8-port USB-C backplane │
│                        (Packet Switch IC)                      │
├────────────────────────────────────────────────────────────────┤
│  I2C Bus ◄─── 0.96" OLED Display                              │
│         ◄─── UPS Battery Monitor (GPIO/ADC)                   │
├────────────────────────────────────────────────────────────────┤
│  Software Stack                                                │
│  ├─ Pi OS / Pimox (Pi 5 port of Proxmox)                      │
│  ├─ Device Tree Overlays (PCIe Gen 3, I2C, power)             │
│  ├─ display_daemon.py (OLED status monitor)                   │
│  └─ systemd services for auto-start                           │
└────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Prerequisites

- Raspberry Pi 5 (4GB or 8GB recommended, 16GB optimal)
- Pi OS 64-bit (Bookworm) or Pimox
- Internet connection for initial setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/internetless.git
cd internetless
```

### 2. Run Setup Script

```bash
chmod +x scripts/setup-pcie.sh
sudo ./scripts/setup-pcie.sh
```

This enables PCIe Gen 3 and installs required tools:
- `pciutils` — PCIe device management
- `i2c-tools` — I2C bus utilities
- `lm-sensors` — Hardware monitoring
- `dtc` — Device Tree Compiler

### 3. Reboot

```bash
sudo reboot
```

### 4. Start OLED Display Daemon

```bash
cd src
pip install -r requirements.txt
sudo python3 display_daemon.py
```

For systemd auto-start, see `firmware/` for service unit files.

---

## Project Structure

```
internetless/
├── cad/                 # Fusion 360 models, STEP, DXF, STL
├── pcb/                 # KiCad backplane project (ASM1187E)
├── firmware/            # Device Tree Overlays (.dts / .dtbo)
├── src/                 # Display daemon and utilities
├── scripts/             # Setup and configuration scripts
└── README.md
```

---

## Development Status

| Component | Status |
|-----------|--------|
| PCB Design | In progress |
| 3D Chassis | Design phase |
| Firmware/DTBO | Stub |
| Display Daemon | Alpha |
| Documentation | Active |

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

---

## Acknowledgments

- Raspberry Pi Foundation
- ASMedia (ASM1187E PCIe switch)
- Waveshare (HAT ecosystem)
- luma.oled project