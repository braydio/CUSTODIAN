# Assault Design (Godot)

> Ported from `python-sim/design/10_systems/assault/ASSAULT_DESIGN.md`
> Phase: In Progress

---

## Core Loop

```
Allocate/Fabricate
    ↓
Intercept / Assault
    ↓
Damage / Salvage
    ↓
Repair / Rebuild
    ↓
Repeat
```

The objective: couple resource management to combat pressure without adding new combat subsystems.

---

## Implemented Systems (Godot)

- Structure lifecycle: OPERATIONAL → DAMAGED → OFFLINE → DESTROYED
- Materials economy: `GameState.materials`
- Assault approaches: INGRESS_N / INGRESS_S
- Multi-wave tactical assaults
- Ammo consumption per assault tick
- Sector fortification levels
- Defense doctrine and allocation

---

## Phase A: Transit Interception

### Overview

Deterministic pre-engagement interception when assaults traverse transit nodes (T_NORTH, T_SOUTH).

### Mechanics

**Trigger:** Assault approaches transit node

**Resource Gate:**
- Requires turret ammo stock ≥ 1
- Spend 1 ammo per intercept
- No ammo = no mitigation

**Mitigation:**
- Store on `AssaultApproach.threat_mult`
- Default = 1.0
- On intercept: multiply by ~0.9

**Engagement:**
When assault starts:
```
threat_budget *= approach.threat_mult
```

**Clamp:**
- Floor: 0.7
- Ceiling: 1.0

### Godot Implementation

- `AssaultManager` handles spawning and movement
- `TransitNode` areas trigger interception check
- Turret system tracks ammo stock
- UI displays interception events

---

## Phase B: Transit Fortification

### Objective

Extend FORTIFY command to support transit nodes and influence interception strength.

### Architectural Decision

Transit nodes are NOT sectors.

Store separately:
```
transit_fort_levels = {
    "T_NORTH": 0,
    "T_SOUTH": 0,
}
```

### Implementation

**FORTIFY Command:**
- Accepts: `FORTIFY <SECTOR> <0-4>` or `FORTIFY T_NORTH <0-4>`
- Writes to `transit_fort_levels`

**Interception Math:**
```
node = approach.current_node
fort_level = state.transit_fort_levels.get(node, 0)
if fort_level > 0:
    approach.threat_mult -= fort_level * TRANSIT_FORTIFICATION_FACTOR
```

**Constants:**
- `TRANSIT_FORTIFICATION_FACTOR = 0.025`
- `THREAT_MULT_FLOOR = 0.7`

### Godot Implementation

- Add `transit_fort_levels` to GameState
- TransitNode entities have fortification level
- Visual indicator of fortification (barricades, turrets)
- FORTIFY UI in pause menu

---

## Phase C: Salvage Coupling

### Objective

Link salvage reward to interception effectiveness and ammo expenditure.

### Formula (Locked)

```
final_salvage = clamp(
    base_salvage + efficiency_bonus - burn_penalty,
    outcome_min,
    outcome_max
)
```

**Efficiency Bonus:**
- Derived from `intercepted_units / total_assault_units`

**Burn Penalty:**
- Derived from intercept ammo
- Tactical ammo expenditure
- Transit fortification wear

**Edge Case:**
- Zero units intercepted → use `partial` tier envelope

### Constraints
- Deterministic
- Bounded modifier
- No RNG spikes
- Preserve salvage baseline

---

## Wave Escalation

### Current Implementation

See `wave_manager.gd` for existing wave system.

### Escalation Formula

```
wave_difficulty = base_difficulty * (1.0 + wave_number * escalation_factor)
```

### Material Rewards

| Wave Tier | Salvage Range |
|-----------|---------------|
| Early (1-3) | 10-20 materials |
| Mid (4-7) | 20-40 materials |
| Late (8+) | 40-80 materials |

---

## Defense Doctrine

### Concept

Player allocates defensive resources per sector:
- Turret placement
- Fortification level (0-4)
- Defense priority

### Doctrine Tiers

| Tier | Effect |
|------|--------|
| 0 | No bonus |
| 1 | +10% interception |
| 2 | +20% interception |
| 3 | +35% interception |
| 4 | +50% interception |

---

## Godot Implementation Checklist

### Required Touchpoints

1. **AssaultManager** - Spawning, movement, interception
2. **GameState** - Materials, transit_fort_levels, ammo stocks
3. **TurretSystem** - Ammo consumption, interception logic
4. **TransitNode** - Fortification, interception trigger
5. **UI** - FORTIFY command, STATUS display, wave info
6. **SalvageSystem** - Phase C formula implementation

### Non-Goals

- Turret placement UI (future)
- Projectile simulation (use hitscan)
- Build grid (future)
- New combat subsystem
- Rework tactical engine

---

## Legacy Python Reference

Python implementation in:
- `core/assaults.py` - Assault logic
- `core/state.py` - State management
- `terminal/commands/policy.py` - FORTIFY
- `terminal/commands/status.py` - STATUS display

Godot port: Translate terminal commands to UI interactions, translate tick-based to real-time.
