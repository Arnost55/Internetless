# Baseplate PCB — Power Path, Supervision & Hot-Swap

The single custom board in the Internetless stack. The Topton N100/N150
mainboard stays stock; this baseplate owns everything between the battery
pack and the mainboard, plus the six module slots, their PCIe fabric and
their mechanical eject system.

**Design status: rev A locked.** Open items are part numbers only.

---

## Locked design decisions

1. **Module slots: 6× M.2 A/E-key**, not USB-C. An A/E-key slot carries both
   a PCIe x1 lane and USB 3.0/2.0, so every module type fits one connector.
2. **PCIe fabric: ASM1187E-class switch** on the baseplate. The mainboard's
   second M.2 slot (x4) becomes the upstream link via an M.2-to-cable
   adapter; the switch fans it out to 6 downstream x1 module slots.
   The mainboard's first M.2 slot stays a real NVMe (boot drive).
3. **Storage: 6× SATA on the mainboard** covers bulk capacity (native
   hot-swap). Optionally one switch port can be repurposed as an M.2
   B/M-key NVMe slot (5 modules + 1 NVMe) if fast bulk storage is wanted.
4. **Slot layout: vertical side-mount rack.** All 6 slots on edge along one
   long side of the chassis, ~12mm pitch — modules slide in like cartridges.
   Mechanics live in a 3D-printed cage (`cad/`), not on the PCB.
5. **SIM: one nano-SIM socket on the baseplate**, traces routed to module
   slot 1's SIM pins. Slot 1 is designated the cellular slot (marked on
   silkscreen). A second socket can be added in a later revision for slot 2.
6. **Slot power: switched 3.3V rails under MCU control.** Slot power-cycle
   doubles as the hot-plug reset mechanism.
7. **Power path: single conversion.** Battery pack → high-efficiency buck
   (LMR514xx class, 95–97%) → mainboard 12V DC-in. No boost-then-buck.
8. **Measurement: INA219/226 on the pack rail.** Real watts and runtime
   estimates, not guessed percentages.
9. **Supervisor: MCU (STM32/CH32 class, <$1)** drives the OLED (zero CPU
   wakeups on the mainboard), controls slot power and eject latches,
   polls the INA, and manages mainboard suspend/wake.
10. **Modules are passive.** A module is a stock M.2 stick in a 3D-printed
    carrier with a single locking notch — no active parts on the module.
    All latches, solenoids and sensors live in the cage, wired to the
    baseplate.

---

## Hot-swap model (three tiers)

Swap behavior is classified per module type; the hardware enforces each tier.

| Tier | Modules | Behavior |
|------|---------|----------|
| **Hot-swap** | SATA drives | Native AHCI — slide out/in anytime, no blip |
| **Orchestrated swap** | Wi-Fi 6E, 5G WAN, any powered module | Two-press latch protocol (below) |
| **Sleep-swap** | Cold modules (SDR, Coral, spare storage) | Board suspends to RAM (~2s), swap, resume (~2s) |

### Orchestrated swap: the quiesce protocol

Swapping a module whose driver holds live state (an AP, a WAN uplink) under
the kernel causes resume errors. The daemon therefore owns swap as a
software-orchestrated sequence; the MCU only ever cuts slot power after the
daemon's ack:

1. **Request** — press the module (it stays locked; solenoid pin blocks it).
2. **Quiesce** — daemon stops the slot's services cleanly (hostapd down,
   WAN route fails over to a 2.5GbE port), then unbinds the kernel driver.
   The kernel now has zero state on the device.
3. **Release** — MCU retracts the solenoid pin (100ms pulse, <1W); the
   spring latch ejects the module a few mm; slot power was already cut.
4. **Insert** — push in; latch catches; presence-detect (A/E-key CD pin)
   fires; daemon powers the slot, rescans, rebinds and restarts services
   with the same config.

Slots are classified per-module in the daemon's slot↔service map. The
OLED shows per-slot state (`READY`, `BUSY — WAN active`, `QUIESCING`,
`EMPTY`), so "is it safe?" never has to be guessed.

### Mechanical eject system (in the cage, per slot)

- **Push-push spring latch** — standard cartridge feel; spring provides
  the few-mm eject travel.
- **Solenoid locking pin** — engages a **notch in the module carrier**
  (not the latch itself). Pin extended whenever the slot is powered and
  not quiesced; a live module physically cannot be yanked.
- **Latch-position sensor** (microswitch or Hall) — tells the MCU whether
  the module is seated, half-out, or absent; feeds the OLED state and the
  presence logic.
- **Solenoids are pulsed only** — no standby draw, no heat.
- **Rev A scoping: full latch on slots 1–2 only** (cellular + Wi-Fi, where
  swap errors actually matter). Slots 3–6 use plain friction latches so a
  latch redesign never blocks the whole build.

### Sleep-swap

For cold modules the MCU can suspend the mainboard to RAM (drop to the
1–2W floor), let the user swap freely, and wake on the slot's
presence-detect or a button. RAM contents survive; services resume in
~2 seconds. Optional convenience path, same electrical rules.

---

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
  │  • slot power switches + eject solenoids           │
  │  • latch/presence sensors                          │
  │  • mainboard suspend/wake (GPIO + WOL trigger)     │
  ├────────────────────────────────────────────────────┤
  │ PCIe upstream (mainboard M.2 #2, x4)               │
  │  └─ ASM1187E switch ── 6× M.2 A/E-key slots (x1)   │
  │      slot 1 = cellular (baseplate nano-SIM)        │
  └────────────────────────────────────────────────────┘
        │ switched 3.3V per slot
  ┌─────▼─────┐  ┌─────▼─────┐   ┌─────▼─────┐
  │ Slot pwr  │  │ Slot pwr  │…  │ Slot pwr  │
  │ switch 1  │  │ switch 2  │   │ switch 6  │
  └───────────┘  └───────────┘   └───────────┘
```

## Module mapping

| Slot | Lines | Module examples | Eject hardware |
|------|-------|-----------------|----------------|
| 1 (cellular) | USB 3.0 + SIM | 5G modem (SIM from baseplate socket) | Full latch + solenoid |
| 2 | PCIe x1 and/or USB | Wi-Fi 6E, Coral M.2 A/E | Full latch + solenoid |
| 3–6 | PCIe x1 and/or USB | SDR (USB), Coral, misc | Friction latch, rev B upgrade |

Bandwidth: each module gets Gen 3 x1 (~985 MB/s). A 5G modem peaks near
2 Gbps, Wi-Fi 6E similar, SDR/Coral far below — six simultaneous modules
never saturate the shared x4 upstream (~3.9 GB/s).

## Power budget (design targets)

| State | Target | Notes |
|-------|--------|-------|
| Suspend (mainboard in S3) | 1–2W | MCU + switches only |
| Idle (routing/DNS/SSH) | 5–7W | ASPM on, cpufreq powersave |
| Load (all cores + NICs) | 15–25W | Buck sized ≥ 40W headroom |
| Runtime @ ~6W avg | 15–20h | 4S2P 21700 pack (~100Wh, TSA-legal) |

Hot-swap packs double runtime: the baseplate accepts a second pack
without cutting mainboard power.

## Connector pinout (baseplate ⇄ mainboard)

The mainboard side carries the same I2C bus the display daemon already
expects (address 0x3C). MCU keeps OLED ownership by default; the daemon
can poll the INA via the same bus.

| Pin | Signal |
|-----|--------|
| 1–2 | +12V (buck output) |
| 3–4 | GND |
| 5 | SDA (3.3V) |
| 6 | SCL (3.3V) |
| 7 | SUS_WAKE# (MCU → mainboard wake) |
| 8 | SUS_STAT (mainboard → MCU, sleep state input) |

## Firmware interface

- MCU exposes INA readings, slot switch states, latch/presence states and
  swap-request buttons over I2C at a fixed address.
- `src/display_daemon.py` reads watts/percent from the MCU instead of the
  current battery stub, and implements the slot↔service map and the
  quiesce protocol.
- Slot power policy (auto-off after N min idle) implemented on the MCU;
  overridable from the daemon.

## Open items for rev A

- [ ] Part selection: buck converter, charger/BMS IC, MCU, INA, switch —
      ASM1187E vs. equivalent; micro-solenoid for the eject pins.
- [ ] Confirm the MW-N100-NAS second M.2 slot is x4 (upstream needs the
      lanes; x1 is workable but reduces headroom).
- [ ] KiCad schematic and layout.
- [ ] Latch cage design in `cad/` (print, test spring forces, iterate —
      the most mechanical-iteration-heavy part).
- [ ] Pack sizing / enclosure fit (14mm hot-swap constraint).
