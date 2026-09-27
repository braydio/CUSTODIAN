# Python Simulation → Godot Migration Contract

Status: active implementation authority. Updated 2026-08-08.

## Authority and lifetime

Godot is the sole live runtime authority. Python is an offline executable specification and deterministic fixture generator; the game never imports, launches, or communicates with Python. `WorldSimulationRuntime` owns the one clock, kernel, campaign session/world, latest snapshot, command ingress, and resolution boundary. `GameState` remains a compatibility phase/tick/failure façade and is advanced once per successful authoritative fixed step. Hub state persists independently and accepts campaign mutation only through a sealed `CampaignOutcome`.

## Clock and ordering

`fixed_tick` advances once per authoritative 1/60-second step. After each group of 60 fixed steps, macro systems resolve the outgoing interval, then `world_tick` increments, invariants and critical failure are evaluated, and an immutable snapshot is emitted. World tick 100 therefore corresponds to fixed tick 6000. Presentation catch-up is bounded to eight steps; excess presentation time is discarded and counted only in clock diagnostics. Headless determinism drives `SimulationKernel` directly.

Implemented macro order is strategic policy power, Python-compatible logistics, repairs, fabrication, relay progression, systemic events, strategic assault, world-tick increment, invariants, and critical-failure evaluation. The seven system slots are asserted by `world_simulation_macro_state_smoke.gd`.

## Identity and adapter boundaries

`WorldIdentityContract` owns normalized macro IDs and explicit scene mapping. `DEFENSE` maps to `DEFENSE_GRID`; scene transit maps to `T_NORTH`/`T_SOUTH`. Unknown identities produce bounded diagnostics. Bindings consume snapshots and submit typed commands only.

Strategic power load lives in `PowerSimulationSystem`. Existing scene power remains local physical delivery. `WaveManager` remains physical spawn execution behind a typed plan bridge. `FabPipeline` remains a delivery/presentation adapter and does not advance simulation jobs.

## Python parity v3

Fixtures for seeds 1/2 and world ticks 0/1/10/100 include the scheduled command stream, normalized projection, and shared SHA-256 (parity schema v3). Covered fields include the prior resource/policy/power/logistics surface plus relay IDs, sectors, statuses, stability and packet counts; relay knowledge; event assault/hostile context counters; and inactive strategic assault state. The fixture bootstrap disables ambient fabrication because that Python algorithm is not ported. Event-key/category selection and active strategic approaches intentionally use the Godot serialized RNG and are validated by Godot same-seed trace/restore tests rather than treated as Python authorities.

Not parity-covered: ambient threat, selected event key/category sequence, active strategic approaches, prose, topology, wear, fidelity, repair/fabrication progression, and failure. Pure Godot tests cover commands, pause retention, catch-up, snapshots/restore, Command Post failure, repair/fabrication foundations, and exactly-once outcomes.

## Current status

- Live runtime authority: yes.
- Python parity coverage: policies, resources, limited-bootstrap inventory/stocks, power load, logistics, retained relay/event context, and inactive strategic assault state.
- Pure Godot deterministic coverage: snapshots, commands, campaign lifecycle, critical failure, repair/fabrication foundations, relay/event/assault evolution and restore.
- Adapter-only: local power delivery, physical WaveManager spawning, FabPipeline delivery.
- Implemented in REMAP-1: macro relay state/progression, deterministic systemic-event context/selection, and strategic assault approach/handoff. Loaded combat remains physical through WaveManager.
- Not yet ported: wear, fidelity, ambient fabrication, full Python repairs, and campaign disk persistence.

## Next Agent Slice

REMAP-1 is complete. Continue with REMAP-2 under the tracker; keep one runtime owner and never launch Python from Godot. Extend parity only for retained semantics that match exactly.
