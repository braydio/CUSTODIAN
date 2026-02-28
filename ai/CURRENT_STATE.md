# CURRENT STATE — CUSTODIAN

## Runtime Status

- Terminal UI is active in `custodian-terminal/` with boot stream, command transport, and snapshot-driven side panels.
- Terminal UI now includes a strategic map monitor mode with 2-second auto-`WAIT` cadence while active.
- Map monitor view supports focus modes (general/defense/logistics) with per-sector policy/defense/logistics overlays.
- Dev-only map viewer is available when `dev_mode` is enabled, keeping command input active and auto-`WAIT` disabled.
- Startup command activation no longer prints UI shortcut text; shortcut line is emitted only after `HELP`.
- Backend-authoritative world-state simulation is active in `game/simulations/world_state/`.
- Unified CLI entrypoint is active via `python -m game` (`--ui`, `--repl`, `--sim`, `--dev`, `--seed`).
- Deterministic seeding and command idempotency are implemented (`GameState(seed=...)`, `/command` `command_id` replay cache).
- Deterministic procedural terminal messaging is active for `WAIT` signals (seeded grammar variants with fidelity-aware symbol banks).
- Procgen infrastructure scaffolding is active for Phase 0.5 (`game/procgen/signals.py`, `game/procgen/projection.py`) with deterministic projection tests in place.
- WAIT text rendering can now route through the Phase 0.5 projection layer via `GameState.procgen_projection_enabled` (default disabled for behavior-safe migration).
- Deterministic sector grid substrate is active (fixed `12x12` per sector) with snapshot-compatible serialization.
- World-state tests are passing (`game/simulations/world_state/tests`).

## Implemented World Features

- 9-sector base state (including FABRICATION sector).
- Grid-based structure placement substrate with deterministic instance IDs (`S<n>`) is implemented.
- Spatial structure registry is active for buildable types (`WALL`, `TURRET`, `GENERATOR`).
- Sector fortification now auto-generates deterministic perimeter-wall layouts (`PERIMETER` subtype) while retaining numeric fort levels for compatibility.
- Assault incoming-pressure math now reads spatial perimeter topology (coverage + continuity) when perimeter walls exist, creating deterministic weak-segment effects.
- `STATUS FULL` now reports perimeter topology telemetry (coverage/continuity percentages) for fortified sectors.
- Assault structure-degradation flow now includes deterministic perimeter-wall erosion under high incoming pressure.
- Perimeter-topology model now includes weakest-edge scoring (`WEAK`) used in assault pressure shaping and exposed in `STATUS FULL`.
- Repair drone stock now routes deterministic autonomous perimeter-wall restoration (weakest-edge-first, max one wall restored per tick).
- Operator policy control exists for autonomous drone routing (`POLICY DRONE_REPAIR <AUTO|OFF>`), surfaced in status as mode + backlog.
- Structure-level damage/state model with repair jobs and reconstruction gating.
- Power-performance coupling for defense output, repair speed, and comms fidelity.
- Comms fidelity levels (`FULL`, `DEGRADED`, `FRAGMENTED`, `LOST`) with fidelity-gated `WAIT`/`STATUS` output.
- Canonical per-tick event records (`tick_events`) now back `WAIT` event surfacing; semantic signal-key suppression prevents repeated message spam even when variant phrasing rotates.
- Presence split (`COMMAND` vs `FIELD`) with transit graph travel (`DEPLOY`, `MOVE`, `RETURN`).
- Command-authority gating while deployed (strategic verbs blocked outside command authority).
- Defense policy layer (`SET`, `SET FAB`, `FORTIFY`) and doctrine/allocation controls (`CONFIG DOCTRINE`, `ALLOCATE DEFENSE`).
- Transit fortification policy extension for interception lanes (`FORTIFY T_NORTH|T_SOUTH <0-4>`) with deterministic threat-multiplier reduction during transit interception.
- Policy QoL controls (`POLICY SHOW`, `POLICY PRESET <...>`).
- Fabrication queue with recipes, queue ops, and stock outputs (`repair_drones`, `turret_ammo`).
- Ambient fabrication loop that passively fabricates materials/gear from policy allocation (`SET FAB`) and scales output from available inputs, power posture, and logistics pressure.
- Logistics throughput caps tied to active system load (`core/logistics.py`) with deterministic slowdown multipliers for repair/fabrication under overload.
- Assault system with spatial approach traversal, transit interception, multi-tick tactical resolution, and after-action effects.
- ARRN relay scaffolding with command/field flow (`SCAN RELAYS`, `STABILIZE RELAY`, `SYNC`) and knowledge-index progression.
- Dev-mode debug command path (`DEBUG ...`) gated behind `--dev`.

## Terminal Command Surface

Normal operation includes:

- `STATUS`, `STATUS FULL`, `STATUS <FAB|POSTURE|ASSAULT|POLICY|SYSTEMS|RELAY>`
- `WAIT`, `WAIT NX`, `WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>`
- `DEPLOY`, `MOVE`, `RETURN`
- `FOCUS`, `HARDEN`, `REPAIR`, `REPAIR <ID> FULL`, `SCAVENGE`, `SCAVENGE NX`
- `BUILD <TYPE> <X> <Y>`
- `SET`, `SET FAB`, `FORTIFY`, `CONFIG DOCTRINE`, `ALLOCATE DEFENSE`
- `FORTIFY <SECTOR> <0-4>` now also mutates spatial perimeter wall layout for the targeted sector.
- `POLICY SHOW`, `POLICY PRESET <BALANCED|SIEGE|RECOVERY|LOW_POWER>`
- `POLICY DRONE_REPAIR <AUTO|OFF>`
- `FAB ADD`, `FAB QUEUE`, `FAB CANCEL`, `FAB PRIORITY`
- `SCAN RELAYS`, `STABILIZE RELAY <ID>`, `SYNC`
- `REROUTE POWER`, `BOOST DEFENSE`, `DRONE DEPLOY`, `DEPLOY DRONE`, `LOCKDOWN`, `PRIORITIZE REPAIR`
- `HELP` and `HELP <TOPIC>` (category tree)
- `TUTORIAL` and `TUTORIAL <TOPIC>` (detailed operator guide)
- `TUTORIAL QUICKSTART` (staged live guide through first assault)
- Recovery: `RESET`, `REBOOT`

Dev mode only:

- `DEBUG HELP`, `DEBUG ASSAULT`, `DEBUG TICK <N>`, `DEBUG TIMER <VALUE>`, `DEBUG POWER <SECTOR> <VALUE>`, `DEBUG DAMAGE <SECTOR> <VALUE>`, `DEBUG TRACE`, `DEBUG REPORT`

## Locked Behavior Notes

- Backend owns authoritative state mutation; frontend echo is presentation-only.
- Time progression occurs only through explicit time-bearing commands.
- `WAIT` unit behavior:
  - default: 5 ticks per unit (`WAIT`, `WAIT NX`)
  - during active assault: 1 tick per unit for higher-fidelity tactical pacing
  - line wording is procedurally varied but deterministic under `seed`/`text_seed`; fidelity boundaries remain enforced
- Unknown command contract remains fixed through processor + serializer:
  - `ok=false`
  - `text="UNKNOWN COMMAND."`
  - `lines=["UNKNOWN COMMAND.", "TYPE HELP FOR AVAILABLE COMMANDS."]`
- Terminal parser accepts optional leading `/` on commands (example: `/TUTORIAL CORE`).
- Tutorial topics include tagged message formatting, examples, and UI-focused guidance.
- Tutorial quickstart runs a live, staged prompt sequence and returns control after first assault.
- Failure mode locks command surface until `RESET`/`REBOOT`.

## Known Documentation Boundaries

- `design/*` is the canonical design architecture.
- `ai/*` is the projection layer for AI session context.
