## 2026-02-27

- Added phase-specific planned doc `design/20_features/planned/PROCGEN_PHASE0_INSTRUMENTATION.md` defining deterministic procgen instrumentation schema, baseline metrics, and test/acceptance gates.
- Added planned feature roadmap `design/20_features/planned/PROCGEN_FORWARD_PROTOTYPE_ROADMAP.md` to drive a procgen-forward prototype across topology, doctrine, economy, event chains, objectives, and UI readability.
- Added in-terminal `TUTORIAL` command with topic drilldowns matching the `HELP` tree.
- Enabled optional leading `/` on terminal commands (e.g., `/TUTORIAL CORE`) for UI parity.
- Documented tutorial usage in world-state terminal docs.
- Expanded tutorial topics with formatted message tags, examples, and UI-focused guidance.

## 2026-02-25

- Executed documentation architecture migration from legacy `docs/` and `feature_planning/` into canonical `design/` and projection `ai/`.
- Established foundation canon under `design/00_foundations/` (`ARCHITECTURE`, `SIMULATION_RULES`, `CORE_DESIGN_PRINCIPLES`, `ENGINE_TRANSITION_STRATEGY`).
- Consolidated system documentation under `design/10_systems/` for assault, infrastructure, procgen, and hub/campaign domains.
- Moved feature lifecycle docs to `design/20_features/{planned,in_progress,completed}`.
- Moved audits and superseded variants to `design/archive/{audit,deprecated,historical}`.
- Migrated AI projection docs to `ai/` (`CONTEXT`, `CURRENT_STATE`, `FILE_INDEX`).
- Archived root-level implementation artifacts (`IMPLEMENTATION.txt`, `IMPLEMENTATION-V1.txt`, `COMMANDS.txt`).
- Removed legacy canonical source directories (`docs/`, `feature_planning/`) after migration.
- Implemented deterministic sector grid substrate in world-state simulation (`GRID_WIDTH=12`, `GRID_HEIGHT=12` per sector).
- Added structure instance layer with deterministic IDs (`S<n>`), grid occupancy, and snapshot serialization/migration (`snapshot_version=3`).
- Added `BUILD <TYPE> <X> <Y>` command with material costs and command-authority enforcement.
- Added structure registry data for `WALL`, `TURRET`, and `GENERATOR`, plus deterministic perimeter-layout helper for fortification migration.
- Added grid/placement invariants and coverage tests (`test_grid_building.py`), with full world-state suite passing.
- Moved `GRID-SURFACE-DESIGN.md` from `design/20_features/planned/` to `design/20_features/completed/`.
- Wired `FORTIFY <SECTOR> <0-4>` to deterministic perimeter wall auto-generation (`PERIMETER`-tagged wall instances) while preserving numeric fortification levels for compatibility.
- Added fortification-grid regression tests (`test_grid_fortification.py`) covering deterministic generation, level transitions, and non-overwrite guarantees for non-perimeter structures.
- Integrated grid-topology pressure shaping into assault damage multiplier (`core/grid_assault.py`), using deterministic perimeter coverage/continuity signals.
- Added assault-topology tests (`test_grid_assault_topology.py`) validating intact-perimeter mitigation, weak-segment pressure increase, and deterministic replay.
- Added operational visibility of perimeter topology in `STATUS FULL` (`- PERIMETER TOPOLOGY:` lines with per-sector coverage/continuity percentages).
- Added deterministic perimeter-wall erosion during high-pressure assault degradation, allowing fortification topology to decay over repeated impacts.
- Extended topology model with weakest-perimeter-segment scoring and surfaced `WEAK` integrity telemetry in `STATUS FULL`.
- Added deterministic drone perimeter-repair routing (`core/drone_repairs.py`) with weakest-edge-first restoration (one wall per tick per available stock).
- Added explicit operator policy control: `POLICY DRONE_REPAIR <AUTO|OFF>` with status drilldown telemetry (`DRONE PERIMETER REPAIR` mode + backlog) in `STATUS FULL`/`STATUS POLICY`.
