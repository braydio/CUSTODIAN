# F14 · Living-world simulation, interest management and unloaded-sector continuity

[← Systems audit overview](../CODEBASE_SYSTEMS_AUDIT.md) · [Conceptual packet roadmap](PACKET_ROADMAP.md#cs-f14-a)

> **Status:** F14 baseline audited; F14-B abstract group activity landed, first fresh review found **blocking R0-01** (dotted identity collision), and the bounded correction landed on `origin/main@d67cf70e0` with focused smokes reported passing. **F14-B accepted, and the later real-Grunt F14-C1 implementation/correction cycle also passed its fresh paired re-review (R0-01/02/03 fixed; no new findings).** Full production geographic residency remains pending.
> **Priority:** P0 audit focus, NOT an automatic implementation/dispatch priority  
> **Decision:** **F14 V1 behavioral boundary LOCKED** (user choice: bounded offscreen outcomes). F14-B implementation and bounded R0-01 correction are landed, **independently accepted after correction**. **Synthetic explicit real-Grunt physical↔abstract handoff is implemented and independently accepted in C1.** Production geographic residency/spawner binding, REMAP-3 disk persistence and multi-site player-facing simulation remain **NOT IMPLEMENTED / NOT LOCKED**.  
> **Workstream:** `living-world-simulation-audit`; repository branch `agent/living-world-simulation-audit` for this documentation slice.  
> **Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31  
> **Evidence method:** initial live GitHub source/design inspection plus **user-supplied read-only local agent audit** of runtime source matching fetched `origin/main@1d19ec8fae15c6eb23604457e3da2adef596c19d`, October 8, 2026. Six reported headless runs passed; those commands were executed by the local agent, **not by this documentation editor**. Findings rechecked against current `main` where indicated. Later C1 synthetic real-Grunt physical→abstract→physical proof is independently accepted; no production geographic/residency gameplay proof yet.

## Why this focus exists

The first 13-item systems overview omitted the **living-world continuity seam** despite existing simulation design and runtime foundations. HUD/terminal F03 deals with command and presentation ownership, not whether unloaded patrols, sectors, hazards, resources or factions genuinely evolve. F14 makes that missing cross-cutting responsibility explicit without duplicating Procgen F02, NPA actor decomposition F04, Infrastructure F08, Campaign continuity F06 or game-feel F12.

The target player promise is that areas the player leaves continue to evolve within an explicit performance budget, and revisit consequences can be reconstructed from authoritative history/state instead of invented anew.

## Source-grounded inventory

| Owner | Verified implementation | Interpretation |
| --- | --- | --- |
| [`world_simulation_runtime.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/simulation/world_simulation_runtime.gd) | Single 60-Hz authoritative campaign clock, kernel/snapshot/command ingress, campaign outcome | **Implemented campaign macro runtime.** Not proof of unloaded individual actor continuity. |
| [`simulation_kernel.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/simulation/simulation_kernel.gd) | Every 60 fixed ticks advances strategic power, logistics, repairs, fabrication, relays, systemic events, assaults, wear, fidelity **and F14-B abstract group route activity**. | **Implemented bounded deterministic abstract activity** for synthetic geographic IDs; no loaded Enemy state transfer or production map integration. |
| [`abstract_activity_simulation_state.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/state/world/abstract_activity_simulation_state.gd) | Stable domain/group and synthetic location records, sorted deterministic progression, causal events and schema-v5 serialization. New event IDs are length-prefixed; old schema-v5 event IDs remain readable on restore. | **Implemented in F14-B + R0-01 correction**, fresh independent correction re-review passed. No physical actors or real geographic stream ownership. |
| [`simulation_interest_manager.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/simulation/simulation_interest_manager.gd) | Player-distance classification every 0.20 seconds, radii 900/1600/3000px; node tiers active/nearby/background/dormant; DevObservatory counts | **Implemented classification**; scene-local and position-based, not loaded/unloaded actor serialization. |
| [`enemy.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/actors/enemies/enemy.gd) | `set_simulation_tier` suspends physics in dormant; `_simulation_tier_interval` throttles nearby to .10s, background to .50s; others run ordinary physics | **Implemented coarse live-actor update frequency.** Dormant does not run an abstract world-behavior tick; no evidence actor identity/intent transfer is integrated. |
| [`world_state_graph.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/world/world_state_graph.gd) | Key/value graph, dependency evaluation, observable changes | Useful shared presentation/derived-state projection, not a competing simulator. |
| [`world_history.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/world/world_history.gd) | Bounded per-sector in-memory journal; timestamps with `Time.get_ticks_msec()` | Useful telemetry; **not a durable deterministic strategic history** or a replayable authoritative simulation ledger. |
| [`PYTHON_SIM_REMAP_TRACKER.md`](../PYTHON_SIM_REMAP_TRACKER.md) | REMAP-0/1/2 complete per tracker; REMAP-3 disk persistence queued; REMAP-4 migration closeout pending | Preserve actual Godot macro authority; historical Python runtime not a live dependency. |
| [`INTEREST_MANAGEMENT_SYSTEM.md`](../../01_systems/INTEREST_MANAGEMENT_SYSTEM.md) | Active interest-management contract; next-slice proposal for hysteresis and abstract background tick | Foundation spec, not proof that authoritative abstract background updates exist. |
| [Sector Activity Simulator candidate](../../90_codex/simulation/sector_activity_simulator.md) | Explicit active/warm/strategic/frozen/historical design concept, exit/re-entry promise and example sector state | **Existing idea card**, not an implemented/approved production spec. Graduate through a locked decision, do not silently treat as runtime authority. |

**Important terminology:** `WorldSimulationState.macro_fidelity` is COMMS/intelligence fidelity (FULL/DEGRADED/FRAGMENTED/LOST). It is **not** a named active/nearby/background/dormant simulation workload tier. Do not conflate the two.

## F14-B implementation, fresh review and correction evidence (2026-10-09)

**Source of truth:** archived [F14-B implementation packet](../../../custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md), [implementation summary](../../../LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_CLAUDE_SUMMARY.md), archived [first independent review packet](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md), [R0-01 review summary](../../../REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_CLAUDE_SUMMARY.md), archived [bounded correction](../../../custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1.md), [correction summary](../../../LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md), and the active [fresh correction re-review packet](../../../custodian/docs/ai_context/task_packets/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1.md). **Historical annotation (superseded):** that note preceded B's passing re-review. Both B and the subsequent C1 correction re-review now have accepted archival receipts.

- **Implemented in F14-B:** `AbstractActivitySimulationState` tracks a deterministic, domain-scoped abstract group across synthetic geographic locations; `SimulationKernel` advances it every 60 authoritative fixed ticks; `WorldSimulationState` canonical snapshot schema is **v5**, with **v4 migration**; causally recorded patrol route progress survives deterministic snapshot continuation. This is *state only*, not actual `Enemy` unload or physical reification.
- **Original implementation validation:** the agent's completion summary reported focused activity, kernel, macro-state, snapshot, telemetry and live-scene Godot smokes PASS, plus changed-file validation **20/20**. This is recorded evidence, not a new local run by the audit editor.
- **R0-01 · BLOCKING FOUND, CORRECTED AND INDEPENDENTLY RE-REVIEWED PASS:** the first reviewer showed accepted dotted IDs `domain=a.b, group=c` and `domain=a, group=b.c` produced the same legacy event ID `a.b.c.60` at fixed tick 60. Snapshot restoration rejected duplicate event IDs. The bounded correction now emits an unambiguous **length-prefixed** `event_id` while `from_dict()` accepts both new IDs and existing schema-v5 legacy IDs. Focused regression covers distinct event IDs, successful snapshot restoration, canonical event/fingerprint continuation and legacy compatibility. **The fresh correction reviewer independently verified it and closed R0-01 with no new findings.**
- **Correction validation reported:** activity/kernel/macro-state/snapshot smokes PASS; correction summary reports a changed-file selection of **2/2**, and the user additionally reports a post-sync selection of **3/3**. These are different run scopes, not contradictory counts.
- **First-review validation limit:** `world_simulation_live_scene_smoke.gd` was **inconclusive in the fresh review worktree** after first Godot editor import exited 139 and left unavailable imported resources. It had passed in the original F14-B implementation run. Do not present the failed import as a demonstrated F14 state defect or re-label the interrupted smoke a PASS. If a live-scene result is material to the re-review, initialize/import successfully before running it, with focused tests preferred for the event-ID correction.
- **Review result:** the archived `review-living-world-abstract-activity-foundation-review-corrections-1` packet and summary record an independent fresh-context **PASS**, clearing B for this F14-C planning refresh. This does not automatically authorize full production geographic/actor streaming; only the explicit C1 boundary below is approved for packet authoring.

**Documentation drift resolved here:** implementation, first review, correction and correction re-review are all archived complete. C1 packet preflight and full F15 geographic binding remain the new open gates. Other active packet files and the managed ready/auto index remain owned by their own workstreams.

## Findings, classified

**F14-01 · CONFIRMED:** Strategic simulation and distance-tiered live enemy processing exist, but use separate clocks/abstractions. Kernel steps deterministic ticks; interest manager classifies on `_process(delta)`; enemies accumulate physics delta and throttle according to tier. This is not itself a defect. It becomes relevant when defining reproducible unload/reactivate handoff behavior.

**F14-02 · CONFIRMED LIMITATION:** `dormant` currently zeroes enemy velocity and disables physics, instead of migrating that actor's identity/objective/health/location into a strategic sector simulation. The proposed Sector Activity Simulator concept describes this missing strategic behavior. Full loaded→abstract→loaded actor continuity remains **unverified/not evidenced**, not categorically absent across every subsystem.

**F14-03 · CONFIRMED LIMITATION:** `WorldHistory` is an in-memory journal using monotonic process milliseconds, and macro campaign disk persistence remains incomplete per REMAP-3. It cannot by itself satisfy deterministic persistent histories across process restarts.

**F14-04 · CONFIRMED DOC DRIFT; DESCRIPTION CORRECTED:** The earlier interest spec described nearby/background as full ordinary processing. Source and local benchmark characterize `Enemy._simulation_tier_interval()` as 0.10s nearby / 0.50s background, within root `_physics_process` rather than an abstract actor model. The source-grounded behavior is now documented in [`INTEREST_MANAGEMENT_SYSTEM.md`](../../01_systems/INTEREST_MANAGEMENT_SYSTEM.md). This descriptive correction does **not** approve further throttling or change the intended gameplay contract; gameplay/feel parity of tier transitions is not yet proved.

**F14-05 · CONFIRMED PHYSICAL HANDOFF/REIFICATION EVIDENCE GAP (NOT PROVEN GLOBAL ABSENCE):** The agent traced `ambient_enemy_spawner.gd:44–95`: ambient enemy `stable_spawn_ordinal` is assigned at spawn, not shown to be a durable identity. `proc_gen_tilemap.gd:10673–10705` unloads **visual chunk presentation** while preserving canonical semantics; it does not itself serialize, migrate or reify enemy actors. `level_loader.gd:296–305` may disable route-cached scenes or free them under destroy policy. No inspected live test demonstrates stable identity/objective/health across unload→offscreen activity→reconstruction. Other level-specific teardown/persistence integration paths remain to be audited; do not claim every system lacks them.

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

**Baseline local read-only audit: satisfied; F14-B synthetic offscreen state implementation landed and corrected, still awaiting its correction re-review.** Re-running the six historical green smokes as a standalone `CS-F14-A` audit packet has low return. Remaining useful evidence is **new** lifecycle falsification, not re-auditing the same runtime:

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

## F14-B acceptance and F14-C planning refresh (2026-10-09)

**Independently accepted F14-B:** [Cycle-1 re-review summary](../../../REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md) and [archived review receipt](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1.md) record **PASS**, `R0-01 fixed`, zero further findings, and focused abstract activity/kernel/macro-state/snapshot smokes PASS. The reviewer used the Godot import preflight and reported focused runner **1/1**. Earlier schema-v5 dotted event IDs remain **restore-only compatible**; new ones use length-prefixed identities. The unrelated Awakening `validate_review_pairing.py` error references a stale `custodian/tools/agent/run_validation.py` path; its owner must correct it separately. This does not invalidate the focused F14 re-review.

**New current-main drift discovered:** Production M6 `ProcGenChunkResidencyPolicy` does evict *disposable painted presentation/cache residency* for distant chunks, while canonical semantics, collision/navigation and foliage identity remain authoritative. It **does not evict or reconstitute Enemy actors**. `AmbientEnemySpawner` uses a per-run `stable_spawn_ordinal` for pacing and its scheduled `_spawn_queue`; `AmbientEnemyCamp` can independently reactivate/spawn based on physical proximity. These are **not a durable Domain/Group/Actor identity registry** and cannot silently become F14 handoff authority. `SimulationInterestManager` only throttles existing live actors and is not a population owner. `Enemy` retains gameplay health, death/corpse/loot and behavior state. **Do not connect physical actor destruction to Archive Resolve or visual chunk eviction.**

### Historical F14-C1 first-proof design contract (implemented and reviewed)

**Design decision:** Author one narrow implementation workstream, **`living-world-entity-reification-handoff`**, to prove an **actual `Enemy` scene (Grunt fixture)** moving `physical → abstract → physical` under explicit, synthetic **Domain + Location A/B** residency requests. This advances the physical-actor bridge *without* prematurely choosing F15's global topology, world-size or production streaming triggers. The broader multi-actor/multi-location production integration is **not** authorized by this step; it must consume F15's later geography/scene binding.

| Contract | First implementation boundary |
| --- | --- |
| **Identity** | One persistent domain-scoped `group_id` plus a distinct stable `actor_id` for one live `Enemy` member. Neither is derived from a `NodePath`, scene instance ID, presentation chunk, `stable_spawn_ordinal`, temporary CampaignVisit nor transient location. Keep the accepted dotted identity grammar; use unambiguous structured or length-prefixed keys as needed. |
| **Authority** | Exactly **one** group representation owns gameplay at a time. Abstract group records may remain serialized as bookkeeping while physical, but their abstract macro progression must be **suspended** in that mode. During abstract ownership, no corresponding live Enemy or descendant callback may continue gameplay. |
| **Transition** | Explicit location-residency request → guard/validate group and actor → capture small approved physical state → atomically transfer ownership at a **SimulationKernel fixed-step boundary** → fully stop/remove physical actor; reverse by staging a real Grunt scene with its state restored **before enabling gameplay**, validating geometry and committing exclusive physical ownership. A failed staging/removal/identity/scene validation leaves the old owner authoritative and does not mutate canonical events or double-spawn. |
| **Carried state** | Persist identity, Domain/Location, current group route objective/progress, actor health/max health or fraction, life/condition, constrained behavior/goal profile and enough transform/entry data to reconstruct at a validated synthetic site anchor. Avoid serializing arbitrary Node graphs, blackboard object references, projectiles or scene-local signals. |
| **Exclusions** | In-flight attack/ability, active collision/damage interactions, corpse/loot/death, boss phases, companions, player, vehicles and other species **fail closed** or remain physical until a later reviewed protocol. Do not delete/respawn a dead actor or award loot as a side effect. |
| **Time and events** | Single 60-Hz fixed-step owner and F14-B macro-stage semantics unchanged. Offscreen causal patrols advance only while the group is abstract. Any new transfer event identity is deterministic and collision-free, with bounded history and no duplicate effects when a request repeats or returns after snapshot restore. |
| **Snapshots** | Persist only authoritative data through existing `WorldSimulationState` / `SimulationSnapshot` path, with an explicit schema upgrade/migration **if required**. Restore old v4/v5 snapshots; preserve accepted legacy schema-v5 event-ID reads and canonical fingerprints. Disk persistence remains REMAP-3. |
| **Placement** | C1 uses deterministic safe A/B test anchors and a production `enemy_grunt.tscn` in a controlled test scene. Spawn/placement services remain the actual owners of world-safe placement; do not bypass their invariants in later production wiring. No production automatic camp spawn interception yet. |
| **Performance** | At most one live actor per group in this first proof, explicit bounded control, no per-frame offscreen actor iteration or hidden simulated SceneTree, no permanent new autoload. Benchmark after F15 production population shape and reification wiring. |

**Required falsification:** physical Enemy exists and has modified health/goal → physical instance becomes truly absent, exclusive abstract state advances at least one fixed macro interval → new Enemy is reified **once** in the correct synthetic location with the **same ActorId and GroupId and altered but conserved carried state**; repeated in/out crossings preserve IDs and do not reset health/intent. Verify negative duplicate reentry, invalid site, unready actor, active combat/death, pending spawn request, paused simulation and failed staging are **non-destructive**. Verify abstract tick is absent while physical, present while abstract, and state-only snapshot restore does not duplicate actors; prior F14-B regression and schema-v5 compatibility remain green. Test the actual Enemy node, not merely a dummy `Node2D`.

**Boundary following C1:** C2 production registration and automatic unload/reentry must be separately refreshed with F15's **stable real geographic IDs/topology** and F02 procgen/NPA/ambient-spawner lifecycle. Later F14-D owns REMAP-3 save/restart integration; F14-E owns two-site player-facing soak. Continuous geography, Ports and vehicle travel stay F15/F09-owned. No new art assets.

**Historical C1 promotion, now complete:** the implementation and paired review passed targeted authoring preflight, were promoted/published on `origin/main`, implemented, reviewed, corrected and independently re-reviewed PASS. **Do not reauthor or re-claim C1**. For later C2 implementation pairs, the same preflight/index/publication gates still apply *after* F15 geography/residency decisions are locked; this planning refresh does not bypass them.

## F14-C1 accepted; production F14-C2/F15 boundary refresh (2026-10-09)

[Full cross-system planning contract](../F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md) · [F14-C1 correction summary](../../../LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md) · [fresh independent passing re-review](../../../REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md).

**Actual verified milestone:** one real `enemy_grunt.tscn` transitions physical→abstract→physical on **explicit synthetic Domain/Location requests** with stable `ActorId`/`GroupId`, non-default supported behavior intent, 39/78 health, exclusive fixed-boundary ownership, deterministic 60-tick offscreen progression, successful repeated return and snapshot restore. Fresh reviewer confirmed **R0-01/02/03 fixed, no new findings**; five focused smokes passed, independent replay matched and a physical-ownership-bypass mutation failed at the intended assertion. `AbstractActivitySimulationState` is now schema **v2** with compatible v4/v5 WorldSimulation snapshot handling; raw original-v5 payload fingerprint is checked before migration. These are reviewed agent-run results, not tests performed by this documentation editor.

**C1 scope ceiling:** `ActorReificationCoordinator.bind(kernel, anchors)` currently uses an explicit **location_id → live Node2D anchor** lookup and explicit request calls. It does **not** resolve a durable production Domain/Location descriptor, attach to actual scene residency, reserve ambient spawn slots, or implement multi-actor/camp ownership. The M6 procgen chunk residency policy evicts painted presentation/cache only; it must never be treated as Enemy unload authority. `RouteTraversalManager` is a scene-route transition owner, not a domain geography registry. This separates *working synthetic actor handoff* from *unbuilt automatic locality residency*. The smoke's old `defend_relay` goal string was not a supported behavior lookup; the independent reviewer repeated supported `harass_player` to prove intent conservation. Use supported behavior profiles/goals in future acceptance fixtures.

**Production contract still requires explicit approval:** (a) stable real `(domain_id, location_id)` resolution, physical scene/site residency and validated safe spawn anchors; (b) camp/spawner managed ActorId reservations, cancellation/reconciliation of queued spawn slots and no duplicate actor generation; (c) transactional real locality unload/reentry into the **already accepted** C1 simulation authority; and (d) F15 measurable connected travel and later REMAP-3 restart durability. Prioritize F15-A evidence before any production C2 implementation packet. **C2/F15-A/B/C are planning slots, not claimable workstreams** and this design refresh is not a world topology lock.

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

CS-F14-A baseline audit evidence is satisfied. **CS-F14-B is implemented/landed** as domain/location/group state, 60-fixed-tick kernel stage, v5 snapshots with v4 migration and a synthetic uninstantiated-location smoke. The first independent review found blocking **R0-01**; the landed correction uses unambiguous length-prefixed causal event IDs while reading legacy schema-v5 event IDs. **The correction's independent fresh-context re-review has PASSED**, so B is accepted. B itself is the state-only foundation; a subsequent independent C1 real-Grunt synthetic actor handoff now landed and passed correction re-review. **Only C2 production binding**, geography/map integration, combat consequences and REMAP-3 disk persistence remain gated.

- [CS-F14-A: read-only authority/interest/handoff baseline](PACKET_ROADMAP.md#cs-f14-a) (evidence satisfied; no duplicate packet)
- [CS-F14-B: deterministic abstract geographic-group activity](PACKET_ROADMAP.md#cs-f14-b) ([implementation archived](../../../custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md), [first review archived](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md), [R0-01 correction archived](../../../custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1.md), [fresh correction re-review PASS](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1.md))
- [CS-F14-C: C1 real-Grunt handoff accepted; C2 production geography/spawner residency pending](PACKET_ROADMAP.md#cs-f14-c) ([C1 correction re-review passed](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1.md))
- [CS-F14-D: persistent history, save/restore and world consequence reconciliation](PACKET_ROADMAP.md#cs-f14-d) (proposed)
- [CS-F14-E: two-sector playable proof, instrumentation, soak and integration closeout](PACKET_ROADMAP.md#cs-f14-e) (proposed)

**A's baseline is satisfied and B is independently accepted after its R0-01 correction.** C1's synthetic one-Enemy actor ownership proof is independently accepted; real automatic population/streaming hookup still requires the F15 geographic location/streaming owner and F04 spawn reservation policy. D consumes REMAP-3 rather than duplicating persistence. Do not expand C1 or auto-authorize full C2/D/E.

## Decision lock record

- **Audit result:** baseline characterization complete with six agent-reported focused PASS checks; synthetic offscreen group activity and causal event/snapshot progression were implemented and tested in F14-B, then R0-01 was reproduced/fixed. **Synthetic real-Grunt physical/abstract handoff and strict absence of physical callbacks have now been proved in C1; production geographic/residency binding, multi-member lifecycle and restart durability are still unproven.**
- **Selected owner/seam:** F14 V1 boundary **LOCKED** below: `WorldSimulationRuntime`/`SimulationKernel` authoritative time and macro commands; a focused activity-state owner scoped by stable synthetic geographic keys; interest manager classifier only; loaded enemies own loaded combat. Real reification adapter and persistence schema remain later decision gates.
- **Design approval:** user explicitly approved **Bounded** offscreen consequences and continuous-geography target (October 9, 2026). F14 V1 adopts authoritative fixed-tick cadence, group-level abstractions with optional stable individual identity and bounded non-physical event types as engineering defaults. Real map identity schema, physical reification, casualty semantics, full restart state and UI reporting await later locks.
- **Preserved contracts:** 60Hz fixed step, kernel macro ordering, loaded physical gameplay, one runtime authority, canonical procgen and campaign identity.
- **Document drift:** interest tier behavior mismatch recorded and descriptive implementation notes reconciled in `design/01_systems/INTEREST_MANAGEMENT_SYSTEM.md`; further gameplay policy changes remain unapproved.
- **Implementation decision:** **F14-B implemented/archived and independently accepted after R0-01 corrected re-review PASS on `main@7d9fe1872361`.** Narrow F14-C1 real-Enemy synthetic two-location handoff proof **implemented, corrected and independently re-reviewed PASS** (R0-01/02/03 fixed, no new findings). **C2 production residency/spawner binding, D REMAP-3 and E playable integration remain unapproved.** Next: F15-A actual geographic owner/scale evidence and an explicit stable Domain/Location contract decision before authoring C2.
