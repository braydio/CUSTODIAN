
Below is the **fully consolidated ASSAULT–RESOURCE LINK document**.


This document now represents the authoritative implementation guide for Phase A–C.

---

# ASSAULT–RESOURCE LINK

## Unified Implementation & Roadmap Document

This document consolidates all prior drafts and roadmaps into a single implementation-ready specification aligned with the current world-state codebase.

---

# 1. IMPLEMENTATION STATUS

### Phase A — Transit Interception

**Status: Implemented**

* Deterministic transit interception implemented in:

  ```
  world_state/core/assaults.py
  ```
* Interception occurs during `advance_assaults`
* Ammo is consumed (`turret_ammo_stock`)
* Bounded `threat_budget` scaling applied before engagement
* Mitigation clamped to safe bounds
* Deterministic under fixed seed

### Phase B — Explicit Material Spend (Transit Fortification)

**Status: Design complete, implementation pending**

### Phase C — Salvage Coupling

**Status: Design-stage follow-on**

---

# 2. OVERALL GOAL

Create a deterministic loop linking operator resource decisions to assault outcomes without introducing UI-heavy systems.

### Target Loop

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

The objective is to couple resource management to combat pressure without adding new combat subsystems.

---

# 3. CURRENT CODE REALITY CHECK

## Implemented Systems

* Structure lifecycle states:

  ```
  OPERATIONAL → DAMAGED → OFFLINE → DESTROYED
  ```
* Materials economy:

  ```
  state.materials
  ```
* Assault approaches:

  ```
  INGRESS_N / INGRESS_S
  ```
* Multi-tick tactical assaults
* Ammo consumption per assault tick
* Repair drones, fabrication queue, inventory tiers
* Defense doctrine and allocation
* Sector fortification (`state.sector_fort_levels`)
* Transit nodes defined in `core/config.py` via `TRANSIT_NODES`
* STATUS rendering via `_append_policy_state`

## Not Implemented

* Player-built structures at transit nodes
* Transit-specific material-spend lane prep
* Salvage coupled to interception/ammo usage

---

# 4. DESIGN CONSTRAINTS

* No new rendering or UI layers
* No new command surface unless extending existing commands
* World mutation only inside simulation tick paths
* No additional RNG
* Deterministic under fixed seed
* Snapshot-safe
* No modification to tactical combat subsystem

---

# 5. PHASE A — TRANSIT INTERCEPTION (IMPLEMENTED)

## Overview

Adds deterministic pre-engagement interception when assaults traverse transit nodes (`T_NORTH`, `T_SOUTH` internally; user-facing uses full names).

## Mechanics

### 1. Trigger

Inside:

```
core/assaults.py::advance_assaults
```

If approach on transit node → run interception once per node pass.

---

### 2. Resource Gate

* Requires `state.turret_ammo_stock >= 1`
* Spend 1 ammo per intercept
* If no ammo → no mitigation

---

### 3. Mitigation

* Store mitigation on `AssaultApproach`

  ```
  approach.threat_mult
  ```
* Default = `1.0`
* On intercept:

  ```
  multiply by ~0.9 (example)
  ```

---

### 4. Engagement Handoff

When `_start_assault` fires:

```
threat_budget *= approach.threat_mult
```

Clamp:

```
floor: 0.7
ceiling: 1.0
```

---

### 5. Feedback

Append to:

```
state.last_assault_lines
```

Example:

```
[INTERCEPT] T_NORTH DELAYED HOSTILES
```

Output fidelity-gated via WAIT system.

---

### Why Phase A First

* Uses existing movement model
* Uses existing resource stocks
* No new commands
* Immediate resource-to-assault coupling
* Minimal architectural risk

---

# 6. PHASE B — TRANSIT FORTIFICATION (Explicit Material Spend)

## Objective

Extend existing:

```
FORTIFY
```

to support transit nodes and influence Phase A interception strength.

No new command surface.

---

# 6.1 Architectural Decision

Transit nodes are NOT sectors.

Therefore:

**DO NOT** store them in:

```
state.sector_fort_levels
```

Instead:

Add:

```
state.transit_fort_levels
```

---

# 6.2 Current Relevant Code State

### FORTIFY

Located in:

```
terminal/commands/policy.py
```

Writes to:

```
state.sector_fort_levels
```

### Transit Nodes

Defined in:

```
core/config.py
```

Used by:

* deploy.py
* move.py

### STATUS

Renders fortification in:

```
_append_policy_state()
```

### Assault Interception

Uses:

```
approach.threat_mult
```

---

# 6.3 Phase B Implementation Changes

---

## A. state.py

Add:

```python
self.transit_fort_levels = {
    "T_NORTH": 0,
    "T_SOUTH": 0,
}
```

### Snapshot Safety

Include in snapshot:

```python
"transit_fort_levels": self.transit_fort_levels
```

Migration fallback if absent.

---

## B. policy.py

Import:

```python
from game.simulations.world_state.core.config import TRANSIT_NODES
```

Modify `cmd_fortify`:

```python
token = sector_token.strip().upper()

if token in TRANSIT_NODES:
    state.transit_fort_levels[token] = clamp_policy_level(level)
    return [f"FORTIFICATION {token} SET TO {level}."]
```

Then continue existing sector logic unchanged.

---

## C. assaults.py

Import:

```python
from game.simulations.world_state.core.config import (
    TRANSIT_FORTIFICATION_FACTOR,
    THREAT_MULT_FLOOR,
)
```

Add to config if missing:

```python
TRANSIT_FORTIFICATION_FACTOR = 0.025
THREAT_MULT_FLOOR = 0.7
```

Inside interception logic:

```python
node = approach.current_node
fort_level = state.transit_fort_levels.get(node, 0)
if fort_level > 0:
    approach.threat_mult -= fort_level * TRANSIT_FORTIFICATION_FACTOR
```

Clamp:

```python
approach.threat_mult = max(
    THREAT_MULT_FLOOR,
    min(approach.threat_mult, 1.0),
)
```

### Rules

* Only apply at transit node
* Do not modify `_start_assault`
* Do not modify engagement logic
* Do not modify salvage

---

## D. help.py

Update:

```
- FORTIFY <SECTOR> <0-4>
```

To:

```
- FORTIFY <SECTOR|T_NORTH|T_SOUTH> <0-4>
```

---

## E. status.py

Inside `_append_policy_state`:

After sector fort rendering, add:

```python
transit_forts = [
    f"{name}:{level}"
    for name, level in state.transit_fort_levels.items()
    if int(level) > 0
]

if transit_forts:
    lines.append("- TRANSIT FORTIFICATION: " + " | ".join(sorted(transit_forts)))
```

---

# 6.4 Phase B Constraints

* No RNG
* Deterministic
* Snapshot safe
* No new UI
* No new subsystem
* No change to tactical combat engine

---

# 6.5 Phase B Test Plan

Create:

```
world_state/tests/test_transit_fortification.py
```

### Tests

1. Command routing:

   ```
   FORTIFY T_NORTH 3
   ```

   → assert `state.transit_fort_levels["T_NORTH"] == 3`

2. Interception scaling:

   * No fortification → capture threat_mult
   * Fortification level 4 → threat_mult lower

3. Clamp enforcement:

   * Ensure multiplier ≥ THREAT_MULT_FLOOR

4. Deterministic replay:

   * Run 100 ticks twice
   * Snapshots identical

5. WAIT output includes interception line

---

# 6.6 Phase B End State

System supports:

* Material-spend lane prep
* Transit-specific fortification
* Deterministic interception scaling
* Policy-level visibility
* Backwards compatibility
* No UI expansion
* No RNG expansion

---

# 7. PHASE C — SALVAGE COUPLING (OPEN DESIGN)

## Objective

Link salvage reward to:

* Interception effectiveness
* Ammo expenditure

Without introducing randomness spikes.

---

## Current Salvage

* Based on penetration/damage baseline
* Deterministic

---

## Proposed Adjustments

Add small bounded modifier based on:

* `ammo_spent_pre_engagement`
* `intercept_success_level`

### Constraints

* Deterministic
* Bounded modifier
* No RNG spikes
* Preserve salvage baseline

---

## Open Questions (Intentionally Left Open)

* Exact salvage modifier formula
* Whether ammo burn reduces salvage or increases it
* Whether fortification level influences salvage
* Whether salvage should reward efficiency vs over-spend

These remain unresolved and must be formally closed before Phase C implementation.

---

# 8. REQUIRED CODE TOUCHPOINTS

Primary:

* `core/assaults.py`
* `core/state.py`

Secondary:

* `terminal/commands/policy.py`
* `terminal/commands/status.py`
* `terminal/commands/help.py`

Presentation:

* `terminal/commands/wait.py` (reuse existing assault lines)

Optional:

* Add reporting counters in state:

  * intercepts_triggered
  * ammo_spent_pre_engagement

---

# 9. NON-GOALS

* No turret placement UI
* No projectile simulation
* No build grid
* No new combat subsystem
* No rework of tactical engine
* No changes to:

  * allocate_defense.py
  * config_doctrine.py
  * assault_ops.py
  * deploy.py
  * fabrication.py
  * repair.py
  * wait.py

---

# 10. FINAL CHECKLIST

## Phase A (Complete)

* [x] Ammo-spend interception
* [x] Mitigation multiplier
* [x] Clamp enforcement
* [x] Deterministic

## Phase B (To Complete)

* [ ] Add transit fort storage
* [ ] Extend FORTIFY
* [ ] Modify interception math
* [ ] Clamp maintained
* [ ] STATUS shows transit fort
* [ ] Snapshot safe
* [ ] Determinism preserved

## Phase C (Open)

* [ ] Define salvage coupling formula
* [ ] Bound modifier
* [ ] Add tests
* [ ] Preserve determinism

---

# FINAL DECISION PATH

1. Phase A: Already stable.
2. Implement Phase B exactly as specified.
3. Close open salvage questions.
4. Implement Phase C only after formula is formally defined.

---

This is now the canonical ASSAULT–RESOURCE LINK specification.

