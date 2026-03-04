Understood. We are now at the **Spatial Combat Coupling seam**.

You have a deterministic assault engine.
You have a spatial grid substrate.
They are not yet coupled.

This is the exact architectural moment where CUSTODIAN either becomes a real spatial strategy engine… or remains a layered sim.

We will proceed precisely.

---

# Phase 2 — Spatial Combat Coupling (Concrete Implementation Spec)

This is not conceptual design.
This is deterministic engine wiring.

---

# 1️⃣ Perimeter Integrity Metric

### Purpose

Replace abstract fortification multiplier with actual structural continuity derived from the grid.

---

## Definition

A sector has:

- `grid[12][12]`
- Structure registry with IDs
- Perimeter walls auto-generated from fort level

We must compute:

```python
integrity = intact_segments / total_expected_segments
```

---

## Implementation Contract

Create:

```python
# game/simulations/world_state/core/spatial_combat.py

def calculate_perimeter_integrity(sector) -> float:
```

### Algorithm

1. Retrieve expected perimeter coordinates
   - Use same generator used by auto-wall builder.
   - Do NOT duplicate geometry logic.
   - Call shared `generate_perimeter_coords(fort_level)`.

2. For each perimeter coordinate:
   - If structure exists AND hp > 0 → intact
   - Else → destroyed

3. Return:

```python
return intact / total
```

Edge case:

- If total == 0 → return 0.0

---

## Determinism Guarantee

- No RNG
- No floating instability (round to 4 decimals)

---

# 2️⃣ Breach Vector Selection

Assault has approach direction already (N/S/E/W or vectorized).

We must breach where integrity is weakest.

---

## Create:

```python
def select_breach_vector(sector, approach_direction) -> list[Coord]:
```

### Steps

1. Filter perimeter coordinates aligned with approach side
   - North approach → northern perimeter row
   - South → southern row
   - etc.

2. Partition into contiguous clusters
   - 4-connected adjacency

3. For each cluster:
   - Compute mean HP
   - Compute size

4. Select cluster with:
   - Lowest mean HP
   - Tie-breaker: lowest sum of HP
   - Final tie-breaker: lexicographically smallest coord

This guarantees replay stability.

Return cluster coordinates.

---

# 3️⃣ Replace Threat Mult Scaling

Current:

```python
threat_budget *= threat_mult
```

Replace with:

```python
integrity = calculate_perimeter_integrity(sector)
breach_severity = 1.0 - integrity
threat_budget *= (1.0 + breach_severity)
```

Examples:

| Integrity | Severity | Threat Mult |
| --------- | -------- | ----------- |
| 1.0       | 0.0      | 1.0         |
| 0.75      | 0.25     | 1.25        |
| 0.50      | 0.50     | 1.50        |
| 0.0       | 1.0      | 2.0         |

This scales pressure without randomness.

---

# 4️⃣ Wall Damage Priority Model

Modify assault tick loop:

Current:
Damage applied abstractly.

Replace with staged propagation:

```
1. Apply damage to breach cells
2. If breach cells destroyed → mark breach_open = True
3. Only then propagate to interior cells
```

Interior propagation order:

1. Defensive structures
2. Power nodes
3. Fabrication
4. Core

Maintain deterministic priority ordering by structure ID.

---

# 5️⃣ Assault Tick Update Flow

Updated assault tick:

```python
def resolve_assault_tick(...):

    if not breach_open:
        breach_cells = select_breach_vector(...)
        apply_damage_to(breach_cells)
        update_integrity_cache()

        if breach_cells_destroyed:
            breach_open = True
    else:
        propagate_interior_damage()
```

Transit interception remains unchanged.

---

# 6️⃣ Required Tests

Add deterministic replay tests:

### A. Fully intact walls

- Integrity = 1.0
- No breach severity

### B. 50% destroyed perimeter

- Integrity ≈ 0.5
- Severity ≈ 0.5

### C. Completely destroyed

- Integrity = 0.0
- Severity = 1.0

### D. Deterministic seed replay

- Same seed → identical breach cluster selection

### E. Approach direction variation

- North vs South → different breach vector

---

# Architectural Impact Assessment

This change:

- Removes final abstraction layer from combat
- Makes grid structurally meaningful
- Preserves determinism
- Does NOT introduce pathfinding yet
- Does NOT introduce real-time logic
- Does NOT break snapshot compatibility

This is a clean seam.

---

# Engine Position After Implementation

You will now have:

```
Deterministic World-State
+ Spatial Topology
+ Structural Damage Propagation
= Grid-Driven RTS Simulation Core
```

At that point:

You are no longer a “terminal sim.”

You are a deterministic spatial RTS engine with terminal control.

---

# Important Strategic Decision

Before implementing:

Do you want:

A) Pure perimeter breach only
I strongly recommend:

Start with A.
Lock it.
Then iterate.

---

- I can draft the exact file diffs for Codex
- Or formalize spatial damage propagation spec
- Or design turret radius influence model
- Or wire Ghost Protocol Recovery into assault aftermath
