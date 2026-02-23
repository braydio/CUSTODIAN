# ENGINE_AND_SYSTEMS_IMPROVEMENTS.md

_CUSTODIAN — Technical Refinement Plan_

---

# 1. Simulation Core Refinement

## 1.1 Explicit Simulation Phases

The world-state tick currently performs multiple responsibilities:

- Assault advancement
- Fabrication queue processing
- Logistics recalculation
- Power output evaluation
- Relay task ticking
- Wear/passive degradation

These occur deterministically, but the order is implicit.

### Improvement

Introduce an explicit ordered simulation pipeline:

```
tick():
    1. resolve_power()
    2. resolve_logistics()
    3. resolve_policies()
    4. resolve_fabrication()
    5. resolve_assaults()
    6. resolve_relays()
    7. resolve_wear()
    8. validate_invariants()
```

Benefits:

- Deterministic reasoning clarity
- Easier performance profiling
- Safer future mechanic injection
- Reduced accidental coupling

---

## 1.2 Domain Separation Enforcement

Several subsystems currently reference each other directly (e.g., fabrication touching logistics multipliers, assaults reading power state).

### Improvement

Introduce a lightweight domain service interface:

```
class PowerDomain:
    def effective_output(self) -> float

class LogisticsDomain:
    def throughput_multiplier(self) -> float
```

Other systems consume interfaces instead of state internals.

Benefits:

- Lower coupling
- Easier snapshot version migrations
- Safer refactors
- Better test isolation

---

## 1.3 Deterministic Event Queue

Assaults and relay tasks operate per tick but are not formalized as event queues.

### Improvement

Introduce a deterministic event scheduler:

```
ScheduledEvent:
    execute_at_tick
    priority
    domain
```

Use a stable, seed-based ordering.

Benefits:

- Future real-time compatibility
- Clean handling of delayed repairs
- Clean handling of staged assaults
- Better debugging traceability

---

# 2. State & Snapshot Architecture

## 2.1 Snapshot Delta Encoding

Snapshots are versioned and migrated, but currently stored monolithically.

### Improvement

Add optional delta snapshotting:

- Store base snapshot
- Store incremental state deltas per tick window

Benefits:

- Faster UI reloads
- Smaller persistence footprint
- Better replay debugging

---

## 2.2 Explicit State Schema Registry

State invariants exist, but schema shape is implicit in the GameState class.

### Improvement

Create a formal state schema registry:

```
STATE_SCHEMA = {
    "power": float,
    "fabrication_queue": list,
    "assault_state": dict,
}
```

Add automated snapshot shape validation.

Benefits:

- Safer migrations
- Easier feature integration
- Reduced silent state drift

---

# 3. Assault Engine Enhancements (Engine-Level Only)

Assault logic is robust (~90% implemented per audit ), but can be structurally hardened.

## 3.1 Separate Tactical Resolution Layer

Currently assault logic handles:

- Routing
- Defense resolution
- Ammo consumption
- ETA advancement
- After-action summaries

### Improvement

Split into:

- `assault_model.py` (data & state)
- `assault_resolution.py` (combat math)
- `assault_reporting.py` (output lines)

Benefits:

- Cleaner balancing passes
- Easier deterministic replay
- Simpler debug trace isolation

---

## 3.2 Ledger Compression & Replay Mode

Assault ledger exists (~95% complete ).

### Improvement

Add:

- Compact ledger export
- Replay command: `ASSAULT REPLAY <id>`

Benefits:

- Dev balancing
- Regression detection
- Campaign review tooling

---

# 4. Power System Structural Hardening

Power-performance integration is ~85% implemented .

## 4.1 Power as First-Class Budget Object

Currently effective output is derived from state.

### Improvement

Model power as:

```
PowerBudget:
    generation
    allocation_map
    brownout_threshold
    overload_penalty
```

Other domains request allocation explicitly.

Benefits:

- Enables future active routing
- Cleaner brownout behavior
- Makes power visible as a control surface

---

## 4.2 Cross-Domain Power Contracts

Define explicit minimum thresholds:

- Assault defense requires X%
- Relay sync requires Y%
- Fabrication requires Z%

Instead of soft coupling via multipliers.

Benefits:

- Prevents emergent edge-case bugs
- Easier balancing
- Clearer invariant enforcement

---

# 5. Fabrication System Improvements

Fabrication realization is ~90% implemented .

## 5.1 Queue Determinism Guarantee

Ensure:

- Stable priority ordering
- Deterministic throughput scaling
- No floating-point accumulation drift

Recommendation:

- Use integer-based work units per tick

---

## 5.2 Resource Ledger Normalization

Introduce a unified ledger:

```
ResourceLedger:
    source
    sink
    timestamp
    domain
```

Instead of implicit deductions.

Benefits:

- Debug visibility
- Campaign audit trails
- Easier balancing

---

# 6. Relay System Expansion (Engine Infrastructure)

ARRN layer is ~75% implemented .

## 6.1 Relay Node State Machine Formalization

Explicit states:

```
DORMANT
SCANNED
STABILIZING
SYNCING
SYNCED
DEGRADED
```

With transition table.

Benefits:

- Prevents invalid state drift
- Enables milestone logic
- Clean future decay modeling

---

## 6.2 Knowledge Unlock Registry

Introduce:

```
KnowledgeUnlock:
    id
    domain
    mechanical_effect
    persistence_scope
```

Decoupled from relay implementation.

Benefits:

- Prepares for Ghost Protocol mechanic
- Enables campaign progression spine
- Keeps unlock logic centralized

---

# 7. Procedural Messaging Engine (Technical Only)

Current system uses fidelity-gated templates .

Research doc describes more advanced grammar engine (not implemented).

## 7.1 Controlled Procedural Description Layer

Introduce:

- Template banks
- Deterministic grammar expansion
- Domain-specific vocabulary pools

Constraint:

- Must remain deterministic under seed

Benefits:

- Reduces repetition
- Supports information degradation theme
- No randomness beyond seed

---

# 8. Test Coverage Expansion

Current world-state tests: 102 passing .

## 8.1 Add Deterministic Replay Tests

Test:

- Same seed
- Same command stream
- Identical final snapshot

---

## 8.2 Assault Balance Regression Suite

Store:

- Known assault seeds
- Expected outcomes

Ensure:

- Future balance changes are intentional

---

## 8.3 Snapshot Migration Forward-Compatibility Test

Simulate:

- Load v1 snapshot into v3 engine
- Validate invariant stability

---

# 9. Development Planning Infrastructure Improvements

## 9.1 Planning Doc Canonicalization

Audit found stale claims in `feature_planning/` conflicting with canonical docs .

### Improvement

Adopt:

```
docs/_ai_context/ = canonical truth
feature_planning/ = aspirational only
```

Add a planning status header in each file:

```
STATUS: IMPLEMENTED / PARTIAL / FUTURE
LAST VERIFIED: YYYY-MM-DD
```

---

## 9.2 System Readiness Index

Add a generated file:

```
SYSTEM_READINESS.md
```

Auto-calculated from:

- Test coverage
- Invariant violations
- Snapshot migrations
- Feature flags

---

# 10. Performance & Scaling

Current architecture is efficient for terminal-based cadence.

Future readiness improvements:

- Avoid O(n) scans per tick where possible
- Cache derived multipliers
- Introduce profiling hooks around tick loop
- Add optional performance metrics mode

---

# Summary of Engine Priorities (Ordered)

1. Explicit simulation pipeline
2. Domain interface separation
3. Event scheduler
4. Power budget formalization
5. Assault resolution separation
6. Relay state machine formalization
7. Deterministic replay testing
8. Snapshot delta system
9. Procedural grammar engine
10. Planning canonicalization

---

This document isolates pure engine/system improvements and removes gameplay redesign discussion, maintaining separation of concerns as recommended in the audit .

If you’d like next, I can now extract:

- `GAMEPLAY_AND_MECHANICS_IMPROVEMENTS.md`
- `CORE_MECHANIC_GHOST_PROTOCOL.md`
- or `PROJECT_CONTEXT_PRIMER.md`
