# Hardware Notes — Topton N100/N150 NAS Board

This replaces the retired Raspberry Pi device-tree overlay work. On x86 the
board firmware handles everything the DTBO used to: PCIe lanes, SATA, Ethernet
and I2C are all native. Configuration happens in the BIOS, not a device tree.

## Board options

| Board | NICs | M.2 | SATA | ~Price |
|-------|------|-----|------|--------|
| Topton N8 (N100) | 4× 2.5GbE | 1 | — | $124–140 |
| Topton MW-N100-NAS | 2× 2.5GbE + 10GbE | 2 (NVMe) | 6 | ~$139 |
| Topton N150 variants | 2× 2.5GbE | varies | 6 | $139+ |

The MW-N100-NAS is the reference board: its two M.2 slots have real PCIe
x4/x1 lanes, so no PCIe switch chip is needed.

## BIOS checklist

- **ASPM** enabled — needed to hold the ~6W idle target.
- **Restore AC Power Loss = Power On** — so the UPS baseplate restarts the
  board after a battery swap.
- **I2C / SMBus controller** enabled for the OLED and battery monitor.
- SATA hot-plug enabled if hot-swapping drives is desired.

## Display (SSD1306 OLED)

The 0.96" SSD1306 OLED connects to the board's SMBus/I2C header at 0x3C.
Identify the bus with `i2cdetect -l`, then scan: `i2cdetect -y <bus>`.

## UPS battery monitor

Preferred: an I2C/SMBus fuel gauge IC (e.g. BQ20Zxx family) on the battery
pack, polled over the same bus as the OLED. Fallback: ADC pin with a
voltage divider — wire details and divider values (100k/10k, 3.0–4.2V cell)
carry over from the old Pi design.

## systemd

Install the daemon and unit:

```
sudo cp src/display_daemon.py /opt/internetless/src/
sudo cp firmware/internetless-display.service /etc/systemd/system/
sudo systemctl enable --now internetless-display
```
