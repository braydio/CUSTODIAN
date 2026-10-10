# F14-C2 / F15 · Production Geographic Identity and Physical Residency Planning Refresh

**Status:** planning/evidence design, **NOT a production architecture lock or claimable implementation packet** · 2026-10-09  
**Planning workstream:** `f14-c2-f15-production-residency-planning`  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31  
**Evidence:** live `braydio/CUSTODIAN` main at `76bd0946bfee6d703e5c56950e6664afb8b572b0`; [F14-C1 correction re-review](../../REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md) and [corrected implementation summary](../../LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md).

## Decision boundary: what is already accepted

- **F14 V1:** bounded deterministic abstract offscreen group activity owned by `WorldSimulationRuntime` and `SimulationKernel`; no second clock, no invisible physics combat or independently mutated supplies.
- **F14-B:** synthetic group activity, causally named deterministic events, snapshot schema v5 and compatibility. Length-prefixed event IDs avoid dotted identity collisions.
- **F14-C1:** a real Grunt transfers physical → abstract → physical on explicit synthetic-location requests, with one stable ActorId/GroupId, conserved health/intent, actual node removal/reentry, guarded fixed-boundary transactions, deterministic replay and state snapshot compatibility. Its **independent cycle-1 re-review PASSED**, with R0-01/R0-02/R0-03 fixed and no new findings. Corrected coordinator accepts only the supported Grunt, not an arbitrary actor family. The original committed C1 smoke uses `defend_relay` as a nonrecognized goal; independent reviewer additionally proved the full flow with supported `harass_player`. Use a supported goal in future production fixtures.
- **F15 player experience:** continuous traversable terrain in one Campaign World/visit, a meaningful Historical City/Hub → Muster Court Continuity Port deployment, ordinary passes as geography rather than mandatory scene-cut teleports; vehicles and Ports are important travel systems. Global geography extent, materialization, topology and production residency are **not yet locked**.

**Acceptance boundary:** C1 proves an explicit **one-Grunt test seam**, NOT real geographic identity, automatic cell eviction, ambient camp slot reconciliation, multi-actor groups, disk persistence, vehicle/foot continuity, or world-scale streaming.

## Live-source ownership and constraints

| Area | Current actual owner | C2/F15 consequence |
| --- | --- | --- |
| Abstract authority | `custodian/game/state/world/abstract_activity_simulation_state.gd` v2 and `custodian/game/systems/simulation/simulation_kernel.gd` | Preserve authoritative fixed ticks, exclusive representation and canonical snapshot state. Do not create another actor ledger or clock. |
| Physical handoff | `custodian/game/systems/simulation/actor_reification_coordinator.gd` | `bind(kernel, anchors)` takes a **location_id-keyed live Node2D anchor dictionary**; requests are caller-driven. Production must resolve composite Domain/Location identities through an actual geographic residency owner and revalidate placement. Avoid passing stale Node pointers as persistent state. |
| Spawn queue | `custodian/game/systems/spawning/ambient_enemy_spawner.gd` | Asynchronous `_spawn_queue`, local `stable_spawn_ordinal`, spawn parent; no persistent ActorId reservation/restore path. Spawn ordinal is not identity. |
| Camps | `custodian/game/systems/spawning/ambient_enemy_camp.gd` | Near-player activation and `_spawned_enemies` / `_queued_or_spawned_count` bookkeeping can independently recreate local populations. Re-entry MUST reconcile logical slot reservations before invoking the spawner. |
| Visual cache residency | `custodian/game/world/procgen/streaming/procgen_chunk_residency_policy.gd`, `procgen_chunk_lifecycle.gd` | M6 unloads **painted presentation / derived cache**, not actors or persistent world data. **Never** trigger F14 actor handoff solely from an M6 DORMANT/UNLOADED transition, Archive Resolve or interest-tier distance. |
| Route scene lifecycle | `custodian/game/world/routes/route_traversal_manager.gd`, `custodian/game/world/levels/generated_region_level.gd` | Route transitions already stage/activate/deactivate real level nodes. Their `route_id/node_id` and generated `profile_id/seed/map_size/room_count` are **not automatically stable Lattice Domain/Location identities**. Review any mapping, cleanup and rollback before composing geographic residency. |
| Finite procgen | `custodian/game/world/procgen/custodian_contract_map.gd`, `proc_gen_tilemap.gd` | The generation target is a finite locally accepted map (typical candidate bounds 160–224 semantic cells); visual chunk streaming is not production macro-world streaming. |
| Campaign | `CampaignSession`, `WorldSimulationRuntime`, Hub/WorldTransition/RouteTraversal systems | One active campaign outcome and existing Operator/vehicle ownership; geographic materialization cannot create independent campaign sessions. |
| Disk persistence | REMAP-3 existing campaign-persistence program | Reuse its eventual disk save authority; snapshot-memory acceptance ≠ disk restart proof. |

## Proposed contract for F15 and F14-C2 (requires architecture approval)

### A. Stable geographic address and separation of concerns

- **DomainId:** durable Lattice Domain identity, not a generated Contract, temporary CampaignVisit or scene.
- **LocationId:** unique within a Domain, durable across unloading, revisits, and a regenerated physical presentation. Represents a **real geographic site or bounded locality** independent of tile chunks, sector infrastructure labels, scene paths or route graph node names.
- **RegionId / geographic adjacency:** graph/topography context to locate sites, routes and plausible intervening terrain. Region-to-location relation may be many-to-many for biome/political layers; do not force territory and ecology into the location namespace.
- **GroupId, ActorId:** stable domain-scoped F14 identities; they reference a LocationId but do not incorporate it, so actors may travel while retaining identity.
- **CampaignVisit/session:** contains current active world/contract, accessibility, route history, entry/exit and Operator state. It **references** Domain geography rather than minting a new geological world every visit.
- **Loaded scene/chunk/route node:** disposable physical *representation* tied to an accepted geographic address through an explicit mapping, not the key of the address itself.
- Use structured address fields or an injective length-prefixed compound codec. Do not join user-valid dotted identifiers with plain dots. Preserve `AbstractActivitySimulationState` ID grammar and backwards-compatible snapshot reads.

**Do not encode a new globally authoritative Site registry in F14.** F15/F02 geometry/geographic owners publish the canonical `(domain_id, location_id)` mapping; F14 consumes it and owns abstract simulation consequences only.

### B. Real locality residency API, independent of visual chunks

A future **single geographic residency authority** should expose a small read-only/query and explicit intent interface, conceptually:

```text
resolve_location(domain_id, location_id) -> immutable descriptor
get_residency(domain_id, location_id) -> absent | staging | resident | evicting
request_resident(domain_id, location_id, reason) -> transaction/result
request_absent(domain_id, location_id, reason) -> transaction/result
get_safe_actor_entry(domain_id, location_id, actor_class, preferred_anchor) -> approved finite, navigable anchor or rejection
```

This describes the *contract*, not compulsory class names. Residency is a semantic physical actor/scene boundary. It is **not** `ProcGenChunkLifecycle.State`, not camera visibility, not distance-tier dormancy and not Archive Resolve. Staging must know the real locality geometry and safe entry anchor before asking C1's coordinator to reify. The gameplay scene and authoritative actor may continue resident while an M6 presentation chunk is unloaded.

At a canonical simulation fixed-step boundary, coordinate **commit or rollback** with F14: (1) validate complete stable address and group location, (2) reserve exactly one logical population slot, (3) ensure no pending spawn/camp request can race, (4) stage safe node/inert Grunt or stop and remove the live actor, (5) commit exclusive F14 physical/abstract ownership **once**, (6) release/clear requests and record causal result. Failure leaves the previous owner authoritative and retains/pins any still-live scene; never silently delete a combatant because the player moved away.

### C. Population/encounter reservation contract

One **logical member slot** is keyed by durable DomainId + GroupId + ActorId, with association to a currently occupied LocationId and spawn-source/camp provenance. The already-authoritative F14 group projection is truth for an F14-managed actor's identity and condition. Camp/spawner owns physical scheduling/scene construction and per-camp quotas, **not a second strategic actor history**.

For an F14-managed slot: register/claim before camp activation; suppress/cancel/reconcile any pending ambient spawn for that slot; restore only when its actual geographic location is resident and a safe entry is available; do not count reification as a new random spawn; no respawn from the old marker when the same durable ActorId is abstract elsewhere. Unmanaged ambient enemies retain current behavior. Keep camp counts/caps and marker deduplication correct; avoid broad `enemy.gd` changes.

If active attack, pending damage/projectile/nav work, loot-bearing corpse, stolen resource custody, unsupported species, absent safe geometry, unresolved spawn request, player in immediate combat area, or contradictory session/location is present, **fail closed/pin physical residency**. Later policies may add specific resolutions; none are authorized by this refresh.

### D. Geographic strategy alternatives and choice to lock later

| Architecture | Benefit | Main risk | Disposition |
| --- | --- | --- | --- |
| One larger full-map TileMap | Minimal new topology owner initially | Still finite one-map architecture, heavy generation, weak distinct settlements/seams | **Do not select** as the primary geographic foundation |
| **Finite Domain topology graph + deterministically materialized localities** | Stable geographic identity, authored/generated compatibility, tractable persistent roads/sites and residency | Requires topology, seam/coordinate and locality mapping work | **Preferred design hypothesis**, pending measured F15-A evidence and explicit lock |
| Unbounded procedural coordinate world | Expandable theoretical extent | Major seam, perf, navigation, persistence, content identity and lore costs | Not justified by the currently locked player experience |

A graph-backed finite accessible footprint can satisfy continuous travel if the route terrain is genuinely traversable and player-facing transitions are seamless. It must not devolve into a menu of disconnected local levels with mandatory cutscenes. Do not prescribe map kilometers or cell counts before travel/camera/vehicle measurements.

## Falsifiable acceptance and negative cases for future production integration

1. Two **real** named locations in one accepted Domain/campaign with stable IDs and explicit adjacency/coordinate/road relations, not just synthetic A/B test anchors.
2. Locality A can be genuinely physically vacated while B remains represented, and the same stable abstract group continues at canonical fixed ticks with causal history. M6 visual chunk eviction alone does **not** flip its representation.
3. Returning to the group's **current** valid location restores precisely one real Grunt, with ActorId/GroupId, health and supported goal conserved. Returning to an old location after abstract travel does not materialize the actor at the wrong site.
4. Two departures and reentries, route/cache unload/reload and snapshot/restore produce no duplicate/phantom/forgotten actors, spawn-queue entries or camp slot drift. Failed reservations, unsafe anchors, missing generated source, edge-trigger races and active combat all leave state valid and recoverable.
5. F14 deterministic hash/replay and v4/v5 legacy snapshot compatibility stay green; geographic/spawn remapping is versioned if it changes canonical state. No duplicate disk persistence owner.
6. Camera, collision, navigation, Operator and campaign session remain intact across actual source/target lifecycle. Ultimately demonstrate a meaningful walkable road/wilderness journey between distinct sites; test vehicle travel separately using current F09 owner once dependencies permit.
7. Validate failure rollback, re-entry from true process restart once REMAP-3 supports it, and benchmark occupied/abstract population and load duration before fixing production density/stream budgets.

## Recommended packet roadmap (design slots, not yet executable)

| Slot / suggested workstream | Sole primary owner and output | Depends on | Gate |
| --- | --- | --- | --- |
| **F15-A** `campaign-geography-residency-authority-audit` | **Read-only** code+runtime evidence: route-generated/local scene lifecycle, existing IDs, two seeded fixture runs, measured or clearly unmeasured timing/camera, camp spawn queues; compare architecture alternatives and propose formal address/residency API; no gameplay rewrite | Accepted C1/F14 and current F02/F15 docs | **Read-only implementation + fresh-review pair published `ready/auto` on origin/main after local authoring preflight and index update. Claim eligibility remains dispatcher-owned; active scope must stay read-only.** |
| **F15-B** `campaign-geography-identity-foundation` | Deterministic persistent Domain/Location address graph and spatial/route binding, no large generator or actors | Approved F15-A observations and explicit geography/extent/seam decision | **Blocked on design lock** |
| **F14-C2a** `living-world-population-slot-reservations` | Reconcile F14 ActorId/GroupId with camp/spawner queue, idempotent managed slot reservations and pending request cancellation; no geographic auto-handoff yet | Accepted C1 + approved Domain/Location contract | **Blocked on F15 address authority** |
| **F14-C2b** `living-world-locality-residency-binding` | Bind approved real locality staging/eviction events to C1 transactional handoff; no trigger on visual chunks; safe anchor and failure rollback | F15-B + C2a + real F02 scene/route APIs | **Blocked on F15-B and spawner ownership** |
| **F15-C** `campaign-continuous-two-site-traversal-proof` | Player-facing continuous foot traversal and repeated physical/abstract return across two distinct recognizable sites, preserving campaign/Operator/navigation | F15-B + C2b + reviewed F02 integration | **Blocked on architecture + preceding reviews** |
| **Later** REMAP-3 / F14-D, vehicle travel via F09 | Process-restart persistence and vehicle-assisted routes remain separately owned | Their existing roadmaps | **Do not duplicate** |

Each executable implementation slice should have an independently authored V2 implementation + fresh post-land review pair, official targeted preflight, `ready/auto` publication on `origin/main`, and exact workstream claim. **No packet is automatically promoted by this planning document.** If F15-A's source investigation can be completed inside an existing authorized F02/F15 audit, merge its scope there rather than creating a redundant claim.

## Codex Hall dependency hooks for upcoming packet refreshes (2026-10-09)

[Tracked idea inventory and mechanics decision gates](codebase_systems_audit/CODEX_IDEA_DEPENDENCY_REFRESH_REGISTER.md) **must** be consulted once F15-A's independently reviewed evidence arrives and **F15-B**, **F14-C2a/b**, **F15-C** or **F14-D** is refreshed for packet authoring. The user's preferred design direction is a **large finite, seeded procedurally generated world with persistent geography and selectively authored lore sites**. World size/coordinate system/staging remain unapproved pending F15-A evidence.

- **F15-B:** determine Encounter Language, Landmark Hierarchy, Spatial Compression and Mystery Budget's **actual mechanics, semantic generation fields, ownership, placement/seed controls and first negative/visibility tests**. Reserve only a lightweight purpose/failure/clue metadata seam for the later Procedural Ruin Generator. Preserve F02 procgen, live Material Intelligence and existing authored-site exceptions. Do not commission visual assets before art grammar and Asset V2 requirements are locked.
- **F14-C2a/b:** decide Faction Knowledge report/witness and Line-of-Communication route/signal **interfaces** only once a durable geographic address, ActorId/group and residency owner exist. **Do not implement** a duplicate actor simulator, faction AI or strategic world graph in C2.
- **F15-C:** evaluate whether the landmarks, environmental motifs, long-range distances and mystery clues remain readable and deterministic across two seeded site crossings/reentries. Full procedural ruins are **not** a dependency of the first continuous-travel proof.
- **Later causal/AI systems:** after stable sites, real history source/provenance and Material V1, revisit Procedural Ruin Generator + World Autopsy; after geography/connectivity/populations, revisit Line-of-Communication, Faction Knowledge, World Event Timeline, Resource Economy, morale, Director Memory and ambient evolution. Existing WorldHistory, WorldStateGraph, Material Intelligence, Observatory, Heatmaps and Interest are **extension/hardening** targets, not clean-sheet systems.
- **Mandatory refresh discipline:** disposition applicable register entries `incorporate-now`, `extend-live-owner`, `separate-next-slice`, `defer-with-trigger`, or `superseded`; decide mechanics/implementation ownership, performance and falsifiable tests before promoting active design or authoring paired packets. Keep the deferred trigger intact even when out of scope. Nothing in this note authorizes new runnable packets.

## Workstream ownership and open design decisions

**We can lock now without user preference:** F14 is the sole offscreen gameplay authority, actors/groups keep durable IDs, M6 presentation unload is not actor residency, staged transfer must be atomic/fail closed, and ambient spawners must not create duplicates of managed identities. These directly follow accepted C1 and runtime contracts.

**Still requires an explicit F15 decision after evidence:** large-but-finite vs expandable world footprint; macro region/route coordinate and deterministic seam owner; whether foot travel must be literally continuous or may conceal technically staged transitions while remaining uninterrupted to the player; terrain/road/vehicle scale and target travel times; which particular real sites make the first proof. The player-facing *continuous travel* intent is already locked; do not reinterpret that as permission for abrupt route menus.

**Immediate next action:** F15-A current-runtime evidence pass and formal geography/residency contract recommendation. Do **not** queue production C2a/b or world generator rewrites first. No assets are required for this planning/evidence slice; any subsequent commissioned art must follow Asset Pipeline V2 and receive exact in-repo paths, pixel dimensions and frame counts at its own design gate.
