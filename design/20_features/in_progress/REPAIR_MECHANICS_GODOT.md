# Repair Mechanics (Godot)

> Ported from `python-sim/design/10_systems/infrastructure/REPAIR_MECHANICS.md`
> Phase: In Progress

---

## Core Philosophy

Repair in CUSTODIAN is **maintenance under pressure** — slow, costly, and boring. It's not spectacle. If repair feels fun, something went wrong.

---

## Design Principles

### 1. Repair is Local and Physical

- No remote repair
- Player must be **present in the affected sector**
- Preserves location-based authority and command vs field distinction

### 2. Repair Restores Capability, Not Certainty

Repair:
- Improves system STATUS
- Improves WAIT fidelity
- Reduces risk

Repair does **NOT**:
- Guarantee safety
- Remove threat
- Undo consequences instantly

### 3. Repair Operates on Systems, Not Sectors

Sectors are views. Systems are things.

Repair targets:
- POWER
- COMMS
- DEFENSE GRID
- ARCHIVE

---

## Implementation Spec

### System Integrity Model

Each **system** has:
- `integrity`: 0–100 (internal)
- `damage_state`: derived from integrity

| Integrity | State |
|-----------|-------|
| 0–25 | COMPROMISED |
| 26–60 | DAMAGED |
| 61–85 | ALERT |
| 86–100 | STABLE |

### Repair Action

**Trigger:** Player presses repair key while in system sector

**Preconditions:**
- Player physically in system's sector
- System is not DESTROYED
- System integrity < 100
- No COMMAND breach lockout

### Repair Is Time-Bound

- REPAIR starts a repair task
- Repair progresses over **real-time** (not turn-based)
- Repair pauses if:
  - Player leaves the sector
  - Assault enters that sector
  - Power drops below threshold

### Repair Progress (Real-Time)

```
integrity += repair_rate * delta
```

Where:
- `repair_rate`: +5 integrity per second (base)
- Scaled down if:
  - Assault active in sector
  - POWER system unstable
  - COMMS degraded

### Repair Outcomes

| Integrity Crossed | Result |
|-------------------|--------|
| ≥ 75 | DAMAGED → ALERT |
| ≥ 90 | ALERT → STABLE |

---

## Godot Implementation Notes

### Entity Architecture

```
SystemEntity (Node2D)
├── integrity: int (0-100)
├── damage_state: Enum (STABLE, ALERT, DAMAGED, COMPROMISED)
├── is_being_repaired: bool
└── repair_rate: float
```

### Player Interaction

- Proximity-based: Player must be within interaction radius of system entity
- Press REPAIR key (E) to initiate
- Visual feedback: Repair beam / particle effect
- Audio: Repair tool sound

### Real-Time Tick

- Hook into `_process(delta)` or a dedicated repair timer
- Only repair when player is present AND actively repairing
- Interrupt on assault entry

### UI Feedback

- System status indicator (color-coded)
- Repair progress bar when actively repairing
- Event notification on threshold crossing

---

## What This Enables (Future)

- Repair bots (remote + parallel repair)
- Combat repair tools
- Prioritization / triage mechanics
- Automation failure states
- Fabrication (reconstruction after DESTROYED)

---

## Legacy Python Code Reference

The canonical Python implementation adds:
- `SectorState.integrity` field
- `GameState.active_repair` tracking
- Repair mutation inside `step_world`
- REPAIR command with preconditions
- WAIT feedback for repair completion

For Godot: Translate `step_world` ticks to `_process(delta)` time.
