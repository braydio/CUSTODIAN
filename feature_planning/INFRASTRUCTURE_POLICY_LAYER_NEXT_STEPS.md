# Infrastructure Policy Layer: Recommended Next Steps

## Purpose
This document proposes the next implementation stage after `feature_planning/INFRASTRUCTURE_POLICY_LAYER-FINAL.md`.
It is scoped to current live systems in:
- `game/simulations/world_state/core/policies.py`
- `game/simulations/world_state/core/fabrication.py`
- `game/simulations/world_state/core/power_load.py`
- `game/simulations/world_state/core/wear.py`
- `game/simulations/world_state/terminal/commands/policy.py`
- `game/simulations/world_state/terminal/commands/status.py`

## Current Baseline
Implemented now:
- Policy sliders and command surface (`SET`, `SET FAB`, `FORTIFY`)
- Policy-aware STATUS block
- Fabrication queue tick processing
- Power-load computation and brownout pressure linkage
- Passive wear tied to defense readiness
- Fortification impact on incoming assault pressure
- After-action policy load summary line

Main remaining gap:
- Fabrication queue is internally ticked but not fully operator-driven as a strategic production loop.

## Recommended Next Step 1: Fabrication Command Surface
### Goal
Make fabrication queue a first-class operator loop.

### Add Commands
- `FAB QUEUE` (view queue + throughput estimate)
- `FAB ADD <CATEGORY> <TASK> <TICKS> <COST>`
- `FAB CANCEL <INDEX>`

### Files
- Add `game/simulations/world_state/terminal/commands/fabrication.py`
- Wire in `game/simulations/world_state/terminal/processor.py`
- Export in `game/simulations/world_state/terminal/commands/__init__.py`
- Add command lines to `game/simulations/world_state/terminal/commands/help.py`

### Rules
- Validate category against `FAB_CATEGORIES`
- Material reservation on add, refund policy on cancel (e.g., 50%)
- Keep deterministic ordering and single-tick progression

### Tests
- New: `game/simulations/world_state/tests/test_fabrication_commands.py`
- Cover add/list/cancel, invalid args, and progression with policy allocation changes

## Recommended Next Step 2: Policy Delta in After-Action
### Goal
Satisfy "delta effects" with meaningful, compact post-assault feedback.

### Add Data Capture
Record assault-start snapshot fields:
- power load
- policy levels
- readiness
- top 3 sector damage values

### Output
Extend after-action summary in `game/simulations/world_state/core/assaults.py`:
- `POLICY LOAD DELTA: <before> -> <after>`
- `READINESS DELTA: <before> -> <after>`
- `MOST DEGRADED: <SECTOR...>`

### Files
- `game/simulations/world_state/core/state.py` (snapshot buffer)
- `game/simulations/world_state/core/assaults.py` (summary generation)

### Tests
- Extend `game/simulations/world_state/tests/test_assault_misc_design.py`

## Recommended Next Step 3: Surveillance Coverage Hooks
### Goal
Make surveillance policy affect more than status semantics.

### Integrations
- Approach warning lead time and certainty tied to `surveillance_coverage`
- Fidelity downgrade pressure scaled by low surveillance policy

### Files
- `game/simulations/world_state/core/assaults.py`
- `game/simulations/world_state/terminal/commands/wait.py`
- `game/simulations/world_state/core/power.py`

### Tests
- Add/extend warning timing and fidelity transition tests

## Recommended Next Step 4: Logistics Throughput Caps
### Goal
Prevent infinite high-policy operation without economic planning.

### Mechanic
- Introduce per-tick logistics budget derived from power load and fabrication state
- High policy settings consume budget faster
- Deficits create temporary policy penalties and repair/fab slowdowns

### Files
- New: `game/simulations/world_state/core/logistics.py`
- Integrate in `game/simulations/world_state/core/simulation.py`
- Surface in `game/simulations/world_state/terminal/commands/status.py`

### Tests
- New: `game/simulations/world_state/tests/test_logistics.py`

## Recommended Next Step 5: Policy Presets (Operator QoL)
### Goal
Reduce command friction while preserving explicit tradeoffs.

### Add Commands
- `POLICY PRESET <SIEGE|RECOVERY|LOW_POWER|BALANCED>`
- `POLICY SHOW`

### Files
- Extend `game/simulations/world_state/terminal/commands/policy.py`
- Update help and status rendering

### Tests
- Verify preset correctness and invariant compliance

## Delivery Order
1. Fabrication command surface
2. After-action deltas
3. Surveillance hooks
4. Logistics cap system
5. Policy presets

## Acceptance Criteria
- All new commands are reflected in HELP and terminal contract tests
- World tick remains deterministic with fixed seed
- Policy changes produce visible tactical/operational consequences within 5-20 ticks
- `./.venv/bin/pytest -q game/simulations/world_state/tests`
- `./.venv/bin/pytest -q tests/test_simulation_step_world.py`
