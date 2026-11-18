# Baseplate PCB — Power Path & Supervision

The single custom board in the Internetless stack. The Topton N100/N150
mainboard stays stock; this baseplate owns everything between the battery
pack and the mainboard, plus the USB-C module bay power.

## Goals

- **Single conversion**: battery pack → buck converter → mainboard 12V input.
  No boost-then-buck chains (each stage costs 5–10%).
- **Measure everything**: real watts and runtime estimates on the OLED, not
  a guessed percentage.
- **Zero idle cost**: load switches cut power to unused USB-C modules
  (0.5–2W each on stock USB).
- **Sleep floor**: MCU supervises suspend-to-RAM on the mainboard,
  targeting a 1–2W system floor when idle.

## Block diagram

```
 4S 21700 pack (~100Wh)
        │
  ┌─────▼──────────────────────────────────────────────┐
  │ Charger / protection / balancing (BMS stage)       │
  └─────┬──────────────────────────────────────────────┘
        │  pack rail (12.8–16.8V, 4S)
  ┌─────▼───────────────┐     ┌─────────────────────┐
  │ Buck converter      ├────►│ Mainboard 12V DC-in │
  │ (LMR514xx class,    │     └─────────────────────┘
  │  95–97% efficient)  │     ┌─────────────────────┐
  │                     ├────►│ OLED + I2C header   │
  └─────┬───────────────┘     └─────────────────────┘
        │ I2C
  ┌─────▼──────────────────────────────────────────────┐
  │ INA219/226 current monitor (pack rail)             │
  ├────────────────────────────────────────────────────┤
  │ MCU supervisor (STM32/CH32 class, <$1)             │
  │  • fuel gauge + runtime estimate                   │
  │  • drives OLED (zero CPU wakeups on mainboard)     │
  │  • load-switch control (1 GPIO per USB-C port)     │
  │  • mainboard suspend/wake (GPIO + WOL trigger)     │
  └─────┬──────────────┬───────────────┬───────────────┘
        │              │               │
  ┌─────▼─────┐  ┌─────▼─────┐   ┌─────▼─────┐
  │ Load sw   │  │ Load sw   │   │ Load sw   │   USB-C module bay
  │ port 1    │  │ port 2    │…  │ port N    │   (5G / Wi-Fi / Coral / SDR)
  └───────────┘  └───────────┘   └───────────┘
```

## Power budget (design targets)

| State | Target | Notes |
|-------|--------|-------|
| Suspend (mainboard in S3) | 1–2W | MCU + switches only |
| Idle (routing/DNS/SSH) | 5–7W | ASPM on, cpufreq powersave |
| Load (all cores + NICs) | 15–25W | Buck sized ≥ 40W headroom |
| Runtime @ ~6W avg | 15–20h | 4S2P 21700 pack (~100Wh, TSA-legal) |

## Connector pinout (baseplate ⇄ mainboard)

The mainboard side carries the same I2C bus the display daemon already
expects (address 0x3C). MCU keeps OLED ownership by default; the daemon can
poll the INA via the same bus.

| Pin | Signal |
|-----|--------|
| 1–2 | +12V (buck output) |
| 3–4 | GND |
| 5 | SDA (3.3V) |
| 6 | SCL (3.3V) |
| 7 | SUS_WAKE# (MCU → mainboard wake) |
| 8 | SUS_STAT (mainboard → MCU, sleep state input) |

## Firmware interface

- MCU exposes INA readings + switch states over I2C at a fixed address.
- `src/display_daemon.py` reads watts/percent from the MCU instead of the
  current battery stub (see TODO in that file).
- Load-switch policy (auto-off after N min idle) implemented on the MCU;
  overridable from the daemon.

## Status

- [ ] Schematic (block-level done, part selection in progress)
- [ ] PCB layout
- [ ] Pack sizing / enclosure fit (14mm hot-swap constraint)
