# PYTHON SIMULATION TO GODOT RUNTIME INTEGRATION

- Status: `complete`
- Baseline commit: `dd5f389fc8d95e8922233cdb6c7759dcf0164e2b`
- Authority: `custodian/AGENTS.md`, active architecture documents under `design/04_architecture/`, and `custodian/docs/ai_context/CURRENT_STATE.md`
- Objective: Make the extracted Godot deterministic kernel the sole live campaign-world authority, backed by genuine offline Python projection fixtures, canonical persistence, exactly-once outcomes, focused scene adapters, and one validation suite.
- Current defects: fixed/world ticks are conflated; parity compares unrelated snapshots; policy/economic defaults drift; snapshot restore is absent; campaign resolution/application are repeatable; the live scene still owns a separate accumulator; scene identity mapping is implicit.
- Authority boundaries: Godot owns runtime state and time. Python is fixture generation only. `GameState` is compatibility-only. Hub mutation accepts immutable outcomes only. Bindings observe snapshots and queue commands.
- Exact files in scope: runtime/state files under `custodian/game/state/{world,run,persistent}/`; deterministic systems under `custodian/game/systems/simulation/`; the compatibility entrypoint, focused bindings, `game.tscn`, Python fixture exporter/contract/tests, validation scripts/fixtures, and architecture/context documentation named by the task.
- Determinism contract: 60 fixed steps per world tick; sequence-ordered deep-copied commands; macro systems resolve the outgoing interval before `world_tick` increments; canonical sorted JSON and SHA-256; headless tests drive the kernel directly.
- Python parity projection contract: schema v2 compares only seed, world tick, threat/failure where genuinely aligned, resources, inventory, stocks, policy dictionaries, strategic power load, and deterministic logistics. It excludes prose, RNG events, topology, wear/fidelity, and full assault state.
- Runtime ownership contract: one `WorldSimulationRuntime` in `game.tscn` owns one clock, kernel, campaign session/world, latest snapshot, command ingress, and resolution boundary.
- Constraints: no Python gameplay dependency; no duplicate clocks/world containers; no unrelated combat, procgen, loot, art, or presentation refactors; preserve `.gd.uid` files and unrelated worktree changes.
- Acceptance: real seeds 1/2 checkpoints 0/1/10/100 parity; exact snapshot round trip; paused command retention; bounded catch-up; exactly-once outcomes; one live runtime; architecture validation; no tracked Python caches.
- Validation commands: `bash custodian/tools/validation/run_world_simulation_migration_suite.sh` plus the focused commands listed in the task and `VALIDATION_RECIPES.md`.
- Documentation-drift checklist: migration authority, glue contract, campaign flow, Hub ownership, architecture, current/context/index/validation, and this packet must describe actual implemented/deferred status.
- Deferred systems: relay state/system; systemic random events; full strategic assault progression; wear/fidelity; ambient fabrication; complete Python repair semantics; broader physical structure damage bindings. These belong in new pure files under `game/state/world/` and `game/systems/simulation/` before parity projection expansion. `WaveManager`, local power, and `FabPipeline` remain explicit adapters.
- Completion status: feasible implementation and consolidated validation complete. The environment lacks the `pytest` module and cannot reach PyPI, so the exact `python3 -m pytest` command is dependency-blocked; the same test module passed directly through its `unittest` entrypoint and the suite records this fallback.

## Plan

1. Normalize state/time/commands/systems and canonical persistence.
2. Replace fixtures with a shared projection contract and real cross-runtime smoke.
3. Enforce campaign lifecycle and wire one live runtime with narrow adapters.
4. Run the consolidated suite, remediate drift, and record precise deferrals.

## Handoff

- Next action: port relays first in macro order, then deterministic event/assault state and expand parity only for matched algorithms.
- Best starting files: `design/04_architecture/PYTHON_SIM_TO_GODOT_MIGRATION.md`, `game/systems/simulation/simulation_kernel.gd`, and Python relay/event sources.
- Validation run: `bash custodian/tools/validation/run_world_simulation_migration_suite.sh` passed, including byte-identical fixture regeneration, all six Godot smokes, and architecture ownership validation.
- Blockers or open questions: direct pytest unavailable (`No module named pytest`; PyPI DNS unavailable). Existing headless import reports plugin socket/editor-settings warnings; live scene reports pre-existing resource leaks.
