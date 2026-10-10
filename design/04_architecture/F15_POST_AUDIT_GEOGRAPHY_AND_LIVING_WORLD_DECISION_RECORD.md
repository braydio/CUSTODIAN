# F15-B / F14-C2 · Post-F15-A Geographic Design Decision Record

**Status:** **D1–D7 USER-APPROVED ARCHITECTURE LOCK (2026-10-10); F15-B1 data-only identity foundation **implemented and fresh-context review PASSED** on main@03a584ee (2026-10-10), 0 blocking / 0 material gaps.** The finite-v1, persistent Domain-versus-Visit identity, perceived continuous traversal, residency/population/persistence/vehicle ownership boundaries below are approved as design authority. B2, F14-C2, F15-C implementation, numeric world dimensions and exact scene-streaming mechanics remain independently dependency-gated.
**Planning workstream:** `f14-c2-f15-production-residency-planning`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
**Verified main baseline:** `83e0008e317958d767aac321d7127ecd33c768ff` (F15-A independent review landed and archived).
**Authority:** [Accepted F15-A report](codebase_systems_audit/F15_GEOGRAPHY_RESIDENCY_AUTHORITY_EVIDENCE.md), [independent review summary](../../REVIEW_CAMPAIGN_GEOGRAPHY_RESIDENCY_AUTHORITY_AUDIT_CLAUDE_SUMMARY.md), [prior F14-C2/F15 refresh](F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md), [Hall dependency register](codebase_systems_audit/CODEX_IDEA_DEPENDENCY_REFRESH_REGISTER.md), [Domain/visit doctrine](CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md).

**Human decision receipt:** 2026-10-10, exact [authoring chat](https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31): the user approved the F15-B design direction and D1–D7, directed promotion of F15-B1 to `ready/auto`, and authorized claiming B1 only after its publication PR merges and both packets plus the index are verified on current `main`. Numeric scale, final visuals and exact streaming remain later gates.

## A. What passed; what it does not prove

- Independent review **PASS**: zero blocking defects, zero material evidence gaps, zero correction findings. After a full Godot editor import, current-main M6 and route lifecycle smokes printed PASS; the route's `MissingSpawn` / invalid `ProcGen owner` errors are deliberate negative-control rollback paths. Current-main packet index, review pairing (**62 pairs**), AI-context, and changed-file checks passed.
- Generated **local** candidate measurements: seed `12345` accepted `224×192` with **8,900 reachable candidate cells**; seed `54321` accepted `208×192` with **9,344**. These are separate regional maps, **not one campaign's world footprint**.
- Controlled unobstructed Operator movement: **439.33 px / 180 fixed ticks = 146.44 px per nominal simulation second**. This is not a two-site route benchmark; no real vehicle travel result. Do **not** derive lore kilometers, travel times or accepted-world scale from these fixtures.
- No production mapping from durable `(DomainId, LocationId)` to route/level/scene identities; F14-C1 has **synthetic** locality anchors; M6 evicts **presentation**, never geographic residency. Source-inspected ambient spawn/managed actor race remains unobserved as a duplicate. Required Ritualant underground ingress prevents one real-world spawn fixture from reaching activation; its generator/level owner retains that defect, not F15-A.
- This review **accepted the audit's truthfulness**, not the following architecture or new F15-B, F14-C2 or F15-C executable work.

## B. Approved design lock (D1–D7)

The user's previously expressed experiential direction is **large finite seeded procgen Campaign Worlds; physically coherent, continuous on-foot travel; persistent locations; on-demand materialization; selectively authored lore sites**. Based on accepted evidence, the user **approves a finite graph-backed Domain/locality footprint** over a single giant TileMap or unbounded coordinate generation for the initial implementation path. Numeric extent, exact coordinate systems, staging internals and world-scale performance budgets remain deferred until later evidence.

| Decision | **Approved design contract** | Owner / boundary | Explicitly NOT assumed |
| --- | --- | --- | --- |
| **D1 Domain, Location, Visit** | One persistent Lattice Domain has a seed and durable finite geographic location/adjacency descriptors. Canonical `domain_id` + `location_id` is the location address; `CampaignVisit` is a distinct per-Contract/session reference to *the same Domain*, not a fresh geography. Scene/route/node IDs and generator seeds are provenance, not substitute identity. | **F15** sole geographic address/topology owner; existing F06 campaign/session owns visit lifecycle; F14 receives immutable location addresses. | A new F14 geography store; deriving identity from a route node, visible chunk, or map label. |
| **D2 Footprint/scale** | **Finite accessible footprint for initial Campaign World**, seeded once per persistent Domain with named boundaries and physically plausible outer limits. **Expandable in future only by a later versioned design** that cannot reroll previously visited locations. Leave numeric cell/kilometer extents and settlement density unset until playable F15-C measurements. | F15 geographic topology data, F02 existing local terrain generator | Infinite geography, automatic dynamic expansion, invented kilometer conversion or simply enlarging a local map. |
| **D3 Continuous travel** | Player should ordinarily walk/drive a *spatially contiguous* road/wilderness route between distinct localities. Hidden technical scene staging is permitted only when it preserves position, heading/camera framing, path geometry, biome transition and Operator control; **not** a visible menu/teleport or unrelated rooms disguised as adjacent. Authored Port/Hub moves remain explicit lore-constrained travel infrastructure. | F15 adjacency/seam contract; F02 level/route/scene owners stage and commit geometry; F15-C proves player experience. | That current RouteTraversalManager already provides seamless campaign walking. |
| **D4 Residency transaction** | A location is `absent | staging | resident | evicting` with a versioned staged handle, explicit safe ingress/anchor validation, cancel/rollback, and source-scene pin until target is safe. F14 exclusive physical ↔ abstract actor handoff occurs once at an **existing SimulationKernel fixed-step boundary**, after valid geometry/slot staging. M6 reveal/unload and camera interest **never trigger** actor abstraction. | F15 geographic residency orchestration, F02 physical scene lifecycle, F14 actor truth | A new world clock, camera-radius unload-as-reification, destruction of active combatants on scene eviction. |
| **D5 Managed population** | Reservation key is durable `DomainId + GroupId + ActorId` (ActorId can migrate between locations without changing identity); association to current `LocationId` and spawn/camp provenance. F04 camp/spawner must cancel or suppress pending spawn for a managed slot **before** it attempts to instantiate; reification is not a new random spawn. Keep unmanaged ambient spawning unchanged. Fail closed/pin when damaged/combating/loot-bearing/unsafe/unresolved. | F14 is sole strategic actor/group truth; F04 owns physical queues/camp limits, C2a owns glue, C2b commits live residency. | A second population simulation; triggering F14 from M6 visual chunk state. |
| **D6 Persistence** | Version identity, topology, locale seed/provenance and visit reference for eventual durable snapshots; use collision-safe structured or injectively encoded keys (never naive `domain.location` concatenation). **REMAP-3** owns disk save/restart; F15-B makes deterministic descriptors serializable but creates no competing save pipeline. | F15 descriptor contract; REMAP-3 disk; F14 snapshot state | Claim that process restart already preserves the new domain; an F15 save silo. |
| **D7 Vehicles** | Ground-vehicle traversal matters to the world design but initial two-site acceptance is **on foot**. An F09-owned Field Scout travel, handling and persistence proof follows real road/scene-seam maturity. | F09 vehicle authority + F15-C later route integration | Vehicle configured max-speed = achieved travel speed; new vehicle controller. |

**Approval recorded:** User explicitly approved **D1–D7 together** on 2026-10-10, retaining numerical world scale and exact technical streaming as later evidence gates. F15-B1 was the last authorized implementation slice, and it has **landed, been independently reviewed and archived**. No B2/C2/F15-C implementation authorization is implied. This approval does **not** authorize dispatching B2, F14-C2, F15-C or art.

### Candidate minimum contract, not prescribed internal class names

```text
GeographicLocationDescriptor {
  schema_version, domain_id, location_id,
  domain_seed, generation_version, locality_seed,
  region_profile_id, site_kind, authored_override_id?,
  neighbors: [{ edge_id, target_location_id, crossing_kind, seam_contract_id }],
  landmark_slots[], encounter_cue_slots[], mystery_refs[],
  room_purpose?, failure_cause_hint?, material_profile_refs[]
}
CampaignVisitReference {
  visit_id, domain_id, entry_location_id, active_location_id, accessible_edge_set
}
LocalityResidency {
  address, state, staged_handle?, validated_ingress[], reservation_epoch
}
```

**Contract discipline:**
- Stable `domain_id/location_id` address and `edge_id` are independent of scene paths, chunks, names and camera. Every neighbor must be reciprocally consistent or explicitly a directed transit.
- Seed resolution is deterministic and versioned. `domain_seed + stable location identity + generation_version` determines local materialization provenance, but **collision-safe encoding** is required; no naive delimiter join and no inference that a seed alone is a place ID. Visit seed may influence *visit-scoped encounters* only if the existing campaign owner allows it; visits never silently reroll immutable terrain.
- All scene handles are ephemeral; F02 existing level/route APIs remain active scene owners. F15 produces descriptions/approved requests, not `Node2D` creation by a competing generator.
- Unknown profiles, malformed keys, incompatible edge seams, no safe ingress, duplicate actor slot, incompatible snapshot schema and cancellation races fail closed with a machine-inspectable reason.

## C. Atomic packet-refresh plan under approved design lock

**Do not turn one wide F15-B packet into an unreviewable game-world rewrite.** User approval selects B1 as the immediate implementation slice; claim only after its promotion PR merges and remote verification passes. All later rows remain conceptual/dependency-gated. Distinguish conceptual series from dispatchable packets:

| Order | Packet refresh / workstream | One primary owner and first proof | Gate |
| --- | --- | --- | --- |
| **B1** `campaign-geography-identity-foundation` (existing F15-B slot) | F15 data-only **Domain/Location/Edge registry**; collision-safe address, stable deterministic seed/version, visit reference and two named neighboring fixture sites with reciprocal edge; return/reinstantiate without ID drift. **No tiles, scenes, actors, saving**. | This human lock + accepted F15-A review; paired V2 packet/independent review needed |
| **B2** *suggested separately authorable follow-on* `campaign-geography-semantic-site-contract` | F15→F02 **read-only semantic generation/seam descriptor** binding an accepted location to existing local procgen and route metadata; validate crossing correspondence, biome/road/water continuity. Reserve landmark/motif/mystery/ruin fields without building their visual systems. | Accepted/reviewed B1 and F02 actual staging owner; separate design/packet decision |
| **C2a** `living-world-population-slot-reservations` | F04 camp/spawner keyed **managed reservation, dedupe, queue cancellation and caps** consuming B1 stable addresses; negative race tests, unmanaged ambient unchanged. | Accepted/reviewed B1, stable F14 group mapping, ingress defect disposition by F02 owner when it blocks real smoke |
| **C2b** `living-world-locality-residency-binding` | F15/F02 scene lifecycle event→F14-C1 fixed-step handoff, transactional rollback/pin, safe anchor reentry and repeated crossing; no M6 actor unload. | B1, physical B2 seam, reviewed C2a, accepted F14-C1 |
| **F15-C** `campaign-continuous-two-site-traversal-proof` | Real two-site **continuous foot traversal** (meaningful road/wilderness/biome transition), repeated return/scene eviction/reentry, stable identity, visible landmark language and no actor duplication. | Reviewed B2 + C2b, F02 actual scene ingress |
| **Later** F09 vehicle, REMAP-3 restart, cause-driven ruins, archive terminal | Their existing functional owners and separate packets | Measured evidence at each gate |

If B1 needs minimal typed fields or a small separate registry file, prefer focused module(s) under `custodian/game/world/` after exact code-owner inspection. Avoid prescriptive private class names and significant edits to `operator.gd`, `enemy.gd`, `route_traversal_manager.gd` or `proc_gen_tilemap.gd` until an existing integration seam is proven. F14-C2a can proceed after B1 if its identity/queue gates hold; it need not wait for landmark polish.

**B1 falsifiable acceptance:** (1) two fixed-seed Domain fixtures, including dotted-but-valid IDs, yield repeatable addresses and reciprocal physical edge semantics; (2) a second CampaignVisit to the same Domain resolves identical sites; (3) collision, duplicate edge, changed generation version, absent neighbor and invalid ingress provenance fail closed; (4) a fixture distinguishing route node identity from `LocationId`; (5) no gameplay nodes / added disk persistence / changed procgen outputs; (6) targeted validator + packet index/paired review proof on current main.

## D. Hall of Great Ideas: mechanism decisions now vs implementation later

The [dependency register](codebase_systems_audit/CODEX_IDEA_DEPENDENCY_REFRESH_REGISTER.md) remains the **complete** source for later revisit triggers. Apply these **mechanic choices** during the B1/B2 specification refresh without adding an unbounded implementation backlog:

| Idea | Concrete design decision for the first future implementation | Earliest sensible implementation |
| --- | --- | --- |
| **Encounter Language** | Structured `motif_id` plus a **truth-bearing cue contract**: every placed warning/cache marker must reference the real danger/opportunity/route state it signifies; biome-specific art is a presentation variant, not duplicate gameplay truth. Invalid references reject cue placement; avoid mandatory new asset art. | B2 metadata; first few live cues in/after F15-C with camera proof |
| **Landmark Hierarchy** | Worldgen reserves durable `landmark_id`, geographic position, role `dominant/supporting/local`, approach visibility candidates and authored overrides; **do not hardcode** historic 1+3+N quantities without measurements. | B2 schema/placement; F15-C player readability proof |
| **Spatial Compression** | Honest far-view/near-scene alignment to the **same landmark address**; occlusion/LOD need actual camera sightline evidence, not artificial distance or player teleport. | B2 seams, F15-C actual render/test |
| **Mystery Budget** | Small location-scoped `mystery_ref` list with clue/provenance/reveal policy; authored canon cannot be randomly resolved or contradicted. No forced clue quotas or UI scavenger checklist. | B2 metadata; authored/terminal behavior later |
| **Procedural Ruin Generator** | Reserve only `room_purpose` and `failure_cause_hint` plus material/clue/repair affordance references. Damage propagation, body/loot placement and visual profiles get separate post-site-geometry approval, Asset V2 manifest and tests. | After accepted B2, real room/site geometry and Material Intelligence surfaces |
| **World Autopsy** | Existing bounded **in-memory** WorldHistory cannot be treated as persistent proven cause. Require location-scoped simulation-tick event provenance, distinguish **generated inferred prehistory** from actual recorded events, reuse REMAP-3 for disk. | Post-accepted B1 site IDs, F14 history/REMAP-3 audit |
| **Line-of-Communication / Faction Knowledge** | F15 owns physical geographic edges; later systems may attach typed power/signal/logistics status and source-tagged faction reports. Dying scout or broken relay may prevent propagation **only through a later separately-authorized mechanism**. | C2 interface reservation; distinct implementation after actual population/connectivity |

**Live-foundation hardening watchlist:** WorldStateGraph keyed dependency truth; WorldHistory sector-local, uptime-stamped bounded memory; Material Intelligence observational classifications; Interest Management tiers ≠ actor eviction; Observatory capture/perf; Heatmaps telemetry-only; Moment Forge deterministic short capture. **Extend these owners when a verified gap exists**, never reopen them as clean-sheet systems. World Event Timeline, Resource Economy, Sector Activity Simulator, Ambient Scheduler, AI Morale, Director Memory, Replay and Performance Budget retain later gate/decision records in the register.

**2026-10-10 independently reviewed B1 closeout:** [implementation summary](../../CAMPAIGN_GEOGRAPHY_IDENTITY_FOUNDATION_CLAUDE_SUMMARY.md) · [fresh review PASS](../../REVIEW_CAMPAIGN_GEOGRAPHY_IDENTITY_FOUNDATION_CLAUDE_SUMMARY.md). Refer to [B2/C2 post-B1 refresh](F15_B2_F14_C2_POST_B1_PLANNING_REFRESH.md) for the **new, unapproved** next-slice integration decisions. The D1–D7 user lock remains valid.

## F15-B1 implementation snapshot (2026-10-10)

The data-only `CampaignGeographyRegistry` now owns finite Domain, Location and Edge identity. It accepts only schema 1 and the explicitly supported `geo-v1` generation provenance, validates bounded IDs/seeds and known endpoints before registration, and returns deep-copy descriptors. Undirected connections require exactly one reciprocal mapping with the same stable edge ID; directed transit is explicit. Domain/location address keys use UTF-8 byte-length-prefixed components, and locality seeds derive deterministically from Domain seed, canonical IDs and generation version.

`CampaignVisitReference` represents a distinct visit ID referencing the same Domain and explicit entry/active locations plus known accessible edges. It does not modify `CampaignSession`, create persistence, or derive geography from route/level IDs. The focused fixture and manifest entry live at `custodian/tools/validation/campaign_geography_identity_smoke.gd` and `custodian/tools/validation/validation_manifest.json`. No physical scene, actor, save, procgen adapter, route integration, or streaming behavior is implemented. Independent review remains the next required gate.

## E. Verification, provenance and doc drift

- This decision record itself adds **no game runtime, scenes, sprite sheets, props, assets, Asset V2 manifests or executable code**. The B1 packet pair is tracked separately. New art is unnecessary for B1; initial B2/F15-C use existing terrain or debug overlays. Any future asset request must specify `asset_drop/inbox/<family>/<named_source>`, repository destination, pixel dimensions, frame count, real alpha where needed, source attribution and Asset Pipeline V2 family schema **when the visual grammar is actually approved**.
- Recheck `origin/main`, current workstream index, root/local AGENTS, active F02 route/level and F14/C1 F04 implementations **before claiming** B1. The above names are possible module surfaces, not nonexistent classes claimed as present.
- Outstanding **owner-specific blocker:** required Ritualant underground ingress can block the ambient real-world spawn fixture. It belongs to its **existing procgen/level** owner and must be repaired or supplied with a valid canonical ingress fixture before claiming live managed-spawn coverage; neither the successful F15-A audit nor this design makes it pass.
- **Doc drift corrected by accompanying links:** earlier F15-A planning pages still refer to `ready/auto` F15-A or preflight; the authoritative latest event is **F15-A accepted and review archived on `main@83e0008e`**. No older audit evidence should be rewritten retroactively; update their forward-looking status/next-step lines only.
- **Next human planning step:** consider the [post-B1 B2/C2 design refresh](F15_B2_F14_C2_POST_B1_PLANNING_REFRESH.md) and approve or revise its B2 semantics-sidecar, C2a managed-spawn reservation, and C2b physical-handoff prerequisite boundaries. Neither B2 nor C2 is claimable from the completion of B1.
