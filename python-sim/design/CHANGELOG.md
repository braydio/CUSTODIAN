## 2026-03-04

- Completed documentation migration to align with the Godot-authoritative pivot described in `python-sim/CODEX_HANDOFF.md`.
- Rewrote foundational runtime docs to reflect active architecture:
  - `design/00_foundations/ARCHITECTURE.md`
  - `design/00_foundations/CORE_DESIGN_PRINCIPLES.md`
  - `design/00_foundations/GAME_IDENTITY_LOCK.md`
  - `design/00_foundations/SIMULATION_RULES.md`
  - `design/00_foundations/ENGINE_TRANSITION_STRATEGY.md`
- Reworked playable-layer transition docs:
  - `design/30_playable_game/PLAYER_CONTROL_MODEL.md`
  - `design/30_playable_game/ENGINE_PORT_PLAN.md`
  - Marked `design/30_playable_game/RTS_LAYER.md` deprecated as a standalone future layer.
- Archived terminal-specific contract/command docs to `design/archive/terminal-deprecated/`:
  - `COMMANDS.txt`
  - `COMMAND_CONTRACT.md`
  - `CUSTODIAN_TERMINAL.md`
  - `TUTORIAL_DETAILS.md`
- Added new active Godot documentation set under `custodian/docs/`:
  - `ARCHITECTURE.md`
  - `GDSCRIPT_STANDARDS.md`
  - `SCENE_HIERARCHY.md`
- Updated active repo and tracker docs for pivot consistency:
  - `python-sim/README.md`
  - `custodian/README.md`
  - `python-sim/AGENTS.md`
  - `python-sim/design/AGENTS.md`
  - `python-sim/ai/CURRENT_STATE.md`
  - `python-sim/ai/CONTEXT.md`
  - `python-sim/ai/FILE_INDEX.md`
  - `python-sim/TODO.md`
- Added repository-level `AGENTS.md` at project root to unify active runtime/documentation precedence across `custodian/` and `python-sim/`.
- Added `python-sim/design/DOC_STATUS.md` to classify active vs legacy document authority.
- Added status index files:
  - `python-sim/design/10_systems/README.md`
  - `python-sim/design/20_features/README.md`
- Refined post-pivot agent governance in:
  - `python-sim/AGENTS.md`
  - `python-sim/design/AGENTS.md`

## 2026-03-03

- Implemented ambient event diversity pacing in `game/simulations/world_state/core/events.py`:
  - Added category metadata to `AmbientEvent`.
  - Added category table and contextual weighting heuristics (post-assault calm boost, low-power infrastructure boost, long-calm recon boost, same-category penalty).
  - Added recent event memory filtering to suppress exact repeats within a rolling window.
  - Added quiet archetypes and additional environmental/infrastructure archetypes.
- Added event pacing context fields to `GameState` and wired assault completion timestamping (`last_assault_tick`) in `core/assaults.py`.
- Snapshot contract bumped to `snapshot_version=7` with additive `event_context` payload; migration defaults added in `core/snapshot_migration.py`.
- Added ambient event diversity tests in `test_ambient_event_diversity.py` and updated snapshot tests for schema v7.
- Moved `design/20_features/planning/AMBIENT_EVENT_DIVERSITY.md` to `design/20_features/completed/AMBIENT_EVENT_DIVERSITY.md`.
- Added `RELAY` tutorial topic in `game/simulations/world_state/terminal/commands/tutorial.py` and extended tutorial index/unknown-topic guidance to include `RELAY`.
- Extended quickstart tutorial flow in `game/simulations/world_state/terminal/tutorial_flow.py` with post-assault ARRN phases: relay scan, relay deploy, relay stabilization, and relay sync.
- Added tutorial ARRN regression tests in `test_terminal_processor.py` and updated tutorial index contract assertion in `test_terminal_contracts.py`.
- Moved `design/20_features/in_progress/ARRN_TUTORIAL_INTEGRATION.md` to `design/20_features/completed/ARRN_TUTORIAL_INTEGRATION.md`.

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
