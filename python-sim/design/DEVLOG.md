## 2026-03-06

- Implemented the Turret System initial runtime slice in Godot:
  - Added base turret script and four scene variants (gunner/blaster/repeater/sniper).
  - Added initial preplaced turrets in the Defense sector within `game.tscn`.
- Updated projectile runtime to include `team` semantics so defense bullets do not collide with friendly player/turret targets.
- Extended enemy objective targeting:
  - enemies now evaluate grouped objectives (`command_post`, `power_node`, `turret`, fallback `player`)
  - structure attack range is separated from player contact range.
- Added sector/operator group wiring required for objective targeting (`command_post`, `power_node`, `player`).
- Updated active docs and turret feature specification checklist for the implemented slice.

## 2026-03-05

- Implemented Wave Spawning as the first logical feature in the in-progress chain (`Wave Spawning -> Enemy Objective -> Sector Damage -> Repair`).
- Added a Godot-native `WaveManager` that:
  - discovers active spawn nodes via `enemy_spawn` group
  - starts after an initial delay and runs recurring wave intervals
  - staggers individual enemy spawns within each wave to reduce teleport/pop-in feel
  - builds escalating wave point budgets with deterministic composition selection
  - spawns enemies into `/root/GameRoot/World/Enemies` with fast/heavy variant fallback from the base drone scene.
- Added lane-aware spawn-node component (`SpawnNode`) and initial map-edge spawn node placement in `game.tscn`.
- Removed static hand-placed drones from `game.tscn` so combat pressure now originates from wave orchestration.
- Added enemy difficulty hook (`apply_difficulty_modifiers`) to support health/damage scaling from the wave system.
- Added dedicated `fast_drone.tscn` and `heavy_drone.tscn` variants and wired them into `WaveManager` for visible archetype differentiation.
- Added `base_tint` support in `enemy.gd` so variant scenes maintain distinct colors across health-state updates.
- Updated active Godot architecture/hierarchy docs to include wave system ownership and scene nodes.
- Added melee operator action (`Q`) with close-range cone damage, cooldown gating, and impact spark feedback.
- Surfaced melee control in weapon HUD text (`WEAPON: ... | MELEE: Q`).

## 2026-03-04

- Applied repository-wide documentation sync to match post-pivot runtime model in `python-sim/CODEX_HANDOFF.md` (Godot-authoritative active runtime, Python stack as legacy reference).
- Replaced terminal-first foundation docs with Godot-native architecture/timing/control language in `design/00_foundations/*`.
- Updated playable runtime docs in `design/30_playable_game/*` and explicitly deprecated `RTS_LAYER.md` as a separate future adapter model.
- Created new active Godot documentation in `custodian/docs/`:
  - `ARCHITECTURE.md`
  - `GDSCRIPT_STANDARDS.md`
  - `SCENE_HIERARCHY.md`
- Archived terminal contract/command docs into `design/archive/terminal-deprecated/` and removed them from `design/archive/historical/`.
- Updated operational trackers and context docs (`python-sim/README.md`, `custodian/README.md`, `python-sim/ai/*`, `python-sim/TODO.md`, `python-sim/AGENTS.md`, `python-sim/design/AGENTS.md`) to remove stale terminal-first assumptions.
- Added root-level `AGENTS.md` and design-level `DOC_STATUS.md` to explicitly govern active-vs-legacy doc authority across the repo.
- Added `design/10_systems/README.md` and `design/20_features/README.md` as directory-level legacy status markers.

## 2026-03-03

- Implemented Ambient Event Diversity Phase 1-2 in `core/events.py` with category metadata (`QUIET`, `ENVIRONMENTAL`, `INFRASTRUCTURE`, `RECON`, `HOSTILE`), category-aware weighted selection, same-category rotation penalty, and recent-name suppression memory.
- Added quiet signal archetypes (`quiet_perimeter_stable`, `quiet_night_cycle`, `quiet_atmospheric`) and six additional environmental/infrastructure archetypes to expand event surface variety.
- Added event pacing context fields on `GameState` (`recent_events`, `last_event_category`, `ticks_since_assault`, `ticks_since_hostile`, `last_assault_tick`) and updated assault resolution to stamp `last_assault_tick`.
- Added `event_context` to snapshot payload and migration defaults; bumped snapshot schema to `7`.
- Added regression coverage in `test_ambient_event_diversity.py` and updated snapshot schema assertions in `test_snapshot.py`.
- Validated full world-state suite via `./.venv/bin/pytest -q game/simulations/world_state/tests` (`172 passed`).
- Moved feature doc from `design/20_features/planning/` to `design/20_features/completed/` and removed the now-empty `planning/` lifecycle directory.
- Added `TUTORIAL RELAY` topic content in `terminal/commands/tutorial.py` covering relay states, dormancy pressure, and knowledge unlock tiers.
- Extended tutorial quickstart in `terminal/tutorial_flow.py` with ARRN phases after after-action assessment (`SCAN RELAYS`, `DEPLOY`, `STABILIZE RELAY`, `RETURN` + `SYNC`).
- Added terminal tutorial regression coverage for the new topic and quickstart ARRN step progression in `test_terminal_processor.py` and updated tutorial contract topic list assertions in `test_terminal_contracts.py`.
- Moved `ARRN_TUTORIAL_INTEGRATION.md` from `design/20_features/in_progress/` to `design/20_features/completed/`.

## 2026-03-02

- Locked Assault-Resource-Link Phase C salvage-coupling design from `CLARIFY.md` into `design/archive/historical/ASSAULT-RESOURCE-LINK.md` with deterministic formula, bounds, and edge-case handling.
- Implemented Phase C in `game/simulations/world_state/core/assaults.py` and `core/assault_instance.py` using assault-scoped salvage accounting (intercept ammo, tactical ammo, transit fortification wear, intercepted units, total units).
- Replaced fixed penetration salvage with bounded formula-based salvage resolution and added concise after-action salvage breakdown lines in assault impact output.
- Added/updated assault tests for formula behavior, clamp envelopes, zero-unit edge handling, and after-action summary surfacing in `test_assault_misc_design.py`.
- Implemented ARRN expansion in `core/relays.py` with deterministic relay stability decay, state thresholds (`STABLE/WEAK/DORMANT`), dormancy pressure computation, bounded knowledge drift, and tiered relay unlock benefits (`RELAY_RECOVERY` 1-7).
- Added ARRN knowledge/status surfaces: `STATUS KNOWLEDGE`, updated status/help contract strings, and relay sync reporting for weak-link packet corruption.
- Wired ARRN unlock effects into simulation systems: remote repair discount at tier 2, warning lead-time bonus at tier 3, Archive Plating fabrication gate at tier 4, logistics penalty reduction at tier 5, and status-fidelity flooring at tiers 1/6.
- Added ARRN regression coverage in `test_arrn_progression.py` and expanded status/contract snapshot assertions.
- Began procgen Phase 1 (slice A): added deterministic seeded topology profile selection in `core/topology_profiles.py` with bounded profile families and full-name summaries.
- Wired topology profile metadata into `GameState` snapshot and run fingerprint (`snapshot_version=6`), plus migration fallback and restoration support.
- Added topology profile tests covering same-seed determinism, cross-seed divergence, bounded modifiers, and summary token hygiene (`test_topology_profiles.py`).

## 2026-02-27

- Added in-terminal tutorial command surface with topic drilldowns and slash-prefixed command support for UI parity.
- Expanded tutorial content with tagged message formatting, examples, and UI-focused structure.
- Added a quickstart tutorial flow that stages commands through the first assault and returns control to the operator.
