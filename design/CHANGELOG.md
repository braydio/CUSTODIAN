## 2026-03-02

- Began procgen Phase 1 slice A: added deterministic seeded topology profile registry/selector (`core/topology_profiles.py`) with bounded profile families and stable profile IDs.
- Snapshot contract now includes additive `topology_profile` metadata (`profile_id`, full-name `summary`) and migration bump to `snapshot_version=6`.
- `run_fingerprint.topology_profile_id` now reflects the selected topology profile instead of a static baseline token.
- Added topology profile coverage in `test_topology_profiles.py` (determinism, divergence, bounds, summary token hygiene) and updated snapshot assertions.
- Implemented ARRN reward-ladder and decay-loop expansion (`core/relays.py`) with deterministic relay stability decay, `WEAK`/`DORMANT` thresholds, dormancy pressure, bounded knowledge drift, and capped relay knowledge index (`0..7`).
- Added tiered ARRN effects across systems: remote repair discount (tier 2), threat-forecast warning lead-time bonus (tier 3), Archive Plating fabrication gate (tier 4), logistics-penalty reduction (tier 5), and status fidelity floors (tiers 1 and 6).
- Added `STATUS KNOWLEDGE` group output and updated status/help contracts to include `KNOWLEDGE` in grouped status surfaces.
- Extended snapshot relay payload with ARRN benefit/dormancy fields and added ARRN progression tests (`test_arrn_progression.py`) plus updated contract/snapshot assertions.

## 2026-02-27

- Revised `design/20_features/planned/PROCGEN_PHASE0_5_SIGNAL_PROJECTION_INFRASTRUCTURE.md` to align with live implementation constraints (discrete fidelity contract, realistic RNG migration, executable test plan).
- Revised and normalized `design/20_features/planned/PROCGEN_PHASE0_INSTRUMENTATION.md` to remove malformed duplicate sections and align field sources/contracts with live code.
- Began Phase 0.5 implementation: added explicit `sim_rng`/`text_rng` ownership in `GameState` while preserving `rng` compatibility alias.
- Added canonical procgen signal registry at `game/procgen/signals.py`.
- Added reusable projection entrypoint at `game/procgen/projection.py` (deterministic, fidelity-gated, additive scaffold).
- Wired WAIT procgen rendering to the new projection layer behind `GameState.procgen_projection_enabled` (default off) for safe migration.
- Added determinism coverage in `game/simulations/world_state/tests/test_procgen_determinism.py`.
- Added projection parity test coverage in `game/simulations/world_state/tests/test_procgen_engine.py` to ensure flagged path matches legacy output.
- Began Phase 0 implementation: added deterministic `run_fingerprint` to world snapshots (`snapshot_version=5`) and migration support in `snapshot_migration.py`.
- Added deterministic procgen report surface (`GET /procgen_report`) with dev-mode gating in both world-state and terminal servers.
- Added instrumentation tests for snapshot fingerprint stability and procgen report endpoint behavior.
- Added baseline variability harness tests (`test_procgen_variability.py`) for seed-suite uniqueness/switch-rate metrics.
- Added phase-specific planned doc `design/20_features/planned/PROCGEN_PHASE1_TOPOLOGY_PROFILES.md` defining deterministic seeded topology profile generation, rule wiring, and validation gates.
- Added phase-specific planned doc `design/20_features/planned/PROCGEN_PHASE0_INSTRUMENTATION.md` defining deterministic procgen instrumentation schema, baseline metrics, and test/acceptance gates.
- Added planned feature roadmap `design/20_features/planned/PROCGEN_FORWARD_PROTOTYPE_ROADMAP.md` to drive a procgen-forward prototype across topology, doctrine, economy, event chains, objectives, and UI readability.
- Added in-terminal `TUTORIAL` command with topic drilldowns matching the `HELP` tree.
- Enabled optional leading `/` on terminal commands (e.g., `/TUTORIAL CORE`) for UI parity.
- Documented tutorial usage in world-state terminal docs.
- Expanded tutorial topics with formatted message tags, examples, and UI-focused guidance.
- Added `TUTORIAL QUICKSTART` live prompt sequence that guides a first-assault session and hands control back to the operator.

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
