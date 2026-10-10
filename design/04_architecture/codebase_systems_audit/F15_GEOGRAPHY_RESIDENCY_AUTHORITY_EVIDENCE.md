# F15-A — Geography and Residency Authority Evidence

**Status:** evidence report; architecture recommendation is provisional
**Source snapshot:** `6d66c1696596e2a8646a56e7de986dc70bbac02e`
**Proof date:** 2026-10-10 (UTC)
**Runtime:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`, Linux x86_64
**Scope:** read-only audit. No geographic identity, residency, spawn, or travel behavior was added.

Labels in this report mean: **CONFIRMED** = source contract; **MEASURED** = executed deterministic evidence; **INFERRED** = proposed interpretation or consequence; **NOT PROVED** = absent or untested.

## Findings

1. **CONFIRMED — there is no durable production `DomainId + LocationId` address.** F14 abstract activity accepts bounded string domain/location IDs, but F14-C1's reification coordinator receives caller-provided `location_id → Node2D` anchors. No live registry maps campaign route nodes or generated regions into those anchors.
2. **CONFIRMED — the existing residency owners are separate.** `RouteTraversalManager` and `LevelLoader` stage, activate, deactivate, cache, restore, roll back, or free *whole scene nodes*. M6 chunk residency unloads painted/presentation cells only. Neither currently owns F15 locality residency or actor population.
3. **MEASURED — two production contract seeds create connected local maps.** Seed `12345` accepted attempt 3/4 at `224×192`; seed `54321` accepted attempt 0/12 at `208×192`. Their measured candidate reachable components are 8,900 and 9,344 cells respectively. These are individual local maps, not a demonstrated traversable settlement-to-settlement world.
4. **MEASURED — a production ambient-spawn fixture is blocked by required ingress generation.** In the seed `12345` smoke, the first three candidates were rejected for `required_world_ingress`; the fourth was accepted, but the loader's Ritualant underground ingress requirement failed and runtime activation/spawning did not occur. A second fixed-seed probe (`54321`) reproduced the loader rejection after moving the contract map into the expected `GameRoot/World/ContractMap` hierarchy. This is a current generated-content/fixture limitation, not proof that all regions fail.
5. **INFERRED — a finite/expandable graph of stable locations with deterministically generated local regions best preserves current local generation while giving F14 and campaign travel an addressable seam.** This is a candidate, not a scale or architecture lock.

## Identity and ownership matrix

| Namespace | Current owner and format | Lifetime / persistence | Collision and F15 relationship |
|---|---|---|---|
| `DomainId` | `AbstractActivitySimulationState`; caller-supplied valid string (1–64 ASCII alphanumeric, `_`, `-`, `.`) | Snapshot-serialized abstract state; no production campaign-domain registry | **CONFIRMED:** F14 state namespace only. No mapping from campaign/world route exists. |
| `CampaignVisit` | No class or field found in active campaign state | **NOT PROVED:** no visit identity to persist/restore | `CampaignSession.session_id` hashes `scenario_id|seed`; it identifies a deterministic session, not an individual visit to a place. |
| Region profile / seed | `CustodianContractMap`, profile and deterministic contract/map seeds | One generated contract/runtime map; seed can reproduce input, but no durable visit address | A seed identifies generation provenance, not necessarily a unique campaign locality. A profile label alone is not unique. |
| `route_id + node_id` | Route registry/definition and in-memory `RouteSession` | Session node/history/state; node state can reset, remain in session, or enter route state store according to lifecycle policy | Route-scoped graph topology. Same node IDs may occur in separate routes; not a global location ID. `@world_origin` is a route sentinel. |
| `level_id` | Level registry/definition and `LevelLoader` | Definition identity; loaded instance is active, cached, or freed by lifecycle policy | Identifies a scene/runtime definition. It does not identify a campaign visit or geographic address. |
| Physical `Sector` | `game/actors/sector/sector.gd`; scene node exports `sector_name`, `sector_type`, tile size | Scene instance; no global geographic persistence contract | Distinct from infrastructure macro sectors. Names/types can repeat between scene instances. |
| Infrastructure/macro sector | `WorldIdentityContract` IDs (`COMMAND`, `POWER`, `COMMS`, `DEFENSE_GRID`, `FABRICATION`, `ARCHIVE`, `STORAGE`, `HANGAR`, `GATEWAY`; transit IDs) | Base/world simulation namespace and scene identity mapping | These name base sectors/transits, not outdoor localities. `DEFENSE` maps to `DEFENSE_GRID`; transit scene IDs map to `T_NORTH`/`T_SOUTH`. |
| Procgen chunk coordinate | `ProcGenTilemap._tile_to_chunk`, integer `Vector2i` divided by `streaming_chunk_size_tiles` (default 16) | Runtime presentation/cache address within one tilemap | Coordinate is map-local and lacks map/domain identity. M6 eviction affects painted chunks, not semantic world cells, actor life, collision, or navigation. |
| F14 `GroupId + ActorId` | `AbstractActivitySimulationState`; caller-supplied strings scoped by `DomainId`; actor may be empty in legacy-compatible records | Deterministic snapshot state and fixed-step transitions; duplicate claims rejected within state/domain | Stable abstract identity, but no production map to a physical locality. Group key uses `domain::group`; causal event IDs are length-prefixed, preserving valid dotted IDs. Do not reuse local scene/chunk IDs as actor IDs. |

**INFERRED candidate only:** a durable address needs an explicitly versioned, canonical `(domain_id, location_id)` key, with region profile/seed and route/node/site kept as provenance or topology references. Do not concatenate unescaped dotted IDs using a delimiter: F14's accepted collision-safe precedent is length-prefixing. Identity canonicalization, domain scope, visit semantics, and seed evolution still require a design decision.

## Physical scene lifecycle and visual chunk lifecycle

### Route/level scene authority — CONFIRMED

`RouteTraversalManager.start_route` resolves route/profile and the entry edge. `transition_via_edge` checks the enabled edge, source node, and active route actor, then enters the configured transition. The transition path validates/stages the target, restores route state according to the target lifecycle policy, and delegates activation to `LevelLoader.commit_staged_level`. For generated regions, `stage_level_async` prepares a generated level before commit; a staged instance starts deactivated. Commit captures source activation and actor position, deactivates the source, activates target and actor spawn, then records active level authority. If activation fails, it deactivates the target, reactivates the source and restores actor position. Route-level `_rollback` also clears target loader authority, frees a newly staged target, reactivates/restores the source, rebinds exits, and unlocks the actor.

On successful exit, `_capture_node_state` obeys `reset_on_entry`, in-session state, or the route state store's persistent policy. `_apply_source_policy` either keeps a deactivated instance in `RouteSession.cached_instances` or calls `release_level_instance`, which may keep it disabled or queue it free. Return-to-world is handled by the active level's origin ingress or `_restore_origin_without_ingress`; failed restore reactivates the level. These are physical scene-node ownership operations and route-owned state restoration; they do not define a persistent geographic locality or restore a campaign visit.

`generated_region_route_lifecycle_smoke.gd` **PASS** (headless). It exercises a generated-region route stage/transition/return path and failure rollback. The deliberate invalid generated dependency prints expected errors before rollback; this is fixture evidence, not a clean production ingress proof. `procgen_region_frame_smoke.gd` **PASS**. The ambient real-world integration attempt is separately recorded below.

### M6 chunk/presentation authority — CONFIRMED

`ProcGenChunkResidencyPolicy` selects chunks by local coordinate, distance, hysteresis and protection. `ProcGenTilemap._unload_chunk` notifies the presentation/reveal layer and removes painted presentation for that coordinate. The semantic map and its collision/navigation authorities remain owned by the loaded `ProcGenTilemap`; this is not unloading a world location or transferring actors. `procgen_distant_chunk_unload_smoke.gd` **PASS** for direct seed `20261001`, map `72×72`, `32 px` cells, 564–588 runtime walkable tiles as its run log reports. `procgen_region_frame_smoke.gd` **PASS** with generated map seed `4134149008`.

**NOT PROVED:** camera interest, visibility, or M6 presentation cache is not a valid trigger for F14 abstracting/reifying actors. F14 transitions are processed by `ActorReificationCoordinator._on_fixed_step_boundary`; F15 must call an explicit location lifecycle contract if actor authority is to follow geography.

## Ambient spawn race and minimal future seam

**CONFIRMED current spawn path:** `AmbientEnemyCamp._process` checks player distance against `activation_range_px` (default 650). `spawn_camp` chooses a deterministic quota from `camp_id`, caps by active plus pending spawns, resolves walkable/separated positions, and calls `AmbientEnemySpawner.queue_enemy_spawn`. The queue stores scene, parent, positions, camp ID, behavior, completion callable, and a process-local ordinal. `_physics_process` pops one request per physics frame. `_spawn_queued_enemy` resolves a walkable point, instantiates an enemy, attaches only `stable_spawn_ordinal`, adds it to the world parent, then invokes the camp completion callback. The camp callback configures behavior/ownership and advances its queued-or-spawned count. It does not claim F14 `ActorId` or `GroupId`.

| Interleaving | Current disposition | Future managed-slot seam (proposal; not implemented) |
|---|---|---|
| Camp queues a generic spawn at locality A; locality unload begins before queue drain | Request retains a valid world parent and can instantiate after the locality transition; no locality generation token/cancel authority is in the request | Before camp activation, ask a locality population-slot authority to reserve `(DomainId, LocationId, GroupId, ActorId)` or unmanaged slot. Cancel/reject pending locality-bound request when its lease is retired. |
| Abstract actor `A/G/actor-1` is at A; returning physical scene is activated while camp has a generic slot queued | Generic spawn has no F14 identity, so both an F14 actor projection and a newly instantiated ambient enemy may appear. Reification's same-actor ownership check cannot match an enemy without those identity fields | Reservation is the single arbiter. Returning actor claims/reuses its slot before camp queues; the camp callback must settle exactly that reservation, and activation fails closed on conflicting physical ownership. |
| Unmanaged camp spawn with no F14 slot | Existing capped camp behavior | Preserve current path, quota, cap, and completion callback for unmanaged population. |

**INFERRED:** a reservation/cancellation seam is sufficient to serialize managed identity against queued ambient creation without making the camp, scene cache, or spawner the durable population owner. Specify lease expiry and rollback before implementation; no actor duplication was observed in current production because this address/reservation integration does not yet exist.

## Fixed-seed local scale and movement evidence

The tests used the current `CustodianContractMap` production contract generation with fixed seeds. The contract profile may choose dimensions inside its exported 160–224 candidate bounds; accepted extent is measured from the selected runtime map. The candidate evaluator reports flood-filled semantic reachability. Pixel extents below use the observed 32 world-unit tile scale. Connected component size is not a geodesic route length.

| Contract seed | Selected region / planet seed | Accepted candidate and map seed | Runtime size and pixel bounds | Spawn and measured reachable component | Route/camera/travel disposition |
|---:|---|---|---|---|---|
| `12345` | `islands` / `17539747` | attempt `3/4`; `3348751998` | `224×192` cells; `7168×6144 px` | spawn `(112,180)`; `8,900` reachable cells; connected ratio `1.0`; rooms `35/35`; ingress `3/3`; terrain connectivity true; runtime floor `9,474`, walls `820` | Local evaluator connectivity measured. Full-width straight-axis bound is `7,168 px` (`224` cells); at measured synthetic Operator rate below this is a **projected** `49.0 simulation seconds`, not a walked route. No two-site route; landmark-in-camera coverage **NOT MEASURED**. |
| `54321` | `terran_wet` / `222523091` | attempt `0/12`; `3249619757` | `208×192` cells; `6656×6144 px` | spawn `(104,180)`; `9,344` reachable cells; connected ratio `1.0`; rooms `36/36`; ingress `3/3`; terrain connectivity true; runtime floor `9,963`, walls `1,047` | Local evaluator connectivity measured. Full-width straight-axis bound is `6,656 px` (`208` cells); at measured synthetic Operator rate below this is a **projected** `45.5 simulation seconds`, not a walked route. The real loader fixture rejected required world ingress, so activation/travel are **NOT PROVED**. No two-site route or landmark-in-camera coverage was measured. |

The generated map is roughly `6.7–7.2 km` wide only if one interprets one world pixel as one physical centimetre; the project defines no such real-world conversion, so this report makes no physical-distance claim. The reliable units here are game pixels and 32-pixel cells.

**Operator movement observation:** a temporary headless probe instantiated the real Operator scene and supplied its supported external-control input frame for 180 physics ticks in an unobstructed empty `Node2D`. It traveled `439.33 px` over 3 nominal fixed seconds (`146.44 px / nominal simulation second`); wall time was `2.975 s`, giving `147.69 px / wall second`. The final surface multiplier was `1.0`. This is a measured controlled walk on empty geometry, not an observed route over either generated map. The two map-span times in the table divide pixel width by the measured nominal rate and are clearly projections; connectivity and usable edge-to-edge paths were not measured by that probe. Operator source baseline remains `SPEED = 150 px/s` before sprint, sneak, combat, status and surface multipliers. The field Scout class smoke **PASS**; its `ground_wheeled_light` profile configures max speed `175 px/s`, acceleration `420`, reverse multiplier `0.45`, and off-road multiplier `0.78`. Scout speed is configured, not route-traversal measured. The production `game.tscn` places its camera at `(720,-480)` and project viewport is `1280×720`. `CameraController.base_zoom` is `(0.84,0.84)` and `move_zoom` is `(0.90,0.90)`, yielding nominal visible rectangles about `1524×857 px` and `1422×800 px` respectively before state/aim zoom and framing offsets. Those are configuration-derived bounds, not observed landmark coverage. No supported current fixture loads two campaign locations as a continuous traversable route, so seam travel and camera visibility remain **NOT PROVED**.

### Validation receipts

| Command / fixture | Result | Boundary |
|---|---|---|
| `godot --headless --path custodian --script res://tools/validation/generated_region_route_lifecycle_smoke.gd` | **PASS** | Generated scene stage/return and rollback fixture; deliberately emits invalid-dependency errors for negative path. |
| `godot --headless --path custodian --script res://tools/validation/procgen_region_frame_smoke.gd` | **PASS** | Fixed-seed region generation/semantic frame; run seed `4134149008`. |
| `godot --headless --path custodian --script res://tools/validation/procgen_distant_chunk_unload_smoke.gd` | **PASS** | M6 visual chunk eviction, seed `20261001`; semantic walkability remains available. |
| `godot --headless --path custodian --script res://tools/validation/procgen_ambient_enemy_real_world_spawn_smoke.gd -- --seed=12345` | **FAIL** | Candidate attempts 0–2 rejected on required ingress; attempt 3 accepted, then generated contract activation failed because the required Ritualant underground pocket had no canonically connector-resolvable authored pocket within 65 deterministic candidates. The original harness also first lacked the expected `GameRoot/World/ContractMap` owner. A temporary corrected hierarchy replay reproduced the ingress failure for seed `54321`; see report limitations. |
| Temporary `f15_audit_contract_metrics_probe.gd`, `--seed=12345` | **MEASURED** | Same four candidate attempts and accepted generated map; metrics table above. Temporary, untracked probe removed before closeout; command shape and source fixture are reproducible from the production smoke after adding metrics-before-loader. |
| Temporary `f15_audit_ambient_spawn_probe.gd`, `--seed=54321` | **MEASURED / loader FAIL** | Corrected hierarchy probe produced metrics and reproduced required-ingress rejection. Temporary, untracked probe removed before closeout. |
| `godot --headless --path custodian --script res://tools/validation/world_simulation_actor_reification_handoff_smoke.gd` | **PASS** | F14 actor physical/abstract fixed-boundary ownership; synthetic anchors only. Expected no-navigation warnings in fixture. |
| `godot --headless --path custodian --script res://tools/validation/vehicle_field_scout_class_smoke.gd` | **PASS** | Scout registration/profile/class contract, not geographic traversal. |
| Temporary `f15_audit_operator_walk_probe.gd` | **MEASURED** | Real Operator scene with 180 successive external-control rightward frames in an empty `Node2D`; observed distance/timing above. The temporary harness is removed before closeout. |

## Architecture options

| Option | Evidence-grounded benefits | Costs / unresolved facts | Status |
|---|---|---|---|
| 1. Enlarge the existing finite map (control) | Current generator creates connected finite local maps and stable seeded output. No new address graph needed for a single loaded map. | Larger generation cost, memory, navigation/collision and camera envelope scale together; it does not itself define visits, reentry, remote actor state, neighboring locality seams, route ownership, or durable locations. Current 208–224 by 192 accepted fixtures show that accepted size is profile/candidate dependent, not a chosen world scale. | **MEASURED** local map bounds; seamless campaign geography **NOT PROVED**. |
| 2. Finite/expandable graph-backed Domain locations with deterministic local materialization | Gives each locality a stable address and explicit adjacency/travel graph while retaining current local map generation, stage/rollback, and F14 abstraction boundaries. Can define finite authored hubs plus deterministic reachable frontier without an unbounded coordinate plane. | Requires canonical IDs, visit/seed policy, route-to-location mapping, compatible roads/water/pass seams, atomic residency and spawn reservation, save/restart policy, map-generation failure fallback, and lore-approved connectivity. Graph traversal is not automatically continuous play. | **INFERRED provisional fit**, pending decisions and playable two-site proof. |
| 3. Unbounded procedural coordinates | Natural coordinate addressing and potentially continuous procedural expansion. | No active generator owns global coordinates, deterministic neighbor seams, bounded memory, rollback, persistence, reentry, actor lifecycle, vehicle routes, or campaign/lore constraints. Coordinate hashes alone do not guarantee connected roads or repeatable authored sites. | **INFERRED high integration cost; NOT PROVED by current code.** |

Measured tests constrain local generation and current residency responsibilities only. Memory/performance costs of larger maps, graph expansion, or infinite coordinates were not benchmarked; no performance ranking is asserted.

## Candidate address and staged residency contract (proposal only)

```text
GeographicAddress {
  address_schema, domain_id, location_id,
  region_profile_id, generation_seed, route_id?, route_node_id?, site_id?,
  provenance_version
}
```

`domain_id/location_id` are the stable key; route, profile, seed, and site are validated provenance/topology, not alternate identities. Use canonical components and a collision-safe encoding at persistence boundaries. A visit/session ID is separate from a location ID.

Candidate owner boundaries:

1. **F15 geography authority** resolves address and adjacency; accepts `request_residency(address)` and returns a versioned staged handle, never a live actor.
2. **F02 level/scene authority** generates or loads a local physical scene into an inactive staged handle, validates declared ingress/spawn and seam metadata, then activates or rolls back the scene atomically. It owns scene nodes and geometry.
3. **F14 simulation authority** at a canonical fixed-step boundary transfers each actor exactly once between its physical instance and abstract record, preserving `ActorId`, health/condition, objective and route state. It rejects ambiguous/missing locality mappings.
4. **F04 spawner authority** consults/releases managed population reservations before queuing local ambient spawns; unmanaged slots keep existing quota/cap behavior.
5. **M6 presentation** may reveal/evict painted chunks but never triggers locality or actor transfer. REMAP-3 remains the future disk-persistence owner.

Fail-closed invariants: one authority per actor; one committed residency per locality key; no actor spawn before reservation; source stays valid until target stage/validation succeeds; on any target activation or F14 transfer failure restore source authority and actor state; canceled staged handles cannot later commit; reentry resolves the same stable address and deterministic provenance; no camera/cache event advances simulation or changes actor authority.

## Decision agenda and ordered handoff

Named decisions that must be recorded before implementation:

- **D1 — Domain and visit identity:** campaign/domain scope, canonical location IDs, `CampaignVisit` lifetime, and whether a deterministic seed is location provenance or visit input.
- **D2 — Geography extent and scale:** finite authored set versus expandable frontier; player-facing distance unit/interpretation; minimum locality/road scale. Do not infer kilometers from pixels.
- **D3 — Continuity contract:** whether locality edges must be walked continuously, how road/water/elevation seams align, and which hub/Port routes are lore-constrained. No teleport-only route may stand in for a missing seam.
- **D4 — Residency and rollback:** staged scene ingress validation, safe actor anchors, failure behavior, caching/destruction policy, and when F14 transitions occur relative to scene commit.
- **D5 — Managed population:** stable slot ownership, pending request cancellation, camp quotas, and behavior when an abstract actor returns while its camp is active.
- **D6 — Persistence boundary:** which address/visit/actor records eventually belong to REMAP-3; no second save silo in F15.
- **D7 — Vehicle evidence:** defer long-route Scout/vehicle traversal and handling claims to F09 plus the later F15 playable geography proof.

| Order | Follow-up | Entry evidence / gate |
|---|---|---|
| 1 | F15-B deterministic geographic identity/materialization | Decide D1–D3 and specify stable address/provenance plus neighbor-seam generation contract. |
| 2 | F14-C2a managed population slot | Use chosen address as population reservation key; specify cancellation and reentry race tests (D5). |
| 3 | F14-C2b physical locality event binding | Bind actual physical locality transitions to F14 at fixed-step boundaries (D4), with rollback and uniqueness tests. |
| 4 | F15-C continuous two-site playable proof | Demonstrate accepted neighboring locations, walkable seam, measured Operator journey, camera landmark coverage, return/reentry and duplicate-free actors; perform vehicle route proof under F09/F15 later (D7). |

**Recommendation:** proceed toward option 2 only after D1–D6 are explicitly locked and the generated-ingress failure is dispositioned by its owner. F15-A establishes evidence; it does not authorize a generator, API, numeric scale, or world-topology implementation.

## Evidence limitations

- Full reproduction runs are expensive (multi-minute contract candidate generation). Captured metrics came from temporary uncommitted probes; their source changes were removed. The existing smoke command is reproducible but does not print the full metrics row.
- The two generated seeds measure candidate-local connectedness, not route length through a player-usable path network. No multi-location production route or operator movement-duration harness exists in the tested fixture, so elapsed travel and seam camera visibility remain **NOT PROVED**.
- Ambient contract smoke did not spawn enemies because the actual loader rejected required authored underground ingress. It cannot establish current spawn success/frequency for those generated contracts. The source interleaving above is code-path analysis, not an observed duplicate.
- Scout smoke establishes profile registration only. No Scout was driven across a generated route.
- Expected fixture warnings include generated-region rollback errors, missing navigation for synthetic Grunt actors, and Godot object/resource leak diagnostics at process exit. Focused smoke exit codes and PASS markers were zero/green except the ambient integration smoke (exit 1).
