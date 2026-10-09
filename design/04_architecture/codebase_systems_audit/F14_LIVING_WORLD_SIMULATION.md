# F14 · Living-world simulation, interest management and unloaded-sector continuity

[← Systems audit overview](../CODEBASE_SYSTEMS_AUDIT.md) · [Conceptual packet roadmap](PACKET_ROADMAP.md#cs-f14-a)

> **Status:** source-level initial audit recorded; local Godot baseline/actor reification proof pending  
> **Priority:** P0 audit focus, NOT an automatic implementation/dispatch priority  
> **Decision:** **NOT LOCKED**. No new executable packets authorized or authored.  
> **Workstream:** `living-world-simulation-audit`; repository branch `agent/living-world-simulation-audit` for this documentation slice.  
> **Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31  
> **Evidence method:** current GitHub source + design + validation recipe inspection, October 8, 2026. No local Godot execution or interactive playtesting in this audit.

## Why this focus exists

The first 13-item systems overview omitted the **living-world continuity seam** despite existing simulation design and runtime foundations. HUD/terminal F03 deals with command and presentation ownership, not whether unloaded patrols, sectors, hazards, resources or factions genuinely evolve. F14 makes that missing cross-cutting responsibility explicit without duplicating Procgen F02, NPA actor decomposition F04, Infrastructure F08, Campaign continuity F06 or game-feel F12.

The target player promise is that areas the player leaves continue to evolve within an explicit performance budget, and revisit consequences can be reconstructed from authoritative history/state instead of invented anew.

## Source-grounded inventory

| Owner | Verified implementation | Interpretation |
| --- | --- | --- |
| [`world_simulation_runtime.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/simulation/world_simulation_runtime.gd) | Single 60-Hz authoritative campaign clock, kernel/snapshot/command ingress, campaign outcome | **Implemented campaign macro runtime.** Not proof of unloaded individual actor continuity. |
| [`simulation_kernel.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/simulation/simulation_kernel.gd) | Every 60 fixed ticks advances strategic power, logistics, repairs, fabrication, relays, systemic events, assaults, wear and fidelity; keeps serializable macro state | **Implemented 1-Hz strategic systems** (at normal clock), not a sector-by-sector actor-preserving background simulator. |
| [`simulation_interest_manager.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/simulation/simulation_interest_manager.gd) | Player-distance classification every 0.20 seconds, radii 900/1600/3000px; node tiers active/nearby/background/dormant; DevObservatory counts | **Implemented classification**; scene-local and position-based, not loaded/unloaded actor serialization. |
| [`enemy.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/actors/enemies/enemy.gd) | `set_simulation_tier` suspends physics in dormant; `_simulation_tier_interval` throttles nearby to .10s, background to .50s; others run ordinary physics | **Implemented coarse live-actor update frequency.** Dormant does not run an abstract world-behavior tick; no evidence actor identity/intent transfer is integrated. |
| [`world_state_graph.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/world/world_state_graph.gd) | Key/value graph, dependency evaluation, observable changes | Useful shared presentation/derived-state projection, not a competing simulator. |
| [`world_history.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/world/world_history.gd) | Bounded per-sector in-memory journal; timestamps with `Time.get_ticks_msec()` | Useful telemetry; **not a durable deterministic strategic history** or a replayable authoritative simulation ledger. |
| [`PYTHON_SIM_REMAP_TRACKER.md`](../PYTHON_SIM_REMAP_TRACKER.md) | REMAP-0/1/2 complete per tracker; REMAP-3 disk persistence queued; REMAP-4 migration closeout pending | Preserve actual Godot macro authority; historical Python runtime not a live dependency. |
| [`INTEREST_MANAGEMENT_SYSTEM.md`](../../01_systems/INTEREST_MANAGEMENT_SYSTEM.md) | Active interest-management contract; next-slice proposal for hysteresis and abstract background tick | Foundation spec, not proof that authoritative abstract background updates exist. |
| [Sector Activity Simulator candidate](../../90_codex/simulation/sector_activity_simulator.md) | Explicit active/warm/strategic/frozen/historical design concept, exit/re-entry promise and example sector state | **Existing idea card**, not an implemented/approved production spec. Graduate through a locked decision, do not silently treat as runtime authority. |

**Important terminology:** `WorldSimulationState.macro_fidelity` is COMMS/intelligence fidelity (FULL/DEGRADED/FRAGMENTED/LOST). It is **not** a named active/nearby/background/dormant simulation workload tier. Do not conflate the two.

## Findings, classified

**F14-01 · CONFIRMED:** Strategic simulation and distance-tiered live enemy processing exist, but use separate clocks/abstractions. Kernel steps deterministic ticks; interest manager classifies on `_process(delta)`; enemies accumulate physics delta and throttle according to tier. This is not itself a defect. It becomes relevant when defining reproducible unload/reactivate handoff behavior.

**F14-02 · CONFIRMED LIMITATION:** `dormant` currently zeroes enemy velocity and disables physics, instead of migrating that actor's identity/objective/health/location into a strategic sector simulation. The proposed Sector Activity Simulator concept describes this missing strategic behavior. Full loaded→abstract→loaded actor continuity remains **unverified/not evidenced**, not categorically absent across every subsystem.

**F14-03 · CONFIRMED LIMITATION:** `WorldHistory` is an in-memory journal using monotonic process milliseconds, and macro campaign disk persistence remains incomplete per REMAP-3. It cannot by itself satisfy deterministic persistent histories across process restarts.

**F14-04 · DOC DRIFT:** The interest design says background enemies continue ordinary physics until an abstract 1–2Hz update is implemented. Live `Enemy._simulation_tier_interval()` already throttles normal enemy physics/behavior to 0.50s in background, and 0.10s nearby. Clarify intended behavior and update the active design only after characterization tests; **no fabricated evidence of correctness or error**.

**F14-05 · UNVERIFIED DESIGN GAP:** Entity identity, aggregate population accounting, sector ownership and reification are not expressed by the investigated strategic macro state; do not infer duplicates or missing actors at runtime without tracing spawn/despawn/streaming/Director integration and constructing a live test.

**F14-06 · UNVERIFIED RISK:** Dormant enemy physics suspension may not suspend all child nodes/timers/perception/independent components. Verify with instrumented lifecycle tests rather than treating `set_physics_process(false)` as global suspension.

## Desired authority model to consider (not locked)

```text
WorldSimulationRuntime + SimulationKernel
  = time, deterministic commands, macro state, sector-wide progress
    |
    +-- Interest management / performance budget
    |     = how much physical resolution is justified for each region/entity
    |
    +-- Sector-level abstract state
    |     = what unfolds when not physically instantiated
    |        (population, group intent, objectives, resources, hazards, changes)
    |
    +-- Handoff / reification adapter
          = loaded -> summarized -> unloaded -> updated -> reconstructed
             with stable identity, no double-spawn and causal history
               |
               +-- Physical actors + NPA behavior, scene encounters,
                   procgen streaming and player interaction
```

Never resolve offscreen attacks with the same physical combat mechanics or claim direct loaded-scene damage without explicit design. This is an aggregate/causal simulation with believable consequences, not a second complete Godot scene running invisibly. Preserve fixed-step authority, determinism, explicit spawn ownership and loaded-world combat. A no-refactor or minimal-gated option is valid if audit evidence shows existing facilities suffice.

## Desired first playable proof before committing to a broad program

1. Seed a small two-sector scenario with one named patrol/group, a resource/repair consequence and a stable entity identity.
2. Start in A while B is absent from loaded physical gameplay. Advance **authoritative simulation time**, not wall-clock sleep.
3. Observe B change in a reproducible, inspectable way, including a causal reason; persist or snapshot the state and verify deterministic continuation.
4. Enter B: reconstruct **one** correct patrol/group state, with adjusted location/goal, no duplicate spawn, no reset to default health/resources and no immediate contradiction to loaded-world physics.
5. Exit/re-enter and test repeated crossings, delayed events, large time jumps, campaign outcome and save/restart requirements.

This is a proposed **acceptance narrative**. Precise schema, update cadence and ownership must be locked after local proof and performance measurements.

## Runtime audit agent: recommended READ-ONLY first pass

No all-repo refactor required. Agent should:

- Start from latest `origin/main` with repository AGENTS and current docs; make no source edits.
- Trace exact scene tree, autoloads, interest classification, enemy throttling, node/component processing, procgen distant unloading, EnemyDirector spawn/identity and `WorldSimulationRuntime` bindings.
- Run the repository-prescribed focused tests:
  ```bash
  cd custodian
  godot --headless --path . --script res://tools/validation/world_simulation_kernel_smoke.gd
  godot --headless --path . --script res://tools/validation/world_simulation_macro_state_smoke.gd
  godot --headless --path . --script res://tools/validation/world_telemetry_foundation_smoke.gd
  godot --headless --path . --script res://tools/validation/world_simulation_live_scene_smoke.gd
  ```
- Characterize, **do not silently repair**, dormant/nearby/background processing, simulation-tick ownership, seeded snapshot/restore, and missing actor reification tests. Use narrower profiling only if source evidence needs it.
- Return findings IDs, touched/read paths, test pass/fail and reproducibility, gaps in existing smokes, design drift, a candidate architecture boundary, and recommended decision-lock changes. Do **not** create runnable implementation packets.

## Cross-workstream ownership guard

- **F02 Procgen:** world install/streaming and accepted topology; no authority to decide fictional offscreen consequences.
- **F04 NPA:** physical actor behavior/composition when loaded; eventual reification API consumer, not strategic simulation's owner.
- **F06 Campaign:** Hub/campaign lifetime and exactly-once outcomes; coordinate persistent state but do not replace campaign progression.
- **F08 Infrastructure:** physical resource/repair/power owners; strategic projections only by explicit binding/command.
- **F10 Streaming/presentation:** whether content is rendered/instanced; visibility is never the source of truth for physical action.
- **F12/F13 Feel/feature ROI:** player-visible patrol movement/recovery and environmental responsiveness are value measures, not implementation owners.
- **F03 HUD:** observatory/terminal view only; must never become the engine of offscreen simulation.

## Conceptual task-packet roadmap

All slots remain blocked pending this item's audit and lock, and existing REMAP, procgen and NPA program ownership checks.

- [CS-F14-A: authority/interest/handoff parity and performance baseline](PACKET_ROADMAP.md#cs-f14-a) (proposed)
- [CS-F14-B: deterministic sector-activity state and simulation rules](PACKET_ROADMAP.md#cs-f14-b) (proposed)
- [CS-F14-C: entity identity, physical→abstract handoff and reification](PACKET_ROADMAP.md#cs-f14-c) (proposed)
- [CS-F14-D: persistent history, save/restore and world consequence reconciliation](PACKET_ROADMAP.md#cs-f14-d) (proposed)
- [CS-F14-E: two-sector playable proof, instrumentation, soak and integration closeout](PACKET_ROADMAP.md#cs-f14-e) (proposed)

A may be audit-only; B and C may change sequence after authority decisions; D must consume REMAP-3 rather than duplicate persistence. This is **not an executable packet sequence**.

## Decision lock record

- **Audit result:** source inventory complete for the named runtime modules; all-group/streaming/cross-scene runtime trace and focused tests **not yet complete**.
- **Selected owner/seam:** proposed above, **undecided**.
- **Design approval:** still needed to choose strategic tick frequency, granularity of stable individual/group identity, reification rules, unloaded hazard/combat limitations and player-facing reporting.
- **Preserved contracts:** 60Hz fixed step, kernel macro ordering, loaded physical gameplay, one runtime authority, canonical procgen and campaign identity.
- **Document drift:** interest background throttle mismatch recorded; do not rewrite historical design speculation as implemented truth.
- **Implementation decision:** **UNLOCKED**; **0 new packets authored or activated**. Next: local read-only characterization + desired two-sector proof scope and then explicit lock.
