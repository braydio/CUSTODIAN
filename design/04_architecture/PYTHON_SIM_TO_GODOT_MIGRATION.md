# Python Simulation → Godot Migration Contract

Status: active implementation authority. Updated 2026-08-08.

## Authority and lifetime

Godot is the sole live runtime authority. Python is an offline executable specification and deterministic fixture generator; the game never imports, launches, or communicates with Python. `WorldSimulationRuntime` owns the one clock, kernel, campaign session/world, latest snapshot, command ingress, and resolution boundary. `GameState` remains a compatibility phase/tick/failure façade and is advanced once per successful authoritative fixed step. Hub state persists independently and accepts campaign mutation only through a sealed `CampaignOutcome`.

## Clock and ordering

`fixed_tick` advances once per authoritative 1/60-second step. After each group of 60 fixed steps, macro systems resolve the outgoing interval, then `world_tick` increments, invariants and critical failure are evaluated, and an immutable snapshot is emitted. World tick 100 therefore corresponds to fixed tick 6000. Presentation catch-up is bounded to eight steps; excess presentation time is discarded and counted only in clock diagnostics. Headless determinism drives `SimulationKernel` directly.

Implemented macro order is strategic policy power, Python-compatible logistics, repairs, and fabrication. Relay, systemic-event, and strategic-assault slots remain deferred.

## Identity and adapter boundaries

`WorldIdentityContract` owns normalized macro IDs and explicit scene mapping. `DEFENSE` maps to `DEFENSE_GRID`; scene transit maps to `T_NORTH`/`T_SOUTH`. Unknown identities produce bounded diagnostics. Bindings consume snapshots and submit typed commands only.

Strategic power load lives in `PowerSimulationSystem`. Existing scene power remains local physical delivery. `WaveManager` remains physical spawn execution behind a typed plan bridge. `FabPipeline` remains a delivery/presentation adapter and does not advance simulation jobs.

## Python parity v2

Fixtures for seeds 1/2 and world ticks 0/1/10/100 include the scheduled command stream, normalized projection, and shared SHA-256. Covered fields: seed, world tick, materials, inventory/stocks under a limited bootstrap, policy levels and dictionaries, strategic power load, and logistics. The fixture bootstrap disables ambient fabrication because that Python algorithm is not ported.

Not parity-covered: ambient threat, RNG events, prose, topology, relays, assaults, wear, fidelity, repair/fabrication progression, and failure. Pure Godot tests cover commands, pause retention, catch-up, snapshots/restore, Command Post failure, repair/fabrication foundations, and exactly-once outcomes.

## Current status

- Live runtime authority: yes.
- Python parity coverage: policies, resources, limited-bootstrap inventory/stocks, power load, logistics.
- Pure Godot deterministic coverage: snapshots, commands, campaign lifecycle, critical failure, repair/fabrication foundations.
- Adapter-only: local power delivery, physical WaveManager spawning, FabPipeline delivery.
- Not yet ported: relays, systemic random events, full assaults, wear, fidelity, ambient fabrication, full Python repairs.

## Next Agent Slice

Port relay state first in macro order, then deterministic event weighting and strategic assault state before expanding parity. Keep one runtime owner, never launch Python from Godot, and add fields to parity only after exact algorithm matches. Acceptance requires repeated command-trace determinism, exact restore, focused cross-runtime comparison, and asserted macro order.
