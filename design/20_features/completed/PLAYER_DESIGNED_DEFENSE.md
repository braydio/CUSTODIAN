We’re going to implement:

1. **Defense Doctrine (player-authored assault behavior)**
2. **Sector Allocation Bias (damage & protection weighting)**
3. **Pre-Assault Readiness Model**
4. **Deterministic Influence Validation**
5. **Terminal Surface Expansion (minimal, non-creeping)**

This is not fluff.
This is structural refinement that increases real strategic state without adding topology.

---

# CUSTODIAN

# DEFENSE CONTROL LAYER — IMPLEMENTATION DOCUMENT

*(Phase: Strategic Realness Before Physical Realness)*

---

# 0. Objective

Introduce the first persistent, player-authored strategic layer that:

* Alters AssaultInstance resolution deterministically
* Persists in GameState
* Requires Command Center authority
* Does not yet introduce physical defense objects
* Increases pre-assault planning depth

The goal is to move from:

> Simulation-forward → Player-shaped simulation

Without introducing structural complexity.

---

# 1. Feature Overview

We introduce three new systems:

---

## 1.1 Defense Doctrine

Defines how automated systems behave during assault.

This modifies:

* Target priority
* Damage distribution
* Reaction timing
* System preservation weighting

This is behavioral influence, not physical modification.

---

## 1.2 Sector Allocation Bias

Defines where defensive resources are prioritized.

This modifies:

* Incoming damage weighting
* Defense effectiveness multipliers
* Repair focus during assault

This is spatial influence without new topology.

---

## 1.3 Readiness Index

Represents global preparedness.

Calculated from:

* Active repairs
* Power routing balance
* Doctrine stability
* Sector integrity

Readiness influences:

* Assault severity roll
* Morale effects
* Damage spread entropy

This introduces tension before assault.

---

# 2. Data Model Changes

## 2.1 GameState Extensions

File:

```
game/simulations/world_state/core/state.py
```

Add:

```python
self.defense_doctrine = "BALANCED"

self.defense_allocation = {
    "PERIMETER": 1.0,
    "POWER": 1.0,
    "SENSORS": 1.0,
    "COMMAND": 1.0,
}

self.readiness_cache = None
```

Constraints:

* Doctrine must be valid enum.
* Allocation values must normalize to mean 1.0.
* Readiness is computed, never manually set.

---

# 3. Doctrine Specification

File:

```
game/simulations/assault/core/enums.py
```

Add:

```python
class DefenseDoctrine(Enum):
    BALANCED = auto()
    AGGRESSIVE = auto()
    COMMAND_FIRST = auto()
    INFRASTRUCTURE_FIRST = auto()
    SENSOR_PRIORITY = auto()
```

---

## 3.1 Doctrine Behavior Effects

In:

```
simulations/assault/core/autopilot.py
```

Inject doctrine weighting into:

* Target selection
* Damage mitigation
* Repair triage during assault

Example behavior definitions:

### BALANCED

* Even weighting
* No bias

### AGGRESSIVE

* +20% outgoing damage
* -15% structure preservation weighting

### COMMAND_FIRST

* +50% protection weighting on COMMAND
* -20% on other sectors

### INFRASTRUCTURE_FIRST

* Protect POWER & SENSORS
* Allow PERIMETER higher risk

### SENSOR_PRIORITY

* Early detection improves damage entropy
* Slight reduction in defense DPS

These are scalar multipliers only.
No new objects.

---

# 4. Sector Allocation Bias

Purpose:

Let player increase or decrease sector survivability.

Allocation modifies:

* Incoming damage weight
* Defense performance multiplier
* Morale decay impact

Implementation:

In:

```
assault/core/assault.py
```

During damage resolution:

Instead of:

```python
sector_damage = base_damage
```

Use:

```python
bias = state.defense_allocation[sector]
sector_damage = base_damage / bias
```

Higher allocation → less damage.

Normalization rule:

Average allocation must remain 1.0.

So if one sector is 1.5, others must adjust proportionally.

This prevents stacking.

---

# 5. Readiness Index

File:

```
world_state/core/state.py
```

Add method:

```python
def compute_readiness(self) -> float:
```

Readiness formula:

```
readiness =
    integrity_score *
    repair_completion_factor *
    power_stability_factor *
    doctrine_stability_factor
```

Where:

* integrity_score = average sector health
* repair_completion_factor = % of structures not in repair
* power_stability_factor = 1 - imbalance magnitude
* doctrine_stability_factor = 1.0 if unchanged for 3+ ticks, else 0.9

Range: 0.0 – 1.0

Readiness modifies:

In `assault_instance.py`:

```python
effective_threat = base_threat * (1.1 - readiness)
```

Higher readiness → lower effective assault severity.

This makes pre-assault planning matter.

---

# 6. Terminal Command Surface

Minimal additions only.

All commands are write-authority gated.

---

## 6.1 CONFIG DOCTRINE

```
CONFIG DOCTRINE <NAME>
```

Examples:

```
CONFIG DOCTRINE AGGRESSIVE
CONFIG DOCTRINE COMMAND_FIRST
```

Processor updates:

```
state.defense_doctrine = value
```

---

## 6.2 ALLOCATE DEFENSE

```
ALLOCATE DEFENSE <SECTOR> <PERCENT>
```

Example:

```
ALLOCATE DEFENSE COMMAND 40
```

Internally:

* Percent values normalized across sectors.
* Converts to float weights.

---

## 6.3 STATUS EXTENSION

Add to STATUS:

```
DEFENSE DOCTRINE: COMMAND_FIRST
ALLOCATION:
  PERIMETER: 0.8
  POWER: 1.0
  SENSORS: 0.9
  COMMAND: 1.3
READINESS: 0.82
```

No UI creep.
Terminal only.

---

# 7. Determinism & Testing

Add test:

File:

```
test_assault_doctrine_variation.py
```

Test:

Given:

* Fixed seed
* Same threat

When:

* Doctrine changes

Then:

* Assault outcome differs predictably

Add test for:

* Allocation bias altering damage distribution
* Readiness reducing severity roll

These tests validate real state impact.

---

# 8. Invariants

Must not violate:

* Location-based authority model
* Write commands only in COMMAND
* No hidden time advancement
* AssaultInstance remains single object
* Tactical system invoked only by world state

No UI added.
No asynchronous systems.
No random non-seeded entropy.

---

# 9. What This Achieves

Before assault:

* Player chooses doctrine.
* Player adjusts allocation.
* Player ensures repairs are complete.
* Player stabilizes power.

Assault outcome is now:

> A function of player preparation.

That’s strategic agency.

---

# 10. What We Are NOT Doing (Yet)

* Physical turret placement
* Fabrication build queues
* Power-per-defense modeling
* Upgrade tiers
* Defense slot topology

Those require structural state expansion.

We are not there yet.

---

# 11. Resulting Loop Evolution

Current loop:

```
Wait → Assault → Repair → Repeat
```

New loop:

```
Configure → Stabilize → Wait → Assault → Repair → Adjust → Repeat
```

That’s a game.

---

# 12. Phase Completion Criteria

This phase is complete when:

* Doctrine visibly changes assault outcome
* Allocation visibly shifts damage distribution
* Readiness modifies severity
* STATUS reflects all new state
* All tests deterministic

No UI additions required.
No structural builds required.

---

# Final Perspective

You are not abstracting forever.

You are building:

1. Behavioral layer
2. Strategic layer
3. Structural layer (next)
4. Topological layer (later)

We’re at step 2.

