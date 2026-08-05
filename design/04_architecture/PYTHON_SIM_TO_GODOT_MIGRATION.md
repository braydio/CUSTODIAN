# Python Simulation → Godot Migration Contract

Status: active implementation authority for the simulation extraction slices.

## Authority and lifetime

Godot is the only runtime authority. Python is a deterministic executable specification and golden-master source; it is never launched by the game and is not a second simulation. `HubState` persists across campaigns, `CampaignSession` and `WorldSimulationState` are disposable run data, and `CampaignOutcome` is the only campaign-to-Hub mutation packet. The existing `GameState` autoload remains a compatibility phase/failure façade during migration.

Pure state lives under `custodian/game/state/`. Deterministic systems live under `custodian/game/systems/`. Scene bindings are projections of snapshots and events; they do not own simulation truth. Input becomes typed commands queued into the kernel.

### Path normalization

Older architecture prose may show `custodian/core/systems/...`. That is a retired proposal path, not a directory to recreate. New state belongs under `custodian/game/state/`, simulation systems under `custodian/game/systems/simulation/` (or an existing `game/systems/<domain>/` owner), and scene adapters under `custodian/game/world/bindings/`. Existing runtime files retain their actual `custodian/game/systems/core/systems/` paths until an independently scoped extraction moves them.

## Clock and ordering

The authoritative clock remains 60 Hz with `1/60` fixed delta. A macro tick is every 60 simulation ticks. Each fixed step drains commands in sequence order, runs fixed systems, advances the tick, and emits a snapshot. Macro systems then run in this order:

1. relays
2. power/load aggregation
3. logistics
4. systemic events
5. assault progression/resolution
6. repairs
7. fabrication
8. wear
9. fidelity
10. invariant validation
11. failure evaluation

The first scaffold implements the fixed-step clock, power calculation, logistics calculation, command/event types, snapshots, and invariant validation. Later slices add the remaining ordered systems without changing this contract.

## Compatibility boundaries

`WaveManager` consumes an `AssaultSpawnPlan` and reports physical outcomes; it does not decide strategic threat. Existing power, fabrication, sector, and structure nodes may remain adapters while their authoritative values move into state. Direct scene mutation is permitted only as a temporary preview fallback and must not be used by production command paths.

F10/save/export scans and rendering are outside the simulation step. A tactical pause stops simulation steps but may continue presentation and command queuing. Commands queued while paused do not mutate state until resumed.

## Python parity

Parity fixtures contain structured snapshots, not prose: seed, tick, threat, sectors, structures, power/load, logistics, policies, inventories, queues, assault, failure, and fingerprint. A same-seed command stream must produce the same Godot snapshot fingerprint across repeated runs. The fixture exporter and broader subsystem ports are subsequent slices; no Python runtime dependency is introduced.

## First vertical-slice acceptance

The first playable target is “Command Post Under Pressure”: deterministic seed, ambient threat, power/load, logistics pressure, policies, repair/fabrication queues, assault plan bridge, structure damage, Command Post failure, stabilization, and snapshot save/reload. Existing art and scene systems are reused. No new art is required.

## Next Agent Slice

Goal: add the Python fixture exporter and parity comparison harness, then port relay/event/assault state without wiring scene authority.

Files: `python-sim/tools/export_godot_parity_fixtures.py`, `custodian/tools/validation/fixtures/world_simulation/`, `custodian/tools/validation/world_simulation_kernel_smoke.gd`, and the next pure systems under `custodian/game/systems/simulation/`.

Constraints: preserve the fixed-step order, do not launch Python from Godot, do not expand `GameState`, and do not mutate Hub state from a transient campaign world.
