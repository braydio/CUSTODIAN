# PROJECT_CONTEXT_PRIMER.md

**CUSTODIAN — Canonical State Overview**
Version: 0.1
Purpose: Provide a consolidated, high-signal context document for AI sessions and future development planning.

---

# 1. Project Identity

**CUSTODIAN** is a terminal-first, deterministic, simulation-driven command-post defense game.

Core loop:

```
Recon / Expedition → Return with materials + knowledge
→ Build / reinforce base
→ Assault event
→ Repair + analyze
→ Repeat
```

Design pillars:

- Deterministic simulation
- Terminal-native command interface
- Authority tied to physical presence
- Information degradation as a gameplay pillar
- Reconstruction over extermination
- Epistemic progression (knowledge unlocks) over raw stat inflation

---

# 2. Runtime Architecture

## Entrypoints

- `python -m game` → Unified CLI
- `--ui` → Web terminal interface
- `--repl` → Interactive loop
- `--sim` → Autonomous simulation

## Determinism & Contract Hardening

High confidence (~100% complete):

- Seeded state initialization
- Idempotent `/command`
- Snapshot versioning + migration
- Invariant enforcement layer
- Full pytest suite (102 passing in world-state tests)

This provides a stable simulation spine.

---

# 3. Simulation Structure

## 3.1 World-State Layer (Ambient Loop)

Drives:

- Assault spawning
- Power degradation
- Logistics throughput
- Fabrication ticks
- Policy modifiers
- Relay system progression

Primary modules:

- `core/state.py`
- `core/policies.py`
- `core/logistics.py`
- `core/power.py`
- `core/fabrication.py`
- `core/relays.py`
- `core/assaults.py`

---

## 3.2 Assault Simulation

Status: ~90% implemented.

Features:

- Spatial approach lanes
- Multi-tick tactical loop
- Interception spending ammo
- ETA modeling
- After-action reporting
- Assault ledger + trace debugging
- Deterministic resolution

Assaults are integrated with:

- Power effectiveness
- Policy sliders
- Logistics caps
- Fabrication throughput
- Defense structures

Remaining gaps:

- Explicit operator spend for lane preparation (Phase B)
- Salvage coupling
- Deeper player-directed assault shaping

---

# 4. Authority Model

Authority is location-based.

Two modes:

### Command Presence

- Policy control
- Fabrication management
- Relay synchronization
- Reconstruction interpretation

### Field Presence

- Local repairs
- Interception authority
- Sector-specific actions
- Physical gating of certain commands

This split is ~90% implemented (Phase A complete).

Future expansions:

- Downed state
- Risk escalation in field
- Broader physical consequence model

---

# 5. Infrastructure Systems

## 5.1 Policy Layer (~90%)

- Sliders + presets
- Throughput penalties
- Fabrication + fortification coupling
- Logistics caps

## 5.2 Fabrication (~90%)

- Recipes
- Queue
- Add/cancel/priority
- Throughput scaling by policy/logistics/fortification

## 5.3 Power System (~85%)

- Effective output modeling
- Brownout linkage
- Coupled to:
  - Repairs
  - Comms fidelity
  - Assault defense performance

---

# 6. ARRN Relay Layer (~75%)

Features:

- SCAN
- STABILIZE
- SYNC
- Knowledge index
- Initial mechanical benefit

Current state:

- Functional but shallow
- Lacks long-term decay pressure
- Limited milestone depth
- Weak campaign coupling

This is a major future expansion vector.

---

# 7. Terminal + UI Layer (~85%)

Implemented:

- Boot lock → unlock flow
- Map monitor auto-WAIT
- Snapshot + map panel
- Offline banner
- History
- Completion engine

The UI is intentionally thin — simulation is authoritative.

---

# 8. Coverage Summary

Approximate implementation coverage:

| System                      | Completion |
| --------------------------- | ---------- |
| Deterministic runtime       | ~100%      |
| Presence model Phase A      | ~90%       |
| Assault architecture        | ~90%       |
| Assault introspection tools | ~95%       |
| Policy layer                | ~90%       |
| Fabrication                 | ~90%       |
| Power integration           | ~85%       |
| Relay system                | ~75%       |
| Terminal integration        | ~85%       |

Overall estimated project completion:
**~80–85% for world-state + terminal foundation**

Remaining work is late-phase systems depth and campaign integration.

---

# 9. Known Gaps

## 9.1 Procedural Description Engine

Research exists but not fully implemented.

Current messaging:

- Fidelity-gated templates

Missing:

- Grammar-driven variant engine
- Multi-layer procedural language generation

---

## 9.2 Assault Resource Phases B/C

Missing:

- Explicit lane-prep spending
- Salvage-to-logistics feedback loop
- Deeper tactical shaping by player

---

## 9.3 Field Risk Model

- Downed-state incomplete
- Consequence hooks present but shallow

---

## 9.4 Relay Campaign Depth

Needs:

- Node decay pressure
- Multi-stage progression
- Broader unlock sets
- Stronger campaign spine integration

---

## 9.5 Balance & Long-Run Stability

Open roadmap items:

- Pacing pass
- Integration test expansion
- Snapshot/UI parity refinement

---

# 10. Canonical Source of Truth

Important structural note:

Some `feature_planning/` documents contain stale “not implemented” claims.

Canonical truth source:

```
docs/_ai_context/CURRENT_STATE.md
```

DEVLOG and canonical snapshot reflect implemented relay, logistics, policy, fabrication systems.

Future planning must reconcile planning docs against canonical state to avoid drift.

---

# 11. Recommended Core Campaign Mechanic

## Ghost Protocol Recovery

Theme-aligned epistemic progression mechanic.

### Core Idea

Major actions generate fragmented pre-collapse ghost logs.

Fragments must be reconstructed to unlock permanent systemic advantages.

---

### Loop

1. Assault / repair / relay stabilization generates FRAGMENTS.
2. In command mode:
   - `SCAN GHOSTLOGS`
   - `RECONSTRUCT <DOMAIN>`
   - `STATUS KNOWLEDGE`

3. Reconstruction outcomes are deterministic but fidelity-gated.

---

### Outcomes

Correct reconstruction:

- Permanent knowledge unlock
- Efficiency bonuses
- Earlier assault warnings
- Repair discounts
- Higher STATUS certainty

Incomplete reconstruction:

- No unlock
- Fragments retained

Incorrect reconstruction (low fidelity):

- Temporary misinformation penalty
- Incorrect operational assumptions
- No RNG death spiral

---

### Why It Fits

- Makes information degradation core to gameplay.
- Reinforces reconstruction-over-extermination.
- Deepens command vs field tension.
- Terminal-native and deterministic.
- Provides campaign spine: survival is tactical; progress is epistemic.

---

# 12. Current Development Focus Recommendations

High-leverage next steps:

1. Deepen ARRN relay milestone structure.
2. Implement Assault Phase B lane-prep spending.
3. Add Ghost Protocol minimal implementation.
4. Reconcile planning docs to canonical snapshot.
5. Perform balance + pacing audit pass.
6. Expand long-run integration testing.

---

# 13. Project Status Summary

CUSTODIAN is not early-stage.

It is:

- Architecturally stable
- Deterministic
- Contract-hardened
- Mechanically integrated

Remaining work is depth, campaign layering, and epistemic progression.

The simulation spine is complete.
Now the design spine must be strengthened.
