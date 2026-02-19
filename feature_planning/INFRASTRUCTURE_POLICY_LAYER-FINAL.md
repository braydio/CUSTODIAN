
```
docs/INFRASTRUCTURE_POLICY_LAYER.md
```

and then executed by Codex step-by-step.

---

# INFRASTRUCTURE POLICY LAYER

## Between-Assault Strategic Systems Specification

---

# 1. PURPOSE

This document defines the **Infrastructure Policy Layer**, a strategic control system that governs:

* Repair behavior
* Defense readiness
* Surveillance intensity
* Fabrication allocation
* Sector fortification posture
* Power load balancing

The goal is to:

* Transform between-assault pacing into colony/factory-style strategic optimization
* Eliminate vague policy labels (e.g. “CONSERVATIVE”, “HARDENED”)
* Replace hidden enum modes with explicit tradeoffs
* Preserve terminal-first UX
* Avoid numeric overload or spreadsheet feel
* Maintain deterministic simulation and seed reproducibility

This system does not replace assaults.
It makes assaults a stress test of infrastructure decisions.

---

# 2. DESIGN PRINCIPLES

## 2.1 No Blind Policies

Every adjustable system must show:

* What increases
* What decreases
* What it costs

No vague adjectives without consequences.

---

## 2.2 Textual Sliders, Not Raw Numbers

Policies are represented as discrete bands:

```
0 – 4 integer scale
```

Rendered as:

```
▮▮▯▯▯ (2/5)
```

With clear effect description.

No decimals shown to player.

---

## 2.3 Tradeoffs Are Mandatory

Increasing one dimension must impact another:

* Defense ↔ Power
* Repair ↔ Materials
* Surveillance ↔ Brownout Risk
* Fabrication ↔ Defense Load

---

# 3. CORE POLICY SYSTEMS

The Infrastructure Policy Layer introduces five global sliders.

Each slider is 0–4.

---

# 3.1 Repair Intensity

Controls autonomous and queued repair behavior.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Slow repair, minimal material usage       |
| 2     | Balanced repair rate                      |
| 4     | Rapid repair, high material + power drain |

### Internal Mapping

```python
REPAIR_SPEED = [0.5, 0.75, 1.0, 1.4, 1.8]
REPAIR_MATERIAL_MULT = [0.5, 0.75, 1.0, 1.5, 1.7]
REPAIR_POWER_MULT = [0.8, 0.9, 1.0, 1.2, 1.4]
```

---

# 3.2 Defense Readiness

Controls turret cycling, patrol drones, response intensity.

### Effects

| Level | Effect Summary                    |
| ----- | --------------------------------- |
| 0     | Minimal readiness, low power draw |
| 2     | Standard                          |
| 4     | Rapid response, high power + wear |

### Internal Mapping

```python
DEFENSE_MULT = [0.6, 0.8, 1.0, 1.3, 1.6]
DEFENSE_POWER_DRAW = [0.7, 0.85, 1.0, 1.25, 1.5]
WEAR_RATE = [0.5, 0.75, 1.0, 1.3, 1.6]
```

---

# 3.3 Surveillance Coverage

Controls detection speed and fidelity strength.

### Effects

| Level | Effect Summary                            |
| ----- | ----------------------------------------- |
| 0     | Delayed intrusion alerts                  |
| 2     | Normal detection                          |
| 4     | Near-immediate detection, high power load |

```python
DETECTION_SPEED = [0.6, 0.8, 1.0, 1.3, 1.6]
FIDELITY_BUFFER = [0.5, 0.75, 1.0, 1.2, 1.5]
SURVEILLANCE_POWER = [0.6, 0.8, 1.0, 1.3, 1.6]
```

---

# 3.4 Fabrication Allocation

Controls queue throughput.

Fabrication uses weighted distribution:

```
DEFENSE
DRONES
REPAIRS
ARCHIVE HARDENING
```

Each category receives 0–4 allocation.

Throughput proportional to allocation weight.

---

# 3.5 Sector Fortification (Per-Sector)

Each sector has independent fortification level 0–4.

### Effects

* Structural resistance multiplier
* Increased power demand
* Reduced fabrication throughput in that sector

```python
FORTIFICATION_MULT = [1.0, 1.1, 1.25, 1.5, 1.8]
FORTIFICATION_POWER = [0, 0.05, 0.1, 0.15, 0.25]
```

---

# 4. RENDERING SYSTEM

Add:

```
core/policies.py
```

---

## Policy Dataclass

```python
from dataclasses import dataclass

@dataclass
class PolicyState:
    repair_intensity: int = 2
    defense_readiness: int = 2
    surveillance_coverage: int = 2
```

Attach to GameState:

```python
self.policies = PolicyState()
```

---

## Render Helper

```python
def render_slider(level: int) -> str:
    filled = "▮" * level
    empty = "▯" * (5 - level)
    return f"{filled}{empty} ({level}/5)"
```

---

## STATUS Integration

Modify:

```
terminal/commands/status.py
```

Add section:

```
POLICY STATE

REPAIR INTENSITY
▮▮▮▯▯
+ Moderate repair speed
- Moderate material drain

DEFENSE READINESS
▮▮▮▮▯
+ Strong response
- Increased power load
```

Descriptions are derived from lookup tables.

---

# 5. FABRICATION QUEUE SYSTEM

Create:

```
core/fabrication.py
```

---

## FabricationTask

```python
@dataclass
class FabricationTask:
    name: str
    ticks_remaining: int
    material_cost: int
    category: str
```

GameState:

```python
self.fabrication_queue: list[FabricationTask] = []
```

---

## Tick Processing

In world tick:

```python
def tick_fabrication(state):
    if not state.fabrication_queue:
        return

    allocation_weight = state.fab_allocation[current_task.category]
    speed_mult = 0.5 + (allocation_weight * 0.25)

    current_task.ticks_remaining -= speed_mult
```

Power consumption increases based on throughput.

---

# 6. POWER LOAD SYSTEM

Add:

```
core/power_load.py
```

Compute system load each tick:

```python
def compute_power_load(state):
    base = 1.0
    base += DEFENSE_POWER_DRAW[state.policies.defense_readiness]
    base += SURVEILLANCE_POWER[state.policies.surveillance_coverage]
    base += REPAIR_POWER_MULT[state.policies.repair_intensity]
    base += sum(FORTIFICATION_POWER[level] for level in state.sector_fort_levels.values())

    state.power_load = base
```

Brownout chance tied to power_load.

---

# 7. WEAR & PASSIVE DEGRADATION

In world tick:

```python
def apply_wear(state):
    wear_factor = WEAR_RATE[state.policies.defense_readiness]
    for sector in state.sectors:
        sector.integrity -= 0.01 * wear_factor
```

Clamped at minimum.

This forces maintenance.

---

# 8. PLAYER COMMANDS

Add:

```
set repair 0-4
set defense 0-4
set surveillance 0-4
fortify <sector> 0-4
```

Implement in:

```
terminal/commands/policy.py
```

Example:

```python
def cmd_set_repair(state, level):
    state.policies.repair_intensity = int(level)
    return ["REPAIR INTENSITY UPDATED."]
```

---

# 9. AFTER-ACTION SUMMARY INTEGRATION

After assault:

* Display destroyed buildings
* Display policy load state
* Show delta effects

---

# 10. IMPLEMENTATION PLAN (ORDERED)

Codex must implement in this order:

1. Create `core/policies.py`
2. Attach PolicyState to GameState
3. Implement render_slider
4. Integrate policy section into STATUS
5. Create fabrication system + queue
6. Add fabrication tick to world loop
7. Add power_load module
8. Integrate power load into brownout logic
9. Add passive wear system
10. Add policy command handlers
11. Update docs:

* `docs/INFRASTRUCTURE_POLICY_LAYER.md`
* Update `docs/CURRENT_STATE.md`
* Update `_ai_context` if necessary

12. Add tests:

* Policy state mutation
* Fabrication speed scaling
* Power load increasing with policy levels
* Wear scaling

---

# 11. ARCHITECTURAL FIT

This integrates cleanly because:

* Uses existing tick loop
* Uses existing state object
* Respects deterministic seed
* Does not alter assault logic
* Expands between-assault pacing
* No UI creep beyond terminal rendering

---

# 12. RESULTING GAME LOOP

Between assaults:

* Allocate fabrication bandwidth
* Adjust repair intensity
* Tune defense readiness
* Balance surveillance
* Fortify key sectors
* Monitor system load
* Manage degradation

Assault hits.

Infrastructure decisions determine outcome.

Recovery phase begins.

---

# 13. STRATEGIC IDENTITY

This is not:

* RimWorld
* Factorio
* Tower defense

It is:

> Infrastructure resilience command simulation under asymmetric hostile pressure.

---

# NEXT STEP

Once implemented:

We can introduce:

* Enemy memory adapting to your policy bias
* Logistics throughput caps
* Multi-stage assault objectives
* Autonomous drone intelligence routing

---

