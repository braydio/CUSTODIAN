# CURRENT STATE — CUSTODIAN

## Code Status
- Terminal UI boot sequence is implemented in `custodian-terminal/boot.js` with power-cycle audio and SSE fallback; command submit/render transport in `custodian-terminal/terminal.js`, and the sector map + system panel projections in `custodian-terminal/sector-map.js` using `custodian-terminal/sector_layout.js`.
- Primary terminal UI webserver is `custodian-terminal/server.py` (static asset serving, SSE boot stream via `/stream/boot`, plus `/command` and `/snapshot`).
- World-state server module `game/simulations/world_state/server.py` also exposes `/command`, `/snapshot` (plus `/stream`).
- World-state simulation spine is implemented with procedural events, spatial ingress assault approaches, and COMMAND/ARCHIVE failure latches.
- Session determinism and endpoint robustness were hardened: `GameState` now supports seeded RNG (`seed`, `rng`), world random calls route through `state.rng`, `/command` supports idempotency via `command_id` replay cache, and both servers share command payload parsing/response serialization via `server_contracts.py`.
- Hub scaffolding exists in `game/simulations/world_state/core/hub.py` with offer generation, recon refinement, hub mutation rules, and snapshot/load seams.
- Phase 1.5 asymmetry is active: sector roles influence threat growth, assault damage, warnings, and event frequency.
- World-state terminal stack is wired end-to-end (`parser.py`, `commands/`, `processor.py`, `result.py`, `repl.py`).
- Runtime invariants are centralized in `core/invariants.py` and validated in both tick progression (`step_world`) and command mutation (`process_command`).
- Structure-level damage scaffolding exists (`core/structures.py`) with timed repairs (`core/repairs.py`), driven by `REPAIR`, `WAIT`, and the materials economy (status-aware repair reissue).
- Power-performance integration is active via `core/power.py`: structure output now follows `effective_output = power_efficiency * integrity_modifier`, COMMS fidelity maps from sensor effectiveness thresholds, and tactical defense output scales with DEFENSE GRID effective output.
- COMMS fidelity is now persisted on state (`state.fidelity`) and refreshed each world tick from COMMS sensor effectiveness; fidelity transitions emit explicit event lines during `WAIT`.
- Repair progression is now power-aware: speed scales by mechanic-drone output (`FB_TOOLS`) and sector power tier, assault outcome damage regresses in-progress repairs in affected sectors, and destroyed structures cancel active repairs with a 50% materials refund.
- Canonical sector layout now includes 9 sectors with FABRICATION present but inert.
- Embodied Presence Phase A is implemented: command/field player modes, transit graph movement (`DEPLOY`, `MOVE`, `RETURN`), and field-local STATUS projection.
- Defense Control Layer is implemented: command-authored doctrine (`CONFIG DOCTRINE`), normalized defense allocation bias (`ALLOCATE DEFENSE`), computed readiness index, and deterministic assault influence on target weighting, tactical output, and post-assault degradation/regression.
- Colony-sim expansion is active: surveillance now affects warning/event detection and comms fidelity buffering, assaults now resolve as multi-tick tactical phases (5-12 ticks), and fabrication now supports operator queue management (`FAB ADD/QUEUE/CANCEL/PRIORITY`) plus tiered resource recipes and stockpile outputs.
- Assault signaling now accounts for field blindness: when an assault begins while deployed, warning visibility is delayed by a short deterministic tick window before surfacing in `WAIT`.
- Assault spawning now uses ingress-route approaches (`INGRESS_N`/`INGRESS_S`) over `WORLD_GRAPH` edges (2 ticks per edge), with tutorial cap control and derived ETA projection.
- Internal assault introspection ledger is now active (`core/assault_ledger.py`) and records per-tick assault decisions, structure-loss records, and failure-chain markers for deterministic replay/debug analysis.
- Developer trace mode now doubles as assault instrumentation toggle (`state.assault_trace_enabled`), with `DEBUG REPORT` exposing recent structured ledger rows and target-weight snapshots.
- Brownout events now emit trace-time ledger records with explicit sector power deltas when assault trace instrumentation is enabled.
- Assault resolution now emits a compact player-facing after-action loss summary when structures are destroyed during the engagement.
- Assault target selection now uses explicit weighted scoring (static sector priority + dynamic damage/alertness + transit-lane pressure modifiers), while preserving `FOCUS`/`HARDEN` posture effects.
- Structure-destruction side effects are now explicit via `core/structure_effects.py`, with pending-loss tracking and first-detection reporting through `WAIT` fidelity filtering.
- Severe non-command assault outcomes can now resolve through an autonomy defensive-margin override, producing a non-failure perimeter-hold outcome when defensive capacity is sufficient.
- Presence/task flow has been modularized: movement start/tick logic is in `core/presence.py`, command authority policy is centralized in `terminal/authority.py`, and task typing/serialization helpers are in `core/tasks.py`.
- Repair authority is mode-aware: command mode supports remote DAMAGED repairs only, while field mode supports local DAMAGED/OFFLINE/DESTROYED repairs.
- Unified entrypoint is available at `python -m game` with `--ui` (default), `--sim`, and `--repl`.
- Dev tooling mode is now available in CLI entrypoints via `python -m game --dev --seed <N>` for deterministic reproduction and gated `DEBUG` commands in terminal processing.
- Debug command set (dev mode only): `DEBUG ASSAULT`, `DEBUG TICK <N>`, `DEBUG TIMER <VALUE>`, `DEBUG POWER <SECTOR> <FLOAT>`, `DEBUG DAMAGE <SECTOR> <FLOAT>`, `DEBUG TRACE`/`DEBUG ASSAULT_TRACE`, `DEBUG REPORT`/`DEBUG ASSAULT_REPORT`.
- Snapshot schema versioning is introduced (`snapshot_version=2`) with migration scaffolding in `core/snapshot_migration.py`.
- Automated tests exist for parser/processor behavior and simulation stepping.
- Git hooks for docs/secret hygiene exist; enable via `git config core.hooksPath .githooks`.

## Terminal Command Surface (Implemented)
- Accepted operator commands in normal operation: `STATUS`, `WAIT`, `WAIT NX`, `WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>`, `DEPLOY`, `MOVE`, `RETURN`, `FOCUS`, `HARDEN`, `REPAIR`, `SCAVENGE`, `SET <POLICY> <0-4>`, `SET FAB <CAT> <0-4>`, `FORTIFY <SECTOR> <0-4>`, `CONFIG DOCTRINE <NAME>`, `ALLOCATE DEFENSE <SECTOR|GROUP> <PERCENT>`, `FAB ADD <ITEM>`, `FAB QUEUE`, `FAB CANCEL <ID>`, `FAB PRIORITY <CATEGORY>`, tactical assault commands (`REROUTE POWER`, `BOOST DEFENSE`, `DEPLOY DRONE`, `LOCKDOWN`, `PRIORITIZE REPAIR`), `HELP`.
- Failure-recovery commands: `RESET`, `REBOOT`.
- Unknown or invalid command input returns:
  - `ok=false`
  - `lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]`

## `/command` Contract (Implemented)
- Request: `POST /command` with JSON key `{ "raw": "<string>" }`.
- Input validation differs by endpoint today:
  - `game/simulations/world_state/server.py` explicitly maps missing/empty/non-string input to the unknown-command payload.
  - `custodian-terminal/server.py` forwards `raw` directly to `process_command`.
- Success and failure payload shape is:
  - `ok` (bool)
  - `lines` (string[]; primary line first)
- Runtime model: Flask server process keeps a persistent in-memory `GameState` across requests.
- World-state server `/command` accepts `{ "command": "<string>" }` with legacy `{ "raw": "<string>" }` fallback and returns `{ok, text, lines}`.

## Locked Decisions
- Terminal-first interface with terse, operational output.
- World time advances only on explicit time-bearing commands (`WAIT`, `WAIT NX`) in terminal mode.
- `STATUS` remains a high-level board view (time, threat bucket, assault state, posture, archive losses, sector statuses).
- Command-mode `STATUS` now includes approach ETA lines while assaults are inbound (`THREAT: <TARGET> ETA~<N>` at FULL fidelity, generalized at degraded fidelity).
- While in field mode, `STATUS` is local-only (location, active task, local structures) and withholds global threat/assault telemetry.
- `STATUS` output degrades with COMMS fidelity (FULL/ALERT/DAMAGED/COMPROMISED).
- `WAIT`/`WAIT NX` now advances in 1-tick units (`WAIT` = 1 tick, `WAIT NX` = `N x 1` tick), applies a 0.5-second pause between internal ticks, and suppresses adjacent duplicate detail lines.
- `WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>` is implemented with a bounded safety cap for operator batching.
- `SCAVENGE NX` is implemented for batch material runs.
- `REPAIR <ID> FULL` is implemented: consumes additional materials to force post-repair sector stabilization to stable thresholds, then applies a recovery window.
- Infrastructure Policy Layer is implemented: global policy sliders (`REPAIR`, `DEFENSE`, `SURVEILLANCE`), fabrication allocation policy, per-sector fortification levels, and policy-aware STATUS rendering.
- Policy command surface is implemented: `SET <REPAIR|DEFENSE|SURVEILLANCE> <0-4>`, `SET FAB <DEFENSE|DRONES|REPAIRS|ARCHIVE> <0-4>`, `FORTIFY <SECTOR> <0-4>`.
- Fabrication queue scaffolding is live in tick loop with allocation-scaled throughput (`core/fabrication.py`), plus policy-driven power load and passive wear integration (`core/power_load.py`, `core/wear.py`).
- COMMAND breach now uses a short recovery window (`COMMAND_BREACH_RECOVERY_TICKS`) before terminal failure, allowing emergency repair response.
- Ambient threat now has a maintenance-recovery path: when COMMAND/COMMS/POWER remain healthy and assaults are idle, threat can decline instead of only rising.
- Sector recovery is now repair-triggered only: sector damage/alertness recovery windows start on `REPAIR COMPLETE`, with speed tiers `LOCAL > DRONE_FOCUS > REMOTE`.
- Structure-loss detection in `WAIT` is fidelity-gated and first-detection only: FULL shows structure ID, DEGRADED shows sector-level loss, FRAGMENTED shows generic loss signal, LOST withholds structure-loss identity.
- Command processor is backend-authoritative; frontend local echo is display-only.

## Flexible Areas
- Exact phrasing of non-contract detail lines (`[EVENT]`, `[WARNING]`, assault begin/end markers).
- Timing and pressure tuning in `core/config.py` and event weights/cooldowns in `events.py`.

## In Progress
- None.
