# DEVLOG — CUSTODIAN

## 2026-02-25
- Implemented Assault-Resource-Link Phase B from `feature_planning/ASSAULT-RESOURCE-LINK-V2.md`.
- Added transit fortification state (`transit_fort_levels`) with snapshot persistence and migration fallback.
- Extended `FORTIFY` to accept transit nodes (`T_NORTH`, `T_SOUTH`) without adding new command surface area.
- Updated interception math to include deterministic transit-fortification mitigation (`TRANSIT_FORTIFICATION_FACTOR`) with floor clamp (`THREAT_MULT_FLOOR`).
- Updated policy/status/help command surfaces to document and render transit fortification levels.
- Added transit fortification test coverage in `test_transit_fortification.py` and updated snapshot coverage.

## 2026-02-24
- Implemented deterministic procedural messaging engine under `game/procgen/` (seed mixing, weighted grammar variants, and short anti-repeat memory).
- Added world-state grammar content at `game/simulations/world_state/content/terminal_grammar.json` and adapter layer at `terminal/procgen_text.py` for fidelity-scoped `WAIT` rendering.
- Updated `WAIT` command internals to use procedural line renderers and switched duplicate suppression to semantic signal keys instead of raw rendered text.
- Added canonical event trigger records (`core/event_records.py`) and per-tick `state.tick_events` wiring in simulation/events for stable mechanics-to-text signal mapping.
- Extended world-state tests with procgen coverage (`test_procgen_engine.py`) and relaxed brittle exact-string assertions in `test_terminal_processor.py` to semantic invariants.
- Added CI workflow `.github/workflows/python-tests.yml` to run `pytest` on push and pull request.

## 2026-02-23
- Added consolidated AI handoff primer at `docs/_ai_context/PROJECT_CONTEXT_PRIMER.md` with current architecture, implemented systems, active gaps, and prioritized focus areas for next-step recommendations.
- Updated `docs/_ai_context/AI_CONTEXT.md` read order to include the new primer immediately after `CURRENT_STATE.md`.
- Added concise external-reviewer primer at `docs/_ai_context/PROJECT_CONTEXT_PRIMER_EXTERNAL.md` with runtime model, contract summary, current feature state, active gaps, and immediate focus recommendations.
- Improved FIELD-mode `STATUS` output with local tactical context: explicit area status, local damage summary, connected travel routes with command-ready `MOVE` tokens, immediate local priorities, and actionable next commands (`RETURN`, `MOVE`, `REPAIR`, `STABILIZE RELAY`).
- Standardized user-facing transit/relay naming to longhand labels in command/status/assault messaging (for example, `NORTH TRANSIT`, `NORTH RELAY`) while keeping internal IDs unchanged.

## 2026-02-22
- Added logistics throughput cap system (`core/logistics.py`) and integrated it into `step_world`; repair and fabrication throughput now slow deterministically under overload pressure.
- Extended status/policy readouts with logistics load/throughput/multiplier visibility and added invariant checks for logistics state.
- Added infrastructure-policy tests covering logistics pressure and repair slowdown behavior.
- Updated `AGENTS.md` with a best-practice rule for dependency-heavy work: implement in validated slices instead of all-at-once rewrites.
- Implemented ARRN relay command slice: `SCAN RELAYS` (command), `STABILIZE RELAY <ID>` (field/local timed task), and `SYNC` (command packet conversion to knowledge index).
- Added relay state to `GameState` (`relay_nodes`, `relay_packets_pending`, `knowledge_index`, `last_sync_time`) plus status projection and `STATUS RELAY` grouped output.
- Added first relay-derived mechanical benefit: remote repair cost discount after sufficient sync progress (`RELAY_RECOVERY` threshold).
- Added policy QoL commands: `POLICY SHOW` and `POLICY PRESET <BALANCED|SIEGE|RECOVERY|LOW_POWER>`.
- Updated help/authority/status surfaces and terminal completion tokens for new relay/policy commands.
- Expanded world-state tests to cover relay flow, sync authority gating, policy preset/show behavior, and status/help contract updates.
- Updated terminal UI snapshot refresh triggers to include `STATUS`, `SET`, and `FAB`, and added startup snapshot refresh so side-panel map/system state renders immediately after boot handoff.
- Expanded STATUS command surface with grouped detail views: `STATUS FAB`, `STATUS POSTURE`, `STATUS ASSAULT`, `STATUS POLICY`, and `STATUS SYSTEMS` (plus existing `STATUS`/`STATUS FULL`/`STATUS BRIEF` aliases).
- Updated help/contract text and added terminal processor tests for grouped STATUS output and invalid-group usage handling.

## 2026-02-21
- Reconciled `docs/_ai_context/` to current implementation and removed stale aggregated-context drift from `AI_CONTEXT.md`.
- Updated canonical docs for current command contract, architecture boundaries, simulation rules, file index, and active roadmap.
- Synced help-command documentation to the new categorized tree model (`HELP` and `HELP <TOPIC>`).
- Synced wait semantics documentation to current behavior (`WAIT`/`WAIT NX` = 5 ticks per unit, reduced to 1 tick per unit while assault is active).
- Updated terminal UI docs to include current QoL features (history navigation, focus hints, tab completion, jump-to-latest indicator, and keyboard shortcuts).

## 2026-02-20
- Moved repair tick progression into `core/simulation.py::step_world` and changed `WAIT` to consume per-tick repair events from state instead of mutating repair jobs directly.
- Updated STATUS behavior to default to a concise action brief and added `STATUS FULL` for extended diagnostics.
- Updated terminal help and processor parsing to support explicit STATUS verbosity selection (`STATUS`, `STATUS FULL`, `STATUS BRIEF`/`STATUS SUMMARY`).
- Reconciled documentation to current endpoint/runtime behavior (`{command}` canonical request body with `{raw}` fallback, `{ok,text,lines}` response shape, and current STATUS semantics).
- Added a current-runtime snapshot section in `ARCHITECTURE.md` to distinguish historical design lock text from live behavior.
- Rewrote `feature_planning/ASSAULT-RESOURCE-LINK.md` into a codebase-accurate, phased implementation spec centered on transit interception and existing resource systems.
- Implemented Assault-Resource-Link Phase A in `core/assaults.py`: transit-node interception now spends DEFENSE ammo during approach traversal and applies bounded pre-engagement threat mitigation to the resulting assault instance.
- Added coverage for interception mechanics and operator surfacing in `test_assault_misc_design.py` and `test_terminal_processor.py`.

## 2026-02-15
- Completed world-state command-loop QoL/fun pass: added `WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>` batching and `SCAVENGE NX` multi-run support.
- Added recoverable COMMAND breach behavior (`COMMAND_BREACH_RECOVERY_TICKS`) so breach is an emergency window instead of immediate hard fail.
- Tuned WAIT interpretive pressure output to emit stability-decline messaging only when threat/damage actually increased this tick.
- Added ambient-threat maintenance recovery in `advance_time`: while assaults are idle and COMMAND/COMMS/POWER remain healthy, threat can now trend downward.
- Added repair-triggered sector recovery windows in `advance_time`: no passive sector healing; recovery begins only after `REPAIR COMPLETE` and applies faster decay for local/manual repair, then drone-focused remote repair, then baseline remote repair.
- Added explicit full stabilization command path `REPAIR <ID> FULL` with additional material cost, operational-core requirement, and immediate clamp to stable sector thresholds before timed recovery continuation.
- Implemented Infrastructure Policy Layer core systems: `core/policies.py`, policy state on `GameState`, policy-aware STATUS block, policy commands (`SET ...`, `SET FAB ...`, `FORTIFY ...`), and help/contract updates.
- Added policy-linked simulation systems: fabrication queue ticking (`core/fabrication.py`), dynamic power load computation (`core/power_load.py`) feeding blackout pressure, passive wear (`core/wear.py`), and fortification mitigation in assault incoming-pressure computation.
- Added automated coverage in `test_infrastructure_policy_layer.py` and expanded terminal processor contract tests for policy commands/rendering.
- Updated STATUS action guidance and refreshed command/server contract tests for revised HELP/WAIT/failure timing behavior.

## 2026-02-15
- Added structured assault introspection ledger in `core/assault_ledger.py` and wired it into world-state (`GameState.assault_ledger`, `assault_trace_enabled`, `last_target_weights`).
- Instrumented assault resolution to append deterministic per-tick ledger records (target sector/weight, assault strength, defense mitigation), structure-destruction entries, and failure-chain records.
- Extended debug tooling with `DEBUG REPORT` and aligned `DEBUG TRACE` to toggle assault instrumentation visibility state while preserving trace output behavior.
- Added blackout instrumentation in `core/events.py` to log explicit power-delta records into the ledger when trace instrumentation is enabled.
- Added `DEBUG ASSAULT_TRACE` and `DEBUG ASSAULT_REPORT` aliases and a compact player-facing after-action loss summary emitted after assault resolution when structures are destroyed.
- Expanded tests for ledger/report/trace behavior and event instrumentation in `test_assault_misc_design.py` and `test_terminal_processor.py`.

## 2026-02-15
- Replaced timer-driven assault progression with spatial ingress approaches in `core/assaults.py` using `WORLD_GRAPH` routing (`compute_route`) and `AssaultApproach` movement (`EDGE_TRAVEL_TICKS=2`).
- Wired simulation flow to approach advancement/spawn (`advance_assaults`, `maybe_spawn_assault`) while preserving tactical resolution via `resolve_assault`.
- Added non-deterministic transit warning emission during approach movement and derived `assault_timer` as minimum inbound ETA.
- Added salvage awards from assault penetration outcomes and command-mode STATUS ETA projection for inbound approaches.
- Added/updated tests for routing, spawn/movement, salvage, step-world orchestration, and command STATUS/WAIT behavior.

## 2026-02-15
- Implemented assault target scoring in `core/assaults.py` with explicit static/dynamic weighting and transit-lane pressure modifiers, preserving posture modifiers (`FOCUS` and `HARDEN`).
- Added structure destruction side-effect mapping in `core/structure_effects.py` and wired structure-loss tracking (`pending`/`detected`) into world-state and assault degradation flow.
- Added autonomy defensive-margin override for severe non-command assault outcomes, enabling `[ASSAULT] AUTONOMOUS SYSTEMS HELD PERIMETER.` when defensive capacity is sufficient.
- Extended `WAIT` fidelity behavior to surface first-detection structure-loss signals once (FULL/DEGRADED/FRAGMENTED) and suppress identity when fidelity is LOST.
- Added targeted tests in `game/simulations/world_state/tests/test_assault_misc_design.py` plus additional `WAIT` structure-loss tests in `test_terminal_processor.py`.

## 2026-02-15
- Updated `WAIT` pacing to 1-tick units (`WAIT` = 1 tick, `WAIT NX` = `N x 1` tick) while preserving 0.5-second internal pacing and duplicate-line suppression behavior.
- Updated terminal help text, terminal docs, AI context docs, and terminal processor contract tests to match the new wait semantics.

## 2026-02-14
- Implemented field-assault delayed warning behavior: when an assault starts while the player is deployed in FIELD mode, immediate assault signaling is suppressed and warning lines surface after a short deterministic delay window.
- Added test coverage for delayed field warning timing in `game/simulations/world_state/tests/test_terminal_processor.py`.
- Applied `feature_planning/EXECUTE_RECOMMENDED_IMPROVEMENTS.md` and renamed it to `feature_planning/APPLIED-EXECUTE_RECOMMENDED_IMPROVEMENTS.md`.
- Added deterministic world-state seeding (`GameState(seed=...)`, `state.rng`) and routed event/assault/scavenge randomness through state-owned RNG.
- Added `/command` idempotency support (`command_id`) with short-lived replay cache and shared command contract helpers in `game/simulations/world_state/server_contracts.py`.
- Added centralized invariant validation (`core/invariants.py`) and wired checks into tick and command processing.
- Added snapshot schema versioning (`snapshot_version=2`) and migration scaffolding (`core/snapshot_migration.py`), plus state seed and operator log projection in snapshots.
- Extracted modular command/presence helpers: `terminal/authority.py`, `core/presence.py`, `core/tasks.py`, and `core/location_registry.py`.
- Improved terminal accessibility: reduced-motion handling, live region updates, keyboard command history (`ArrowUp/ArrowDown`), focus-visible styling, and an offline banner on repeated command transport failures.
- Expanded operator-facing UI projections with compact logbook lines in the system panel and static role glyphs in sector cards.

## 2026-02-14
- Applied `feature_planning/COMMS_REPAIR_MECHANIC.md` (renamed to `feature_planning/APPLIED-COMMS_REPAIR_MECHANIC.md`).
- Added persistent COMMS fidelity state (`state.fidelity`) with per-tick refresh in `core/simulation.py` via `refresh_comms_fidelity(...)`.
- Added fidelity transition event emission (`[EVENT] INFORMATION FIDELITY ...`) into `WAIT` detail output.
- Updated WAIT tick payload/model to carry fidelity-event lines and preserve fidelity-aware suppression/interpretive behavior.
- Added tests for fidelity refresh/event emission in `tests/test_simulation_step_world.py` and `game/simulations/world_state/tests/test_terminal_processor.py`.

## 2026-02-13
- Implemented a shared power-performance layer in `core/power.py` with deterministic power tiers, integrity modifiers, and `effective_output = power_efficiency * integrity`.
- Integrated power-aware repairs in `core/repairs.py`: speed now scales by mechanic-drone output (`FB_TOOLS`) and sector power tier; DESTROYED reconstruction requires minimum sector power plus powered mechanic drones.
- Added deterministic repair regression on assault damage and cancellation/refund behavior (50% materials) when a structure is destroyed mid-repair.
- Wired COMMS information fidelity to sensor effectiveness thresholds in `WAIT`, `STATUS`, and repair-status responses, while preserving legacy COMMS degradation caps.
- Scaled tactical turret behavior in `assault/core/defenses.py` using effective output (damage/cadence degradation and low-output misfire behavior), fed from DEFENSE GRID structure output via `core/tactical_bridge.py`.
- Added new repair tests for degraded power speed, reconstruction power requirements, and regression/cancel-refund behavior.

## 2026-02-12
- Updated `WAIT` semantics to use 5-tick units (`WAIT` = 5 ticks, `WAIT NX` = `N x 5` ticks) with a 0.5-second internal pacing delay.
- Reworked wait output to emit observed event/signal lines in sequence and suppress adjacent duplicate lines.
- Updated help text, terminal docs, AI context docs, and terminal processor tests to match the new wait pacing/contract.

## 2026-02-11
- Implemented Embodied Presence Phase A: command/field mode split, transit travel graph, and new `DEPLOY`/`MOVE`/`RETURN` command flow.
## 2026-02-15
- Implemented `feature_planning/COLONY-SIM-FEATURES.md` and moved it to `feature_planning/completed/`.
- Completed surveillance wiring: detection speed now scales warning/event visibility and comms fidelity now applies surveillance buffer plus interference penalty.
- Extended assault loop to multi-tick tactical resolution (5-12 ticks) with per-tick feedback lines and tactical command effects (`REROUTE`, `BOOST`, `DEPLOY DRONE`, `LOCKDOWN`, `PRIORITIZE REPAIR`).
- Added after-action impact deltas for sector integrity loss, material delta, power load change, fabrication slowdown signal, and surveillance state.
- Completed fabrication command loop (`FAB ADD/QUEUE/CANCEL/PRIORITY`) and introduced tiered recipe-driven inventory flow (`SCRAP` -> `COMPONENTS` -> `ASSEMBLIES` -> `MODULES`) plus drone/ammo stock outputs affecting assault/repair behavior.
- Added deterministic tests for surveillance/fidelity scaling, fabrication loop behavior, and assault WAIT cadence/phase persistence.

## 2026-02-15
- Implemented the Defense Control Layer from `feature_planning/PLAYER_DESIGNED_DEFENSE.md`: doctrine state, normalized allocation bias, readiness computation, and command-surface configuration (`CONFIG DOCTRINE`, `ALLOCATE DEFENSE`).
- Wired deterministic strategic influence into assaults: doctrine/allocation now affect target weighting, tactical defense output, incoming pressure, structure degradation severity, and repair regression triage.
- Added readiness-driven assault severity scaling in `AssaultInstance` via `effective_threat = base_threat * (1.1 - readiness)` with doctrine scale factor.
- Extended STATUS output with doctrine/allocation/readiness details in command mode.
- Added deterministic tests in `test_assault_doctrine_variation.py` for doctrine variation, allocation distribution effects, readiness severity scaling, and command-authority gating.

## 2026-02-15
- Implemented dev-mode world-state tooling: `GameState.dev_mode` and `GameState.dev_trace`, plus gated `DEBUG` command routing in terminal processor.
- Added debug command handlers for forced assaults, manual tick advancement, assault timer override, sector power override, sector damage override, and trace toggling.
- Added deterministic CLI flags to unified entrypoint: `--dev` and `--seed` now flow into REPL and sim startup state.
- Added structured per-tick assault trace output in `core/assaults.py` behind `state.dev_trace`.
- Added terminal processor tests covering debug-mode gating, forced assault trigger, manual tick advancement, and sector mutation commands.

- Added field-local `STATUS` output (location, task, local structures only) and command-authority gating for strategic commands while deployed.
- Updated repair authority model: remote repair is command-only for DAMAGED, local field repair handles DAMAGED/OFFLINE/DESTROYED with mode-specific timing/cost behavior.
- Updated world-state `/command` endpoint contract handling to accept `{command}` with `{raw}` fallback and return `{ok, text, lines}`.
- Added and updated tests for presence flow, authority gating, snapshot fields, and revised repair/help command contracts.
- Completed feature-planning execution pass and moved planning docs into `feature_planing/completed/`; added recommendation docs in `feature_planning/`.

## 2026-02-10
- Added structure damage scaffolding with timed repairs, plus the `REPAIR` command and repair progression tests.
- Shifted assault outcomes to degrade structures at resolution and tightened status report degradation to match COMMS fidelity rules.
- Cleaned and aligned `docs/SystemDesign.md` and AI context docs with the current structure/repair implementation.
- Reworked WAIT/WAIT 10X output to follow the revised information degradation spec with fidelity-gated event and summary lines.
- Consolidated STATUS/WAIT information degradation rules into `docs/INFORMATION_DEGRADATION.md`.
- Added Phase 1 materials economy: materials in state/snapshot, STATUS resources block, SCAVENGE command, and repair material gating.
- Added structure IDs to STATUS and sector map when COMMS is stable, plus repair-in-progress feedback on reissue.
- Generalized WAIT to accept `WAIT NX` (any positive N).
- SCAVENGE now replays per-tick WAIT detail lines, suppressing repeated no-effect event spam.
- Added FABRICATION as the 9th sector with placeholder structures and repair progress reporting by fidelity.

## 2026-02-09 # {NOTE FOR CODEX}
- CODEX OVER HERE! READ THIS!
- Hi it's Brayden. I want you to put move the contents of docs/INFORMATION_FIDELITY.md to somewhere persistent so that the style of (in-game) information degradation is a persistent design theme. Also thanks for all your hard work. Brayden out.

## 2026-02-09
- Implemented hub/campaign schemas with offer generation, recon refinement, hub mutation rules, and snapshot/load seams.

## 2026-02-07
- Implemented HARDEN posture and updated FOCUS to bias assault target selection only.
- Added ARCHIVE loss counter/threshold and STATUS posture/loss reporting.
- Added system panel + terminal feed formatting and comms-based UI degradation.

## 2026-02-08
- Reconciled campaign contract language: contracts are interface commitments, scenarios are hub-surfaced proposals, rewards are hub mutations justified by context.
- Current focus: finalize the Hub ↔ Campaign scaffolding by defining campaign offer generation, recon-based information refinement, and a strict outcome-to-hub mutation contract before expanding gameplay systems.
- Added `WAIT 10X` support to advance ten ticks with summarized output.
- Removed obsolete `NEXT_FEATURES.md` now that Phase 1 plan is realized.
- Added `GameState.snapshot()` and `/snapshot` endpoints for read-only UI projection.
- Implemented sector map UI that updates only after state-changing commands.
- Added `RESET`/`REBOOT` handling in the terminal processor and slowed/enhanced boot audio cadence.
- Updated Phase 1 sector layout to the canonical 8-sector set with IDs and map positioning.
- Removed `docs/PHASE_I_FINALIZATION.md` after implementing its Phase 1 requirements.
- Implemented Phase 1.5 asymmetry and `FOCUS` command, plus associated map layout updates.
- Removed `docs/PHASE_1.5_BUILD.md` after implementing Phase 1.5 requirements.

## 2026-02-05
- Added terminal webserver `custodian-terminal/server.py` with SSE boot stream.
- Renamed `simulate_*` entrypoints to `sandbox_*` and updated references.
- Hardened `game/run.py` to add repo root to `sys.path` for any CWD.
- Added world-state terminal command stack (parser, processor, command registry, REPL) with read/write authority gating.
- Added `step_world` helper and pytest coverage for world-state stepping and terminal commands.
- Added git hooks for docs/secret hygiene: `pre-commit` (block forbidden files, warn on untracked logs), `commit-msg` (docs check with [no-docs] override), `post-commit` (DEVLOG nudge).
- Archived the Phase 1 terminal design lock from the former `NEXT_FEATURES.md` into `docs/_ai_context/ARCHITECTURE.md` with divergence notes.
- Updated terminal boot flow: `boot.js` appends a system log and unlocks command mode; terminal input submits to `/command` and renders lines or failure messages.
- Implemented `/command` in `custodian-terminal/server.py` using a persistent `GameState` and the terminal command processor.
- Added unified entrypoint `python -m game` with `--ui`/`--sim`/`--repl` modes and updated README entrypoints.
- Fixed `custodian-terminal/server.py` to add the repo root to `sys.path` so `python -m game --ui` can import `game`.
- Renamed boot and server files to canonical `boot.js` and `server.py`.
- Aligned `/command` contract to `{raw}` request and `{ok, lines}` response across UI and servers.
- Removed reset/reboot command mutations to keep state changes inside `step_world`.
- Implemented Phase 2 assault outcomes (clean defense, damage, breach, strategic loss, command center breach) with outcome messaging.
- Tightened terminal cursor cadence and suppressed cursor during active typing.
- Added power-cycle boot audio hook (power_cycle.mp3) and wired it into boot start.
- Expanded terminal boot audio base (hum + relay + beep + alert) with policy-safe unlock and one-shot helpers.

## 2026-02-06
- Updated terminal boot flow integration so UI command submit/render path uses backend `CommandResult` payloads (`ok`, `text`, optional `lines`/`warnings`).
- Standardized world-state `/command` request handling on canonical `{command}` with temporary `{raw}` fallback.
- Added world-state failure latch (`is_failed`, `failure_reason`) on COMMAND breach threshold.
- Updated `step_world` and terminal `WAIT` behavior to emit final failure lines and halt normal progression after breach.
- Updated terminal processor lockout so only `RESET`/`REBOOT` are accepted while failed.
- Extended world-state terminal tests to cover failure trigger, failure finality, and reboot-required behavior.
- Reconciled AI context docs to current implementation state: removed stale unwired `/command` assumptions, documented live endpoint contract/command set, and aligned cross-references in docs.
- Verified no `AGENTS_ADDENDUM.md` remains in repo scope, so no addendum carryover items remain to prune.

## 2026-02-07
- Refined `WAIT` quiet-tick fallback output to include a compact secondary threat signal alongside assault-pressure state, keeping `TIME ADVANCED.` as the primary line.
- Expanded terminal processor tests to lock quiet-tick fallback behavior for non-empty, concise, contract-compliant detail lines.
- Revalidated AI context docs against current implementation of both `/command` Flask handlers and terminal processor behavior.
- Updated contract documentation to reflect active endpoint behavior, current command set semantics, and authoritative backend dispatch model.
- Updated cross-references in docs index and world-state docs so `/command` behavior descriptions match live code paths.
- Confirmed no `AGENTS_ADDENDUM.md` exists in repository scope, so no completed addendum items remain to prune or archive.

## 2026-02-22
- Updated terminal UI readability and spacing in `custodian-terminal/style.css`, including a new display header with explicit mode labeling.
- Added strategic map monitor mode in `custodian-terminal/index.html`/`terminal.js`/`sector-map.js` with auto `WAIT` cadence every 2 seconds while active.
- Removed startup shortcut banner from command-mode activation; UI shortcut line is now printed only after the operator runs `HELP`.
- Added directional topology visuals for transit links, ingress links, and core sectors in the map monitor SVG projection.

## 2026-02-23
- Added map focus controls (general/defense/logistics) to the map monitor UI and synchronized focus state with the SVG renderer.
- Extended the map monitor projection with per-sector overlays for policy levels, defense allocations, fortification, fabrication priorities, and logistics telemetry.
- Added a dev-only map viewer that keeps command input active and disables auto-`WAIT`, gated by the snapshot `dev_mode` flag.
- Repositioned the new-output indicator to avoid overlapping the map mode controls.

## 2026-02-25
- Added ambient fabrication in `core/fabrication.py` to passively produce materials and gear each tick, weighted by `SET FAB` category policy.
- Ambient fabrication now consumes real inventory inputs and is throttled by FAB power effectiveness, global power load stress, and logistics supply-chain pressure.
- Updated `STATUS FAB` to include ambient fabrication throughput telemetry (rate, power factor, supply factor).
- Added world-state tests covering ambient materials conversion, policy-biased ambient output, and supply-pressure throttling behavior.
- Implemented deterministic sector grid substrate (`12x12` per sector) in `core/state.py` with `GridCell`/`SectorGrid` state and spatial `StructureInstance` records.
- Added snapshot schema updates (`snapshot_version=3`) to serialize/restore grid occupancy, structure instances, and deterministic `next_structure_id` progression.
- Added buildable structure registry in `core/structures.py` (`WALL`, `TURRET`, `GENERATOR`) and deterministic perimeter layout helper `generate_perimeter_positions` for future fortification migration.
- Added `BUILD <TYPE> <X> <Y>` command handler with command authority gating, occupancy/bounds/material checks, and deterministic ID allocation (`S<n>`).
- Extended runtime invariants for grid-instance consistency and added `test_grid_building.py`; full world-state test suite now passes with grid layer active.
- Wired sector `FORTIFY` handling to deterministic perimeter wall auto-generation in `core/grid_fortification.py`, using `PERIMETER`-tagged wall instances while retaining numeric fort levels.
- Added safe layout mutation behavior so fortification generation never overwrites occupied non-perimeter cells and never removes manual/non-perimeter walls.
- Added `test_grid_fortification.py` for level-transition replacement, non-overwrite behavior, manual-wall preservation, and deterministic replay.
- Added `core/grid_assault.py` with deterministic perimeter-wall coverage/continuity metrics and bounded topology multiplier for assault pressure shaping.
- Integrated topology multiplier into `_incoming_damage_multiplier` so intact perimeter layouts reduce incoming pressure and weak segments increase pressure, without introducing per-tile combat state.
- Added compatibility guard so numeric fortification without perimeter wall instances remains behavior-neutral (legacy snapshots/tests).
- Added `test_grid_assault_topology.py` to validate intact mitigation, weak-segment penalty, and deterministic repeatability.
- Exposed perimeter topology telemetry in `STATUS FULL` policy output, including per-fortified-sector coverage and continuity percentages.
- Added regression coverage for topology telemetry visibility in `test_grid_fortification.py`.
- Added deterministic perimeter wall erosion helper (`erode_perimeter_walls`) and integrated it into assault structure degradation for high-pressure sectors.
- Fortification topology now degrades across repeated assaults, feeding back into coverage/continuity-based pressure shaping.
- Added regression test for high-pressure erosion behavior in `test_grid_assault_topology.py`.
- Extended topology metrics with weakest-perimeter-segment scoring and incorporated it into assault pressure shaping.
- Updated `STATUS FULL` perimeter telemetry to include `WEAK` edge integrity percentage per fortified sector.
- Added `core/drone_repairs.py` for deterministic autonomous perimeter wall restoration using repair drone stock.
- Integrated drone perimeter routing into `tick_repairs`, restoring at most one wall per tick with weakest-edge-first prioritization.
- Added `test_drone_perimeter_repairs.py` for single-tick pacing, no-stock behavior, and deterministic replay.
- Added operator-facing drone routing policy command `POLICY DRONE_REPAIR <AUTO|OFF>`.
- Extended policy status rendering to include drone routing mode and perimeter repair backlog drilldown.
- Added regression tests for policy command authority/toggling and drone policy-off behavior.
