# Python Simulation Macro World-State Completion

- Status: `complete`
- Goal: Complete the next coherent Python→Godot simulation remap boundary by adding authoritative relay state, deterministic systemic-event state/selection, and strategic assault state to `WorldSimulationRuntime`.

- Current measured state:
  - `SimulationKernel` resolves macro systems in this order:
    `power → logistics → repairs → fabrication → relay → systemic events → strategic assault → world_tick/invariants/failure`.
  - Python parity v3 covers policies, resources, limited-bootstrap inventory/stocks, strategic power load/logistics, representative relay state, systemic-event context, and inactive strategic-assault state.
  - Relay state, deterministic systemic events, and strategic assault approach/handoff are implemented.
  - Snapshot/restore and exactly-once campaign outcome foundations already exist.
  - Loaded assaults are already physical Godot gameplay and must remain so.

- Task-specific authority:
  - `design/04_architecture/PYTHON_SIM_TO_GODOT_MIGRATION.md`
  - `design/02_features/assault/ASSAULT_DESIGN_GODOT.md`
  - `design/04_architecture/PYTHON_SIM_REMAP_TRACKER.md`
  - Historical parity/archeology input only:
    - `python-sim/game/simulations/world_state/core/relays.py`
    - `python-sim/game/simulations/world_state/core/events.py`
    - `python-sim/game/simulations/world_state/core/event_records.py`
    - `python-sim/game/simulations/world_state/core/assaults.py`
    - `python-sim/game/simulations/world_state/core/assault_instance.py`
    - `python-sim/game/simulations/world_state/core/assault_ledger.py`

- Change:
  1. Extend authoritative world state and snapshot serialization with the minimum retained relay/event/strategic-assault state.
  2. Add one Godot-native macro system for each retained responsibility or the smallest cleaner decomposition discovered from the live graph.
  3. Insert them into the existing macro boundary in this order:

     `power → logistics → repairs → fabrication → relay → systemic events → strategic assault`

  4. Port relay state/progression needed by active simulation:
     - relay identity/status/stability;
     - deterministic decay;
     - packet/sync state;
     - retained knowledge/progression modifiers;
     - interactions required by later retained macro systems.
  5. Port deterministic systemic-event behavior:
     - event context counters/state;
     - category weighting;
     - seeded selection;
     - recent-event suppression;
     - retained state-changing consequences.
     Do not port terminal prose as simulation authority.
  6. Port strategic assault state sufficient for:
     - approach/pending state;
     - deterministic target/pressure selection;
     - timing/ETA or equivalent current macro representation;
     - warning/handoff state;
     - persistent strategic outcome bookkeeping.
  7. Connect strategic assault state to the existing physical assault boundary without allowing it to resolve loaded combat abstractly.
  8. Expand snapshot/restore, invariants, and parity projection only for behavior intentionally retained.
  9. Add focused fixtures/tests proving deterministic repeated traces and restore equivalence.

- Preserve:
  - `WorldSimulationRuntime` as sole live campaign-world simulation owner.
  - Physical `WaveManager`/Enemy/turret/infrastructure combat as authority for loaded assaults.
  - Current ARRN/player-facing relay runtime ownership; macro relay state may integrate through an adapter but must not silently replace it.
  - Existing command, snapshot, exactly-once outcome, repair/fabrication, power, and logistics behavior.
  - Seeded determinism and stable macro ordering.

- Non-goals:
  - wear;
  - full fidelity migration;
  - full Python repair semantics;
  - ambient fabrication;
  - campaign disk save/load;
  - terminal command/prose behavior;
  - Python tactical autopilot;
  - redesigning physical assault combat;
  - rewriting current ARRN gameplay;
  - porting every field/function merely because it exists in `python-sim/`.

- Acceptance:
  1. Macro order is explicitly tested as:
     `power → logistics → repairs → fabrication → relay → systemic events → strategic assault`.
  2. Relay evolution is deterministic for repeated identical seed/command traces.
  3. Event selection/state evolution is deterministic and uses the authoritative simulation RNG/state rather than presentation randomness.
  4. Strategic assault approach/target/state evolution is deterministic.
  5. A snapshot taken with live relay/event/assault state restores exactly and produces the same subsequent trace as an uninterrupted run.
  6. Cross-runtime comparison covers the retained relay/event/strategic fields and algorithms chosen for parity, with differences explicitly documented where active design intentionally supersedes Python behavior.
  7. A loaded assault still resolves through physical Godot actors/systems; no Python-style tactical autopilot or abstract damage outcome decides it.
  8. Existing simulation migration smokes remain green.
  9. `design/04_architecture/PYTHON_SIM_REMAP_TRACKER.md` marks REMAP-1 complete only after all three domains satisfy acceptance.

- Task overrides: `none`

- Deferred:
  - REMAP-2: wear, fidelity, full repair semantics, ambient fabrication.
  - REMAP-3: campaign/save-file persistence.
  - REMAP-4: final parity expansion and migration closeout.

## Work Surface

Likely active files, subject to graph inspection:

- `custodian/game/systems/simulation/simulation_kernel.gd`
- `custodian/game/systems/simulation/world_simulation_runtime.gd`
- `custodian/game/state/world/world_simulation_state.gd`
- `custodian/game/state/world/simulation_snapshot.gd`
- `custodian/game/systems/simulation/simulation_parity_contract.gd`
- `custodian/game/systems/simulation/simulation_invariants.gd`
- new focused macro simulation systems under
  `custodian/game/systems/simulation/`
- existing Python fixture/projection generator used by the migration suite
- focused validation under `custodian/tools/validation/`

Inspect the graph before deciding exact new filenames or adapter boundaries.

## Plan

1. Map retained Python relay/event/assault state onto current Godot state and classify each historical behavior `PORT`, `SUPERSEDED`, or `RETIRED`.
2. Implement relay state and prove deterministic snapshot/restore.
3. Add deterministic systemic-event weighting/state on top of relay output.
4. Add strategic assault approach/state and physical-runtime handoff without abstract loaded-combat resolution.
5. Extend parity projection/fixtures for only the retained behavior.
6. Run focused checks during implementation, then the existing world-simulation migration suite once at closeout.
7. Update the remap tracker and active state docs if the implementation changes their owned truth.

## Handoff

- Next action: inspect the live graph around `SimulationKernel`,
  `WorldSimulationState`, snapshot/parity serialization, ARRN relay consumers,
  and `WaveManager` assault handoff, then begin relay state.
- Best starting files:
  - `design/04_architecture/PYTHON_SIM_TO_GODOT_MIGRATION.md`
  - `custodian/game/systems/simulation/simulation_kernel.gd`
  - `custodian/game/state/world/world_simulation_state.gd`
  - `design/02_features/assault/ASSAULT_DESIGN_GODOT.md`
- Blockers or open questions:
  - None.

## Completion notes

- Implemented: three Godot macro systems, one serialized deterministic RNG stream, relay progression commands, schema-v3 snapshot migration from v2, macro invariants, parity-v3 projection/fixtures, and typed WaveManager handoff plus physical completion observation.
- Historical classification: PORT relay progression/event context and selection/strategic approaches; SUPERSEDED Python parallel-sector damage/power consequences and target/intercept details; RETIRED prose, detection presentation, tactical autopilot and abstract combat/economy outcomes; no unresolved design decisions.
- Validation: `world_simulation_kernel_smoke.gd`, `world_simulation_macro_state_smoke.gd`, `world_simulation_python_parity_smoke.gd`, `world_simulation_snapshot_roundtrip_smoke.gd`, fixture validator, and the one-shot migration suite passed. Loaded combat remains WaveManager/actor-owned; the negative control rejects physical-result fields in macro assault state/plans.
- Deferred: REMAP-2 wear/fidelity/full repairs/ambient fabrication; REMAP-3 disk persistence; REMAP-4 final migration closeout.
