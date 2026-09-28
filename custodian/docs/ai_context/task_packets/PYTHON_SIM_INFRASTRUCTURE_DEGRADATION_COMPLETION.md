# Python Simulation Infrastructure Degradation Completion

- Status: `ready`
- Goal: Close the REMAP-1 integration defects found in post-landing review, then complete REMAP-2 by making wear, macro fidelity, repair progression, and ambient fabrication authoritative Godot simulation behavior without reintroducing Python-era parallel runtime authority.

- Current measured state:
  - REMAP-1 is on `main` and the macro order is currently:
    `power → logistics → repairs → fabrication → relay → systemic events → strategic assault → world_tick/invariants/failure`.
  - Snapshot schema/parity are v3.
  - Relay/event/strategic-assault state is serialized and deterministic under the existing macro smoke.
  - Repair and fabrication have Godot foundations, but command ingress still accepts caller-supplied repair cost/duration and fabrication outputs/duration instead of deriving those contracts from authoritative simulation data.
  - Wear, macro fidelity, ambient fabrication, and the retained full repair semantics remain unported.
  - Post-landing review found several REMAP-1 integration defects that must be corrected in this slice before REMAP-2 is marked complete.

- Task-specific authority:
  - `design/04_architecture/PYTHON_SIM_TO_GODOT_MIGRATION.md`
  - `design/04_architecture/PYTHON_SIM_REMAP_TRACKER.md`
  - `design/02_features/assault/ASSAULT_DESIGN_GODOT.md`
  - current active repair/fabrication/power/ARRN design discovered from live `design/`
  - Historical archaeology/parity input only:
    - `python-sim/game/simulations/world_state/core/wear.py`
    - `python-sim/game/simulations/world_state/core/fidelity.py`
    - `python-sim/game/simulations/world_state/core/power.py`
    - `python-sim/game/simulations/world_state/core/repairs.py`
    - `python-sim/game/simulations/world_state/core/drone_repairs.py`
    - `python-sim/game/simulations/world_state/core/fabrication.py`
    - `python-sim/game/simulations/world_state/core/relays.py`

- Change:

  ## A. REMAP-1 review corrections

  These are acceptance work for this slice, not optional cleanup.

  ### A1. Physical assault completion must mean physical completion

  The current `WaveManagerSimulationBinding` treats `WaveManager.wave_completed` as physical assault completion. In the live `WaveManager`, that signal fires when the spawn queue is exhausted, before the spawned enemies are necessarily dead.

  Replace this with a plan-specific physical lifecycle contract:

  - a strategic external plan must have a stable plan ID;
  - `WaveManager` must retain plan ownership for the actors spawned by that plan;
  - completion for strategic bookkeeping must be emitted only when that plan has no pending spawns and no still-live plan-owned actors;
  - ambient/unrelated enemies must not block or falsely satisfy that plan's completion;
  - `PHYSICAL_ASSAULT_COMPLETED` must be queued only from this plan-specific completion observation;
  - do not reinterpret the existing generic `wave_completed` signal if other production behavior relies on its current spawn-cycle meaning.

  ### A2. Remove re-entrant direct simulation mutation from the binding

  The physical binding currently calls `WorldSimulationRuntime.acknowledge_assault_handoff()`, which mutates authoritative simulation state directly from the scene adapter and can occur synchronously while the kernel is emitting the handoff signal.

  Replace this with typed command ingress.

  Add the narrowest command/state transition required for handoff acceptance, for example an `ASSAULT_HANDOFF_ACCEPTED` command carrying the plan ID. The binding may submit commands/observations; it must not directly mutate `kernel.state`.

  ### A3. Make HANDOFF_READY retryable and restore-safe

  A rejected external plan currently leaves the macro assault in `HANDOFF_READY`, but the one-shot transition signal is not emitted again. A snapshot restored while already `HANDOFF_READY` has the same problem.

  Ensure:

  - a temporarily busy/unavailable `WaveManager` does not strand the assault;
  - the same plan can be offered again until accepted;
  - accepted plans remain exactly-once and are not double-started;
  - restoring a `HANDOFF_READY` snapshot re-exposes the pending plan;
  - restore/continuation tests cover both rejected-then-retried and restored-pending handoff.

  ### A4. Preserve the selected strategic target across the physical handoff

  `StrategicAssaultSimulationSystem` currently chooses a macro target but emits every physical plan with `objective = "breach_command"`.

  Do not silently discard the selected target.

  Use the active physical objective contract to implement one explicit strategy:

  - map supported macro targets deterministically to current physical objectives; or
  - constrain strategic target selection to targets the physical runtime can currently represent.

  At minimum, `COMMAND`, `POWER`, and `DEFENSE_GRID` must not collapse to the same physical intent when their current physical equivalents exist. Unsupported targets require an explicit documented fallback, not an accidental one.

  Add a regression proving the macro target and resulting physical objective remain semantically aligned.

  ### A5. Repair systemic-event assault recency

  `systemic_event_state.ticks_since_assault` currently only increments. It is not reset from live strategic/physical assault state, so the retained recent-assault event weighting stops representing actual assault recency.

  Restore a deterministic assault-recency contract:

  - active approach/handoff/physical assault state yields zero or the explicit current equivalent;
  - after true physical completion the counter advances from the completion boundary;
  - snapshot/restore preserves the same future weighting;
  - test the under-five-ticks category multiplier around an actual assault lifecycle.

  ### A6. Fix relay dormancy pressure at knowledge tier 7

  Historical retained semantics halve dormancy pressure at the top knowledge tier using:

  `ceil(dormant_count / 2)`

  The current Godot implementation uses `dormant_count - 1`, which diverges for several counts.

  Fix the formula and prove representative 1–4 dormant-relay cases. Recompute pressure after sync/progression changes so the benefit is not delayed until a later unrelated tick.

  ### A7. Resolve the systemic-event power signal

  The current infrastructure-event multiplier reads average `SectorSimulationState.power`, while the authoritative `PowerSimulationSystem` currently updates strategic `power_load` and does not maintain those sector power values.

  Do not leave an effectively dead weighting branch.

  Inspect current power ownership and choose one authoritative contract:
  - derive the event modifier from the existing macro power state; or
  - explicitly establish authoritative sector power if current design requires it.

  Do not make presentation/local physical power the macro authority by accident.

  ### A8. Remove duplicate relay command match arms

  `SimulationKernel._apply_command()` currently contains duplicated `STABILIZE_RELAY` and `SYNC_RELAYS` match cases. Remove the duplicate arms and add/retain focused command coverage.

  ### A9. Reconcile retained relay knowledge benefits with REMAP-2 systems

  The historical relay knowledge ladder included cross-system effects for repair, fidelity, fabrication, logistics, and threat forecasting. REMAP-1 ported knowledge progression but not those effects.

  For each historical benefit, classify `PORT`, `SUPERSEDED`, or `RETIRED` against current design.

  REMAP-2 must explicitly resolve the benefits that directly touch its systems:
  - remote repair discount;
  - fidelity reconstruction/floor behavior;
  - fabrication blueprint/progression behavior.

  Also inspect logistics optimization and threat-forecast behavior. If retained by current design, wire them through their existing authoritative owners; otherwise document their retirement/supersession. Prefer derived behavior from `relay_knowledge_level` over a second persisted benefits dictionary unless persistent benefit state is genuinely required.

  ## B. Wear

  Add a Godot-native deterministic wear authority.

  Retain the useful macro semantics:
  - passive sector degradation;
  - defense-readiness wear-rate policy;
  - sector-fortification mitigation;
  - bounded deterministic state suitable for snapshots/parity.

  Wear is macro campaign degradation only. It must not directly damage loaded physical actors/scene nodes.

  Add an explicit macro slot after strategic assault and before fidelity unless live architecture inspection finds a stronger current ownership reason. The resulting order should be asserted.

  ## C. Macro fidelity

  Add authoritative macro communications/intelligence fidelity state without replacing presentation policy.

  Retain the useful simulation semantics:
  - deterministic `FULL / DEGRADED / FRAGMENTED / LOST` state or the exact current canonical equivalents;
  - surveillance buffering;
  - current authoritative power/integrity inputs;
  - retained interference effects;
  - retained relay reconstruction benefits where current design still wants them;
  - transition events as simulation facts, not terminal prose.

  `TerminalFidelityPolicy` remains a presentation/read-model policy. It may consume the authoritative macro fidelity result, but it must not become simulation authority.

  If historical `CM_CORE` structure assumptions no longer match the current Godot identity model, map them to the current COMMS authority rather than recreating dead structure IDs.

  ## D. Full repair semantics

  Replace caller-authored repair economics with simulation-owned rules.

  Current `QUEUE_REPAIR` accepts caller-provided `material_cost` and `ticks`. The caller must not be able to choose authoritative cost or duration.

  Move retained repair quoting/validation/progression into the repair simulation/domain authority. A repair request should identify the target and only genuinely player-selected mode/options; the simulation derives:
  - eligibility;
  - cost;
  - duration/progression;
  - policy multipliers;
  - logistics throughput effects;
  - retained power/fidelity/relay effects where current design requires them;
  - completion/result state.

  Preserve the current HP-based Godot structure model. Do not recreate the Python enum ladder line-for-line if HP/status already provides the current equivalent.

  Classify historical local/remote repair, reconstruction restrictions, sector recovery windows, cancellation/refund, and assault regression individually. Port only semantics still required by current design.

  Do not duplicate the loaded physical hold-repair interaction layer.

  Historical perimeter-drone grid rebuilding is not automatically in scope. The current Godot wall/build authority wins; classify that Python behavior rather than recreating its grid model.

  ## E. Full fabrication + ambient fabrication

  Replace caller-authored fabrication outputs with simulation-owned recipe data.

  Current `QUEUE_FABRICATION` accepts caller-provided outputs and duration. A caller must not be able to mint arbitrary authoritative resources.

  Establish or reuse one Godot-native authoritative recipe contract that owns:
  - recipe ID;
  - category;
  - inputs;
  - outputs;
  - base duration;
  - unlock requirements;
  - deterministic queue behavior.

  Explicit queued fabrication and ambient fabrication must use the same resource/output helpers rather than parallel rule paths.

  Port retained ambient behavior:
  - category allocation shares;
  - deterministic progress accumulation;
  - logistics/supply pressure effects;
  - current authoritative power effect;
  - bounded progress;
  - deterministic crafting order;
  - input consumption;
  - output application.

  Retain only current resource identities. Map historical repair-drone/turret-ammo/archive outputs to current stock/resource owners rather than creating duplicate inventories.

  Resolve the retained relay fabrication unlock/benefit as part of A9.

  ## F. Snapshot/parity/invariants

  Extend authoritative state only as required for REMAP-2.

  If new persisted fields require a schema bump:
  - migrate v3 snapshots explicitly;
  - preserve deterministic continuation;
  - do not invalidate prior snapshots silently.

  Expand invariants for:
  - wear/damage bounds;
  - fidelity state;
  - repair job authoritative fields;
  - recipe/ambient fabrication progress;
  - any new plan-specific assault physical-lifecycle bookkeeping that belongs in simulation state.

  Extend Python parity only where retained semantics intentionally match. Deliberate current-Godot replacements should be documented rather than forced into false parity.

- Preserve:
  - `WorldSimulationRuntime` / `SimulationKernel` as the only macro simulation authority.
  - Physical `WaveManager`/Enemy/turret/infrastructure combat as loaded assault authority.
  - Scene adapters submit typed commands/observations only.
  - Current physical repair interaction authority.
  - Current local physical power-delivery authority.
  - Current ARRN player-facing interaction authority.
  - Existing deterministic RNG/snapshot continuation contract.
  - Existing REMAP-0/1 behavior except where explicitly corrected above.

- Non-goals:
  - campaign disk persistence / REMAP-3;
  - final migration demolition/closeout / REMAP-4;
  - Python tactical assault resolver or tactical bridge;
  - terminal prose generation;
  - recreation of historical Python grid/topology models;
  - redesign of loaded physical combat;
  - replacement of current wall/build placement authority;
  - broad UI redesign.

- Acceptance:

  ## REMAP-1 correction gates

  1. Strategic assault completion is not recorded when the last enemy is merely spawned.
  2. A plan-specific physical completion observation occurs only after that plan's owned live actors are resolved and its pending spawns are empty.
  3. A busy/rejecting WaveManager leaves the plan pending and later retry succeeds exactly once.
  4. Restoring a `HANDOFF_READY` snapshot re-offers the plan and can complete normally.
  5. The scene binding no longer mutates simulation state directly; handoff acceptance/completion use typed ingress.
  6. Strategic target → physical objective mapping is explicit and regression-tested.
  7. Assault-recency event weighting resets/advances against the real assault lifecycle.
  8. Knowledge-tier-7 relay dormancy pressure matches retained `ceil(n/2)` behavior.
  9. Infrastructure event weighting uses a live authoritative power signal.
  10. Duplicate relay command match arms are gone.
  11. Relay knowledge benefits touching repair/fidelity/fabrication are explicitly classified and implemented or retired.

  ## REMAP-2 gates

  12. Macro order is explicitly asserted with wear and fidelity in their final owned slots.
  13. Same-seed wear/fidelity/repair/fabrication traces are deterministic.
  14. Wear responds to defense-readiness and fortification policy without touching loaded physical HP directly.
  15. Fidelity transitions across thresholds deterministically and presentation consumes, rather than owns, the macro result.
  16. Repair requests cannot choose their own authoritative cost/duration; invalid/insufficient-resource cases fail closed.
  17. In-progress repairs snapshot/restore and continue identically.
  18. Fabrication requests cannot choose arbitrary authoritative outputs/duration.
  19. Explicit and ambient fabrication use one authoritative resource/output contract and never produce resources without consuming required inputs.
  20. Ambient fabrication allocation/progress snapshot/restore continues identically.
  21. Cross-runtime parity covers each retained REMAP-2 algorithm that is intentionally exact, with superseded behavior explicitly classified.
  22. Existing REMAP-0/1 focused smokes remain green.
  23. The world-simulation migration suite passes once at closeout.
  24. `design/04_architecture/PYTHON_SIM_REMAP_TRACKER.md` marks REMAP-2 complete only after both the review corrections and REMAP-2 systems satisfy acceptance.

- Task overrides: `none`

- Deferred:
  - REMAP-3: campaign/save-file persistence across process restart.
  - REMAP-4: final parity/classification audit and migration closeout.

## Work Surface

Likely active files, subject to live graph/source inspection:

- `custodian/game/systems/simulation/simulation_kernel.gd`
- `custodian/game/systems/simulation/relay_simulation_system.gd`
- `custodian/game/systems/simulation/systemic_event_simulation_system.gd`
- `custodian/game/systems/simulation/strategic_assault_simulation_system.gd`
- `custodian/game/systems/simulation/repair_simulation_system.gd`
- `custodian/game/systems/simulation/fabrication_simulation_system.gd`
- new focused wear/fidelity simulation systems if appropriate
- `custodian/game/state/world/world_simulation_state.gd`
- repair/fabrication/assault state objects
- `custodian/game/world/bindings/wave_manager_simulation_binding.gd`
- `custodian/game/systems/core/systems/wave_manager.gd`
- `custodian/game/ui/terminal/terminal_fidelity_policy.gd`
- parity fixture/projection tooling
- focused world-simulation validation

## Plan

1. Fix and test A1–A9 before expanding the macro model.
2. Classify retained wear/fidelity/repair/fabrication semantics against current Godot authority.
3. Make repair/fabrication request contracts simulation-owned rather than caller-authored.
4. Implement wear and macro fidelity in explicit deterministic macro slots.
5. Implement ambient fabrication on the same authoritative recipe/resource path as explicit fabrication.
6. Extend state/snapshot/invariants/parity only for retained semantics.
7. Run focused tests during implementation and the migration suite once at the coherent closeout boundary.
8. Update tracker/current-state/index docs only where owned truth changes.

## Handoff

- Next action: inspect the live ownership graph around WaveManager external plans, simulation command ingress, repair/fabrication command callers, current COMMS/power state, and current recipe/resource authorities. Fix the REMAP-1 handoff lifecycle first.
- Best starting files:
  - `custodian/game/world/bindings/wave_manager_simulation_binding.gd`
  - `custodian/game/systems/core/systems/wave_manager.gd`
  - `custodian/game/systems/simulation/simulation_kernel.gd`
  - `custodian/game/systems/simulation/relay_simulation_system.gd`
  - `custodian/game/systems/simulation/systemic_event_simulation_system.gd`
  - `custodian/game/systems/simulation/repair_simulation_system.gd`
  - `custodian/game/systems/simulation/fabrication_simulation_system.gd`
  - `design/04_architecture/PYTHON_SIM_TO_GODOT_MIGRATION.md`
- Blockers or open questions:
  - No blocker known. If current active design does not define a macro power-availability signal suitable for fidelity/event weighting, make that ownership decision explicit in the implementation and document it rather than reusing inert legacy fields.
