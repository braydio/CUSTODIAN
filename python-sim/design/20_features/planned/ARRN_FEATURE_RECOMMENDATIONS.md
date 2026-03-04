# ARRN Expansion: Reward Ladder + Decay Loop

> **Status:** Implementation-ready specification
> **Supersedes:** `ARRN_FEATURE_RECOMMENDATIONS.md` (this document)
> **Parent:** TODO.md ARRN expansion item

---

## 1. Knowledge Index → Reward Ladder

### Core Principles

- Deterministic thresholds.
- No raw DPS buffs.
- Rewards bias **information quality, efficiency, and preemption**.
- All effects visible in `STATUS KNOWLEDGE`.

### Knowledge Index Range

```
knowledge_index ∈ [0 … 7]
```

### Tier Table

| Knowledge Index | Unlock | Mechanical Effect | Notes |
|----------------|--------|-------------------|-------|
| 1 | SIGNAL_RECONSTRUCTION_I | DEGRADED sector STATUS redaction reduced by 1 tier | Improves fidelity under low comms/power |
| 2 | MAINTENANCE_ARCHIVE_I | Remote repair cost -1 (floor 1) | Already partially implemented at 3 — move to 2 |
| 3 | THREAT_FORECAST_I | +1 tick earlier assault warning | Adjust assault ETA reveal window |
| 4 | FAB_BLUEPRINTS_I | Unlock 1 new fabrication recipe tier | Gate mid-game fabrication |
| 5 | LOGISTICS_OPTIMIZATION_I | Logistics cap penalty reduced by 10% | Soft efficiency improvement |
| 6 | SIGNAL_RECONSTRUCTION_II | STATUS certainty never drops below DEGRADED (no UNKNOWN) | Removes worst-case redaction |
| 7 | ARCHIVAL_SYNTHESIS | Dormancy pressure halved | Converts ARRN into stabilizing macro-system |

### Design Rationale

- Early levels = quality-of-life and information smoothing.
- Mid levels = efficiency multipliers.
- High levels = systemic stabilization (decay mitigation).
- No pure " + damage" style inflation.

---

## 2. Decay Loop Specification

Relays must not be fire-and-forget.

### Relay State Model

Each relay has:

```
stability ∈ [0 … 100]
state ∈ {UNKNOWN, LOCATED, UNSTABLE, STABLE, WEAK, DORMANT}
```

### Stability Decay (Per Tick)

```python
decay_rate = BASE_DECAY + assault_pressure_modifier

BASE_DECAY = 0.5 per tick
assault_pressure_modifier = active_assaults * 0.2
```

**Examples:**

| Condition | Decay Rate |
|----------|------------|
| No active assaults | 0.5 |
| 1 active assault | 0.7 |
| 2 active assaults | 0.9 |

### State Thresholds

| Stability | Relay State |
|-----------|-------------|
| 70–100 | STABLE |
| 30–69 | WEAK |
| 0–29 | DORMANT |

### Behavior by State

**STABLE**
- Contributes to knowledge_index progression.
- No penalties.

**WEAK**
- Knowledge contribution reduced by 50%.
- 10% chance per SYNC to fail (deterministic via seeded RNG).

**DORMANT**
- Contributes 0 to knowledge.
- Adds Dormancy Pressure (see below).

---

## 3. Dormancy Pressure (Global Consequence)

Dormancy Pressure is the tension mechanic that forces player attention.

```
dormancy_pressure = count(DORMANT relays)
```

### Effects

#### A. Assault Frequency

For each dormant relay:
```
assault_interval -= 1 tick
(minimum clamped)
```

Dormant relays increase ambient hostility.

#### B. Fidelity Suppression

If `dormancy_pressure >= 2`:
- STATUS output occasionally redacts even at good power.
- WAIT procedural messaging more pessimistic.
- Reinforces narrative degradation.

#### C. Knowledge Drift

If `dormancy_pressure >= 3`:
```
knowledge_index degrades by 1 every N ticks
```

This is slow erosion. Not instant punishment — creeping loss.

---

## 4. Player Control Surface

Minimal, aligned with existing command stack:

- `SCAN RELAYS` — View relay network status
- `STABILIZE RELAY <NAME>` — Field action to restore stability
- `SYNC` — Command action to convert packets to knowledge
- `STATUS KNOWLEDGE` — View current knowledge index and unlocks

### Future Extensions (Not in Scope)

- `ALLOCATE TECHNICIANS RELAYS`
- `PRIORITIZE RELAY <NAME>`

---

## 5. Loop Behavior Summary

### Healthy Loop

Stabilize → Sync → Unlock → System efficiency improves → Stabilize easier.

### Neglected Loop

Ignore → Relays decay → Dormancy pressure rises → Assaults intensify → Knowledge degrades → Player forced to respond.

---

## 6. Mathematical Implementation Compact

```python
# Per tick
for relay in relays:
    active_assaults = count_active_assaults()
    decay_rate = 0.5 + (active_assaults * 0.2)
    relay.stability -= decay_rate

    if relay.stability <= 0:
        relay.state = DORMANT
    elif relay.stability < 30:
        relay.state = WEAK
    else:
        relay.state = STABLE

# Global calculations
dormancy_pressure = sum(1 for r in relays if r.state == DORMANT)

# Assault frequency modifier
assault_interval = base_interval - dormancy_pressure

# Knowledge drift (if dormant >= 3)
if dormancy_pressure >= 3 and tick % KNOWLEDGE_DRIFT_PERIOD == 0:
    knowledge_index = max(0, knowledge_index - 1)
```

---

## 7. Design Integrity Check

This fits CUSTODIAN because:

- Frames knowledge as fragile.
- Creates epistemic defense.
- Makes reconstruction an ongoing responsibility.
- Does not introduce arcade-style stat inflation.
- Deepens campaign spine without UI bloat.

---

## 8. Open Questions (For Implementation)

Before coding, finalize:

1. **Max knowledge_index cap:** 7 vs 10 (sticking with 7)
2. **Drift below unlocked tiers:** Can knowledge drop below a tier's threshold? (Recommendation: Yes, enforces fragility)
3. **ARCHIVAL_SYNTHESIS permanently disables decay:** No — halve only (maintains ongoing responsibility)

### Resolution (2026-03-02)

- `knowledge_index` cap locked to `7`.
- Knowledge drift below unlocked tiers is allowed.
- `ARCHIVAL_SYNTHESIS` halves dormancy pressure; it does not disable decay/drift.
- Tier 4 `FAB_BLUEPRINTS_I` is implemented as an `ARCHIVE_PLATING` fabrication gate unlock.

---

## 9. Files to Modify

| File | Changes |
|------|---------|
| `game/simulations/world_state/core/relays.py` | Add stability, decay logic, dormancy pressure |
| `game/simulations/world_state/core/state.py` | Add dormancy_pressure field, knowledge drift logic |
| `game/simulations/world_state/core/assaults.py` | Wire dormancy_pressure to assault_interval |
| `game/simulations/world_state/core/fidelity.py` | Wire dormancy_pressure to fidelity suppression |
| `game/simulations/world_state/terminal/commands/status.py` | Add STATUS KNOWLEDGE section |

---

## 10. Test Plan

### Unit Tests

1. Stability decay formula matches spec.
2. State transitions at correct thresholds.
3. Dormancy pressure calculations.
4. Knowledge index unlocks at correct tiers.

### Integration Tests

1. Relays decay over time without player action.
2. Dormancy pressure affects assault timing.
3. Knowledge unlocks provide specified effects.
4. SYNC fails deterministically at WEAK state.

### Regression Tests

1. Existing ARRN commands still work.
2. Snapshot compatibility maintained.
3. Determinism preserved.

---

## 11. Status: Ready for Implementation

This spec is implementation-ready. All mechanical effects are defined, bounded, and deterministic.

**Next step:** Move to `in_progress/` and begin slice implementation.
