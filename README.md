# Internetless

**Compact ~1.6L Modular SFF Travel Server and Router**
170mm × 170mm × 55mm | Intel N100/N150 NAS board

A portable, battery-backed networking and compute platform designed for homelab, travel, and edge deployments.

---

## Overview

Internetless is a fully modular small-form-factor server built around an x86 NAS board (Topton N100/N150 Mini-ITX). It combines routing, storage, compute, and connectivity into a shoebox-sized package with hot-swappable USB modules and built-in UPS.

```
┌──────────────────────────────────────────────────────────────┐
│  ┌────────────────────────────────────────────────────────┐  │
│  │        Topton N100/N150 NAS Mini-ITX board             │  │
│  │  2× M.2 NVMe (real PCIe lanes)   6× SATA               │  │
│  │  2× 2.5GbE + 10GbE               ~6W idle              │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────────────────┐  │
│  │ M.2    │ │ M.2    │ │ USB-C  │ │  0.96" OLED (I2C)    │  │
│  │ NVMe 1 │ │ NVMe 2 │ │ module │ │  Battery monitor     │  │
│  └────────┘ └────────┘ └────────┘ └──────────────────────┘  │
│         Internal storage + USB-C module bay                  │
│                                                              │
│  ──────────────────────────────────────────────────────────  │
│           Hot-Swappable UPS Baseplate (14mm)                 │
│                  Pogo-Pin Connector                          │
└──────────────────────────────────────────────────────────────┘
```

---

## Specifications

| Component | Details |
|-----------|---------|
| **Dimensions** | 170 × 170 × 55 mm (~1.6L) |
| **Core** | Topton N100/N150 NAS board (4-core Intel, 8–16GB DDR5 SODIMM) |
| **Board options** | N8 (4× 2.5GbE, ~$124–140) or MW-N100-NAS (2× 2.5GbE + 10GbE, 2× M.2, 6× SATA, ~$139) |
| **Storage** | 2× M.2 NVMe (PCIe x4/x1) + 6× SATA |
| **Module Bay** | USB-C quick-swap (5G modem, Wi-Fi 6E, SDR, Coral) |
| **UPS** | Detachable 14mm hot-swap battery baseplate |
| **Display** | 0.96" OLED (I2C, flush-mounted top) |
| **Power** | ~6W idle, DC 12V input (from UPS baseplate) |
| **Chassis** | 3D-printed PETG with TPU bumpers |

---

## Supported Modules

Wired networking (2.5GbE/10GbE) and NVMe storage are built into the board, so the hot-swap bay is reserved for the genuinely modular peripherals:

- **5G LTE / eSIM** — Mobile broadband connectivity (USB modem)
- **Wi-Fi 6E** — Wireless AP and client modes (USB adapter)
- **Coral AI TPU** — Edge ML inference (USB Coral)
- **SDR** — Software-defined radio (RTL-SDR, HackRF)
- **USB NVMe** — Ad-hoc external storage swaps

---

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│           Topton N100/N150 NAS Mini-ITX board                  │
├────────────────────────────────────────────────────────────────┤
│  PCIe (native) ──► 2× M.2 NVMe slots                           │
│  SATA (native) ──► 6× SATA ports                               │
│  Ethernet ──► 2× 2.5GbE (+ optional 10GbE SFP+/RJ45)           │
├────────────────────────────────────────────────────────────────┤
│  I2C ◄─── 0.96" OLED Display                                   │
│       ◄─── UPS Battery Monitor (SMBus fuel gauge or ADC)       │
│  USB  ──► Hot-swap module bay (5G / Wi-Fi / Coral / SDR)       │
├────────────────────────────────────────────────────────────────┤
│  Software Stack                                                │
│  ├─ Proxmox VE (native x86 — no ARM ports)                    │
│  ├─ Debian + Docker (alternative lightweight install)         │
│  ├─ display_daemon.py (OLED status monitor)                   │
│  └─ systemd services for auto-start                           │
└────────────────────────────────────────────────────────────────┘
```

No PCIe switch chip or custom backplane is needed: the two M.2 slots have real PCIe lanes and the module bay is plain USB. The old 8-slot cartridge matrix (ASM1187E) is retired — same capability, less hardware.

---

## Quick Start

### Prerequisites

- Topton N100/N150 NAS board + DDR5 SODIMM + M.2 NVMe
- USB install media with Proxmox VE or Debian 12
- Internet connection for initial setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/internetless.git
cd internetless
```

### 2. Flash the Host OS

Write Proxmox VE (or Debian 12) to a USB stick and install to the first NVMe. In the board BIOS, check that:

- **ASPM** is enabled (for the ~6W idle target)
- **AC power loss recovery** is set to *Power On* (UPS behavior)
- **I2C/SMBus** controller is enabled (for the OLED)

### 3. Run Setup Script

```bash
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

This installs the host tooling for the OLED and monitoring:
- `i2c-tools` — I2C bus utilities
- `lm-sensors` — Hardware monitoring
- Docker + Compose (if installing on plain Debian)

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
├── firmware/            # systemd units and hardware notes
├── src/                 # Display daemon and utilities
├── scripts/             # Setup and configuration scripts
├── services/            # Docker Compose stack
└── README.md
```

---

## Development Status

| Component | Status |
|-----------|--------|
| 3D Chassis | Design phase |
| Display Daemon | Alpha |
| Docker Stack | Alpha |
| Documentation | Active |

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

---

## Acknowledgments

- Topton / AliExpress NAS board ecosystem
- luma.oled project
