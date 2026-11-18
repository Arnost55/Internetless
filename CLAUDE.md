# CLAUDE.md

## Project

**Internetless** — compact modular SFF travel server/router (~1.6L), built around a Topton N100/N150 NAS Mini-ITX board (x86, native Proxmox), with a hot-swap UPS battery baseplate and a USB-C module bay for peripherals (5G modem, Wi-Fi 6E, Coral, SDR).

Earlier revisions of this repo targeted a Raspberry Pi 5 with an 8-slot PCIe-switch cartridge matrix; that design is retired. Do not reintroduce Pi-specific artifacts (device-tree overlays, `config.txt`, `vcgencmd`, RPi.GPIO).

## Hardware reference

- Reference board: Topton MW-N100-NAS — 2× 2.5GbE + 10GbE, 2× M.2 NVMe, 6× SATA (~$139)
- Alternative: Topton N8 — 4× 2.5GbE
- BIOS requirements: ASPM on (~6W idle target), AC power loss → Power On, I2C/SMBus enabled
- Display: 0.96" SSD1306 OLED on I2C, address 0x3C (bus number varies by board)
- UPS: hot-swap 14mm baseplate, battery monitor via SMBus fuel gauge (preferred) or ADC + divider

## Repository layout

- `firmware/` — systemd units (`internetless-display.service`) and hardware notes (`HARDWARE.md`). No device trees — x86 config lives in BIOS.
- `scripts/setup.sh` — host setup: i2c tools, Docker (on plain Debian; skipped on Proxmox VE).
- `src/display_daemon.py` — OLED status daemon (luma.oled + psutil). CPU temp via hwmon/lm-sensors, not `vcgencmd`.
- `services/docker-compose.yml` — service stack (network manager, status web, eSIM, Pi-hole, Ollama). N100 is CPU-only — keep local models to 1B–3B class.
- `cad/` — chassis models (not yet populated).

## Conventions

- Bash for host scripts (`set -e`, root check); Python 3 for daemons.
- The target host is Proxmox VE or Debian 12 on amd64. Docker files should stay compatible with both.
- Commits follow `<type>: <subject>` with focused, single-purpose changes.
