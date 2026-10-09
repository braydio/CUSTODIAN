# F14 · Living-world simulation, interest management and unloaded-sector continuity

[← Systems audit overview](../CODEBASE_SYSTEMS_AUDIT.md) · [Conceptual packet roadmap](PACKET_ROADMAP.md#cs-f14-a)

> **Status:** local Godot **baseline characterization received**; unloaded-area actor-continuity proof pending  
> **Priority:** P0 audit focus, NOT an automatic implementation/dispatch priority  
> **Decision:** **F14 V1 behavioral boundary LOCKED** (user choice: bounded offscreen outcomes); specific B abstract-activity implementation slice approved for packet authoring. Full physical actor handoff, reification, REMAP-3 disk persistence and cross-world simulation rollout remain **NOT IMPLEMENTED / NOT LOCKED**.  
> **Workstream:** `living-world-simulation-audit`; repository branch `agent/living-world-simulation-audit` for this documentation slice.  
> **Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31  
> **Evidence method:** initial live GitHub source/design inspection plus **user-supplied read-only local agent audit** of runtime source matching fetched `origin/main@1d19ec8fae15c6eb23604457e3da2adef596c19d`, October 8, 2026. Six reported headless runs passed; those commands were executed by the local agent, **not by this documentation editor**. Findings rechecked against current `main` where indicated. No physical→abstract→physical gameplay proof yet.

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

**F14-04 · CONFIRMED DOC DRIFT; DESCRIPTION CORRECTED:** The earlier interest spec described nearby/background as full ordinary processing. Source and local benchmark characterize `Enemy._simulation_tier_interval()` as 0.10s nearby / 0.50s background, within root `_physics_process` rather than an abstract actor model. The source-grounded behavior is now documented in [`INTEREST_MANAGEMENT_SYSTEM.md`](../../01_systems/INTEREST_MANAGEMENT_SYSTEM.md). This descriptive correction does **not** approve further throttling or change the intended gameplay contract; gameplay/feel parity of tier transitions is not yet proved.

**F14-05 · CONFIRMED EVIDENCE GAP (NOT PROVEN GLOBAL ABSENCE):** The agent traced `ambient_enemy_spawner.gd:44–95`: ambient enemy `stable_spawn_ordinal` is assigned at spawn, not shown to be a durable identity. `proc_gen_tilemap.gd:10673–10705` unloads **visual chunk presentation** while preserving canonical semantics; it does not itself serialize, migrate or reify enemy actors. `level_loader.gd:296–305` may disable route-cached scenes or free them under destroy policy. No inspected live test demonstrates stable identity/objective/health across unload→offscreen activity→reconstruction. Other level-specific teardown/persistence integration paths remain to be audited; do not claim every system lacks them.

**F14-06 · VERIFIED SUSPENSION SCOPE; SUBTREE RISK OPEN:** `enemy.gd:1980–1988` zeros velocity and disables **root** physics for dormant actors; this does not itself suspend all descendants, timers, signals or presentation. The local agent reported eight dormant actors producing zero enemy physics-body spans while all eight remained presentation-enabled. `get_runtime_cost_state()` supplies tier-derived flags, **not proof of actual descendant processing**. Source inspection of `enemy_perception_component.gd:22–25,99–125` found a connected noise-bus handler that may mutate the cached blackboard after dormancy, subject to its eligibility/cache state. **Not reproduced at runtime**: a targeted descendant/noise lifecycle test remains required.

## Local read-only runtime audit and validation receipt (2026-10-08)

**Provenance:** The user supplied an agent report stating its fetched baseline was `origin/main@1d19ec8fae15c6eb23604457e3da2adef596c19d` with a clean working tree and matching local runtime sources; local `main` was three documentation-only commits behind. The results below are **reported local runs**, not commands re-executed by this documentation pass. Current `main` was fetched again for the simulation clock/runtime and current design artifacts; no new behavior is inferred from commit ancestry alone.

| Local validation (all reported exit 0) | Outcome and boundary |
| --- | --- |
| `world_simulation_kernel_smoke.gd` | **PASS:** macro command/clock and kernel contracts; no physical offscreen continuation |
| `world_simulation_macro_state_smoke.gd` | **PASS:** strategic ordering and deterministic macro continuation; no offscreen groups |
| `world_telemetry_foundation_smoke.gd` | **PASS:** dummy interest-managed node telemetry; does not prove enemy descendant lifecycle |
| `world_simulation_live_scene_smoke.gd` | **PASS:** scene/runtime creation, pause/fixed ticks, snapshot and binding; no unloaded actor reification |
| `world_simulation_snapshot_roundtrip_smoke.gd` | **PASS:** valid snapshot restore with an expected invalid-schema negative-control error |
| `enemy_runtime_attribution_perf_bench.gd` | **PASS:** eight actors per uniform tier, instrumentation only; not a production-hardware capacity or game-feel threshold |

**Reported benchmark:** ~6.89 ms average frame wall time across four uniform-tier cases, `enemy_total` ~0.481 ms for eight active vs. 0 ms for eight dormant. The report path on the agent's local machine was `/home/braydenchaffee/.local/share/godot/app_userdata/CUSTODIAN/performance/enemy_runtime_attribution_perf_bench.json`. This absolute path is an **agent-local artifact**, not a portable checked-in report or evidence of full-subtree suspension. Collect machine-controlled comparisons before setting performance targets.

**Explicit limits:** No smoke above validates an unloaded geographic area's changed state, a stable actor/group reconstruction, exact population counts after repeated crossings, or the end-to-end disk-restart world lifecycle. The first proof must be added separately.

### Additional findings from the local characterization

**F14-07 · CONFIRMED SNAPSHOT CONTRACT LIMIT:** `WorldSimulationState` snapshots include macro sector/structure state, queues for repairs/fabrication, bounded macro events and serialized RNG. However `WorldSimulationRuntime.save_snapshot()` returns a dictionary, not a disk save; `restore_snapshot()` restores world state and `clock.fixed_tick`, not `SimulationClock` accumulator/pause/drop counters or `SimulationKernel` pending command queue and next sequence. Which of those must survive a **save/restart** boundary, versus being intentionally normalized to a safe fixed-step boundary, is a REMAP-3 design/validation choice. No save correctness claim until that contract is explicit.

**F14-08 · CONFIRMED DUAL CLOCK USE, NO DEFECT PROVED:** Campaign kernel advances fixed steps at 60Hz and steps macro systems every 60 fixed ticks; interest classification runs at 0.20s in presentation `_process`, and enemy behavior throttling accumulates physics `delta`. They are separate scheduling surfaces. This does not prove that tier transitions break determinism, but it prohibits treating elapsed wall time or interest-classification frames as authoritative abstract-world time without a bridge.

**F14-09 · F15 GEOGRAPHY DEPENDENCY:** A conceptual `sector_activity` subsystem cannot use facility macro-sector names (POWER/COMMS/etc.), scene `Sector` rectangles or presentation chunk IDs as its only geographic identity. [F15 campaign-world geography](F15_CAMPAIGN_WORLD_GEOGRAPHY.md) owns stable geographic topology and location vocabulary across one large traversable campaign. **The first F14 proof may use two deterministic synthetic geographic location IDs** so it is not blocked on the final physical world size or art; production ownership/schema integration must wait for an agreed F15 geographic identity contract. This does not block F14 lifecycle/clock test characterization.

### Audit milestone and residual tests

**Baseline local read-only audit: satisfied.** Re-running the above six green smokes as a standalone conceptual `CS-F14-A` packet has low return. Remaining useful evidence is **new** lifecycle falsification, not re-auditing the same runtime:

1. Dormant enemy with actual perception component and noise-bus signals: prove which descendant callbacks/state mutations remain possible and which behavior must be disabled or redirected.
2. Demonstrate physical actor identity and health/intent/state across a real level cache/destroy and re-entry, with a negative case for duplicate spawns.
3. Seeded abstract two-geographic-location proof using canonical fixed ticks with B uninstantiated: causal offscreen event → deterministic snapshot/replay → reification exactly once → repeated leave/return.
4. Process-restart persistence, exact-once event reconciliation and pending-command/clock-boundary semantics coordinated with REMAP-3.
5. Only after geographic scale/interest policies are locked: representative population/performance budget and visibility-independent processing measurements.

## F14 V1 behavioral decision lock (user-approved 2026-10-09)

**Decision authority:** The user selected **Bounded** offscreen simulation. This locks the gameplay ceiling/intent, not a new global world generator, encounter balance table, vehicle tuning, or fiction rule.

| Concern | Locked F14 V1 decision |
| --- | --- |
| **Global owner** | Existing `WorldSimulationRuntime` / `SimulationKernel` and authoritative fixed ticks remain the sole campaign time/mutation owner. An abstract-activity component is invoked by the existing kernel, never a competing autoload clock. |
| **Geographic identity** | Use stable **Domain ID + geographic location ID + group ID**. Group and individual IDs are domain-scoped, not nested under a temporary CampaignVisit or scene and may change location. A first isolated data test may use two synthetic locations `A` and `B` with an explicit seed. Do not key this to facility POWER/COMMS `Sector` nodes or streamed presentation chunks. |
| **Levels of detail** | Near operator: physical gameplay/NPA owns combat. Far and unloaded: group-level causal abstract state; individual state only where meaningful and durable. The interest manager selects **resolution**, not consequences. |
| **Bounded activity** | Legitimate offscreen outcomes may include patrol movement/route occupation, work progression, repairs/resources via their existing owners, pressure and warnings, retreat, encounter outcomes and bounded casualties *only under explicit later policy*. Offscreen actors do not run unseen physical bullet/animation/physics combat. |
| **V1 foundation scope** | One stable named group in synthetic location B makes a deterministic, inspectable nonlethal state change (e.g. patrol objective/route progress) while no actor in B is instantiated; fixed-seed snapshots reconstruct the same abstract state and event. V1 is **not** full physical reification or material stock mutation. |
| **Cadence** | Prototype group activity at **one update per 60 authoritative fixed ticks** (~1Hz at normal speed) as configurable/tunable policy; deterministic ID-sorted ordering, bounded work per update and event-driven idle behavior. Benchmark before freezing throughput/catch-up policies for production or distant domains. |
| **Handoff law** | Exactly one representation owns a group at any moment: physical while loaded, abstract while genuinely absent, never both. Physical→abstract summary and abstract→physical reification must preserve stable ID, location, objective, relevant resources and condition and never double-spawn. This is the **locked target for F14-C**, not acceptance falsely attributed to F14-B. |
| **Persistence and events** | Abstract state/event outputs must be serializable/deterministically replayable and have causal reason/tick. Integrate real disk persistence and once-only handling through **REMAP-3**, not an independent save subsystem. Existing WorldHistory telemetry is not authoritative save history. |
| **Offscreen stakes** | Avoid out-of-camera surprise resolution of named story-critical characters, irreversible campaign failure, wholesale settlement destruction or contested extraordinary actions without a later explicitly approved rule/visibility policy. No infinite offscreen simulation when the campaign runtime is inactive. |
| **Evidence** | Six user-supplied headless checks passed baseline code, **not** unloaded reification. New focused seeded offscreen foundation smoke required for B; real unload/re-enter/duplicate tests belong to C/E. |

**Approvals:** F14 V1 owner/rule boundary and **CS-F14-B as next narrow implementation workstream** are design-authorized. B must be independently reviewable before physical adapter work. F15's continuous world geography is **the player-facing target**; physical streaming architecture, numeric scale, biome assets, seam technology and vehicle traversal tuning are separately pending. No global runtime execution or complete F14 implementation claim is implied by this lock.

## Target ownership model (V1 boundaries locked; later integrations gated)

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

1. Seed two **synthetic geographic location IDs** (A/B) in one campaign with one named patrol/group, a resource/repair consequence, and stable actor/group and location identity. Do **not** use a POWER/COMMS facility macro sector or painted presentation chunk as the geographic key.
2. Start in A while B is absent from loaded physical gameplay. Advance **authoritative simulation time**, not wall-clock sleep.
3. Observe B change in a reproducible, inspectable way, including a causal reason; persist or snapshot the state and verify deterministic continuation.
4. Enter B: reconstruct **one** correct patrol/group state, with adjusted location/goal, no duplicate spawn, no reset to default health/resources and no immediate contradiction to loaded-world physics.
5. Exit/re-enter and test repeated crossings, delayed events, large time jumps, campaign outcome and save/restart requirements.

This is a proposed **acceptance narrative**. Precise schema, update cadence and ownership must be locked after local proof and performance measurements.

## Local audit status

The requested **read-only local source/test audit has been returned** and is recorded above. It does not need to be repeated as a second implementation task. The next checks should be newly scoped, falsifiable **dormant-subtree / actor-handoff lifecycle tests** and the F15 geographic identity decision, rather than an unfocused Godot sweep. Consult the six reproduced command names above and `VALIDATION_RECIPES.md` for regression reuse.

## Cross-workstream ownership guard

- **F02 Procgen:** world install/streaming and accepted topology; no authority to decide fictional offscreen consequences.
- **F04 NPA:** physical actor behavior/composition when loaded; eventual reification API consumer, not strategic simulation's owner.
- **F06 Campaign:** Hub/campaign lifetime and exactly-once outcomes; coordinate persistent state but do not replace campaign progression.
- **F08 Infrastructure:** physical resource/repair/power owners; strategic projections only by explicit binding/command.
- **F10 Streaming/presentation:** whether content is rendered/instanced; visibility is never the source of truth for physical action.
- **F12/F13 Feel/feature ROI:** player-visible patrol movement/recovery and environmental responsiveness are value measures, not implementation owners.
- **F03 HUD:** observatory/terminal view only; must never become the engine of offscreen simulation.
- **F15 Geographic topology:** stable location/territory and campaign-world topology identity; F14 consumes it for offscreen simulation but should not create a competing geographic generator. Synthetic geographic IDs are acceptable for F14's initial behavioral test.

## Conceptual task-packet roadmap

CS-F14-A read-only evidence is satisfied. **Only the narrow CS-F14-B abstract activity foundation is authorized** for packet authoring by the October 9 V1 behavioral decision; its new implementation/review pair remains **draft/manual pending local authoring preflight**. CS-F14-C/D/E are not yet authorized and still require evidence plus REMAP, procgen and NPA owner reconciliation.

- [CS-F14-A: authority/interest/handoff parity and performance baseline](PACKET_ROADMAP.md#cs-f14-a) (proposed)
- [CS-F14-B: deterministic abstract geographic-group activity](PACKET_ROADMAP.md#cs-f14-b) (design locked; [draft implementation packet](../../../custodian/docs/ai_context/task_packets/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md) and [paired review](../../../custodian/docs/ai_context/task_packets/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md) awaiting authoring validator)
- [CS-F14-C: entity identity, physical→abstract handoff and reification](PACKET_ROADMAP.md#cs-f14-c) (proposed)
- [CS-F14-D: persistent history, save/restore and world consequence reconciliation](PACKET_ROADMAP.md#cs-f14-d) (proposed)
- [CS-F14-E: two-sector playable proof, instrumentation, soak and integration closeout](PACKET_ROADMAP.md#cs-f14-e) (proposed)

**A's read-only diagnostic purpose is satisfied. B is approved for the isolated synthetic-location state-only implementation after packet-pair authoring preflight.** C's real reification contract must be refreshed from reviewed B and F15's actual location/streaming owner; D must consume REMAP-3 rather than duplicate persistence. Do not mistake B design authorization for an implemented system, or authorize C–E automatically.

## Decision lock record

- **Audit result:** read-only baseline runtime/source characterization and six focused local checks **reported complete/passing**. Full actor handoff/reification, descendant lifecycle and unloaded-area causal simulation tests **not yet proven**.
- **Selected owner/seam:** F14 V1 boundary **LOCKED** below: `WorldSimulationRuntime`/`SimulationKernel` authoritative time and macro commands; a focused activity-state owner scoped by stable synthetic geographic keys; interest manager classifier only; loaded enemies own loaded combat. Real reification adapter and persistence schema remain later decision gates.
- **Design approval:** user explicitly approved **Bounded** offscreen consequences and continuous-geography target (October 9, 2026). F14 V1 adopts authoritative fixed-tick cadence, group-level abstractions with optional stable individual identity and bounded non-physical event types as engineering defaults. Real map identity schema, physical reification, casualty semantics, full restart state and UI reporting await later locks.
- **Preserved contracts:** 60Hz fixed step, kernel macro ordering, loaded physical gameplay, one runtime authority, canonical procgen and campaign identity.
- **Document drift:** interest tier behavior mismatch recorded and descriptive implementation notes reconciled in `design/01_systems/INTEREST_MANAGEMENT_SYSTEM.md`; further gameplay policy changes remain unapproved.
- **Implementation decision:** **F14-B foundation authorized for packet authoring** as an isolated deterministic simulation-data slice. The broader F14 program is **not** automatically authorized: C reification, D REMAP-3 integration and E playable integration remain dependency/design-gated. Before dispatch, the specific new packet and paired review must pass the repository's targeted authoring preflight. Next: implement/review B before revisiting C.
