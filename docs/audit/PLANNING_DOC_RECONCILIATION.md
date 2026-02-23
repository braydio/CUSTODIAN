# PLANNING_DOC_RECONCILIATION.md

## Purpose

This document reconciles discrepancies between:

- `feature_planning/`
- `docs/_ai_context/`
- The actual implementation in `game/` and `custodian-terminal/`

Its role is to:

- Identify stale or contradictory planning claims
- Establish a canonical truth source
- Prevent future drift between planning docs and implemented systems
- Clarify what remains truly unimplemented

This file is not speculative. It reflects actual code state versus planning assertions.

---

# 1. Canonical Truth Source

**The authoritative project state is:**

```
docs/_ai_context/CURRENT_STATE.md
```

This file must override any older claims in:

```
feature_planning/
```

If a planning file contradicts CURRENT_STATE.md or implemented code, the planning file is considered stale.

---

# 2. Coverage Summary (Post-Reconciliation)

After reviewing:

- `docs/`
- `feature_planning/`
- `game/`
- `custodian-terminal/`

### Overall Implementation Estimate

**80–85% complete for world-state + terminal foundation systems.**

Remaining work is primarily:

- Late-phase depth systems
- Campaign progression coupling
- Procedural narrative engine
- Balance/pacing refinement
- Extended ARRN progression

---

# 3. Implemented Systems (Confirmed in Code)

The following are implemented despite some planning files claiming otherwise:

---

## 3.1 Deterministic Runtime + Contract Hardening (~100%)

Confirmed implemented:

- Seeded state
- Idempotent `/command`
- Snapshot versioning and migration
- State invariants

References:

- `game/simulations/world_state/core/state.py`
- `game/simulations/world_state/server_contracts.py`
- `game/simulations/world_state/core/invariants.py`

Status: Complete and stable.

---

## 3.2 Embodied Presence – Phase A (~90%)

Implemented:

- Command vs Field authority split
- Travel graph flow
- Field authority gating
- Local vs remote repair distinction

References:

- `core/presence.py`
- `terminal/processor.py`
- `core/repairs.py`

Remaining:

- Downed-state system
- Expanded field risk hooks

Planning files incorrectly imply this layer is still conceptual.

---

## 3.3 Assault Architecture (~90%)

Implemented:

- Spatial approaches
- Multi-lane routing
- ETA calculation
- Interception with ammo spending
- Multi-tick tactical loop
- After-action reporting

References:

- `core/assaults.py`
- `core/assault_ledger.py`
- `terminal/processor.py`

Remaining:

- Explicit lane preparation spending
- Salvage-resource coupling (Phase B/C)

---

## 3.4 Assault Dev/Debug Tooling (~95%)

Implemented:

- Assault ledger
- Trace toggle
- Debug report command surface

Planning docs mark this as pending — this is incorrect.

---

## 3.5 Infrastructure Policy Layer (~90%)

Implemented:

- Policy sliders
- Presets
- Fortify/fabrication allocation
- Logistics throughput penalties

References:

- `core/policies.py`
- `terminal/commands/policy.py`
- `core/logistics.py`

Planning files still list policy system as incomplete.

This is stale.

---

## 3.6 Fabrication System (~90%)

Implemented:

- Recipes
- Queue system
- Add/cancel/priority
- Throughput coupling to policy + logistics + fortification

References:

- `core/fabrication.py`
- `terminal/processor.py`

Remaining:

- Deeper supply-chain feedback loops
- Salvage integration

---

## 3.7 Power-Performance Integration (~85%)

Implemented:

- Effective output computation
- Wired into:
  - Repairs
  - Comms fidelity
  - Assault defense behavior

References:

- `core/power.py`
- `core/repairs.py`

Planning files sometimes describe power as conceptual — that is outdated.

---

## 3.8 ARRN Relay Layer (~75%)

Implemented:

- Scan
- Stabilize
- Sync
- Relay tasks
- Knowledge index
- Initial mechanical benefit

References:

- `core/relays.py`
- `terminal/processor.py`

Remaining:

- Node decay
- Long-term progression
- Campaign-layer unlock integration

Planning docs underestimate current relay implementation depth.

---

## 3.9 Terminal/UI Integration (~85%)

Implemented:

- Boot lock → unlock flow
- Map monitor auto-WAIT
- Snapshot/map panel
- Offline banner
- Command history + completion

References:

- `custodian-terminal/boot.js`
- `custodian-terminal/terminal.js`
- `sector-map.js`

Planning documents frequently treat UI as minimal — this is outdated.

---

# 4. Systems Truly Not Fully Implemented

These remain accurate gaps:

---

## 4.1 Procedural Description Engine

Planning describes:

- Grammar-driven variation engine
- Contextual variant generation
- Narrative synthesis

Current implementation:

- Template-based fidelity gating
- Not full grammar-driven procedural generation

This is genuinely incomplete.

---

## 4.2 ARRN Deep Milestones

Missing:

- Node decay over time
- Multi-layer relay unlock trees
- Strong campaign coupling
- Progressive knowledge tiers

Current ARRN = foundation layer only.

---

## 4.3 Assault Resource Phases B/C

Missing:

- Explicit operator spend for lane prep
- Salvage-material coupling
- Advanced interception doctrine depth

Phase A architecture exists.

---

## 4.4 Downed-State + Field Risk Layer

Presence seam exists.

Missing:

- Downed-state consequences
- Extraction mechanics
- Expanded risk propagation

---

## 4.5 Balance and Long-Run Integration Tests

Roadmap flags still valid:

- Assault pacing pass
- Economic scaling
- Snapshot/UI parity refinement
- Extended deterministic simulation runs

---

# 5. Identified Planning Drift

The following pattern exists:

### feature_planning/ contains stale claims such as:

- "Policy layer not implemented"
- "Relay system conceptual"
- "Fabrication pending"
- "Assault routing future work"

These contradict actual implementation.

Cause:
Planning docs were not updated after implementation.

Effect:
AI sessions misinterpret maturity of systems.
Codex recommendations become misaligned.

---

# 6. Required Structural Fix

To prevent future drift:

### Rule 1

`docs/_ai_context/CURRENT_STATE.md` is authoritative.

### Rule 2

When a feature moves from planned → implemented:

- Update CURRENT_STATE.md
- Append DEVLOG entry
- Update or archive the corresponding planning file

### Rule 3

Add status headers to planning docs:

```
STATUS: IMPLEMENTED
STATUS: PARTIALLY IMPLEMENTED
STATUS: NOT IMPLEMENTED
STATUS: ARCHIVED
```

Without this, planning files become misleading.

---

# 7. Validation Snapshot

Test run:

```
pytest game/simulations/world_state/tests
```

Result:
**102 passed**

This confirms simulation stability and deterministic integrity.

---

# 8. Current Project Reality (Post-Reconciliation)

CUSTODIAN is:

- Architecturally mature
- Deterministic and hardened
- Terminal-native
- Mechanically layered
- Policy/logistics integrated
- Assault system structurally complete

Remaining work is not foundational.

It is:

- Depth expansion
- Epistemic systems (Ghost Protocol fits here)
- Campaign progression layering
- Narrative proceduralization
- Balance refinement

This is a late-mid-stage system, not early prototype.

---

# 9. Recommended Next Action

Immediately:

1. Add STATUS headers to every file in `feature_planning/`
2. Archive clearly outdated planning files
3. Freeze CURRENT_STATE.md as canonical truth
4. Split design speculation from implementation reality permanently

This prevents future confusion for:

- Codex
- ChatGPT sessions
- Human contributors
- Yourself in 3 months

---

End of PLANNING_DOC_RECONCILIATION.md
