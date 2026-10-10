# F15 · Campaign-World Geographic Scale, Topology and Traversable Domain

[← Audit overview](../CODEBASE_SYSTEMS_AUDIT.md) · [Discussion draft](../CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md) · [Conceptual roadmap](PACKET_ROADMAP.md#cs-f15-a)

> **Audit status:** source/design comparison recorded; full runtime topology, regional playtest measurements and design lock pending  
> **Decision status:** **PLAYER EXPERIENCE LOCKED** (continuous campaign geography; passes do not inherently trigger cutscenes; ports/vehicles are core travel). The actual F15 macro topology, chunk/region materialization, numeric scale, routes, vehicle feel, assets and implementation DAG remain **NOT LOCKED**; no F15 implementation packet authorized.  
> **Priority:** P0 design/audit focus, not a new dispatcher priority  
> **Workstream:** `campaign-world-geography-design-audit`  
> **Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31  
> **Method:** live repository docs/source, October 8, 2026; **no headless or interactive local Godot runtime tests**.

## Scope and player target

The user wants **Awakening (Historical City) → persistent Hub with Contract choice → continuity gateway → a broad, physically traversable Campaign World** containing distinct biomes, towns/cities, territories, routes, infrastructure, wilderness, settlements and activity, staying in the same campaign until its outcome/exit. The current compact, packed one-canvas contract sandbox fails geography scale and visual readability.

This is **not F14**: F14 owns how actors/sectors continue to evolve when not loaded. F15 defines **which places exist, where they are and how they connect**, which F14 will eventually consume. F02 covers concrete procgen/world-installation implementation; F15 does not commandeer it.

## Confirmed repository facts

1. **Awakening/Hub:** `AWAKENING_FIRST_RETURN.md`, `HUB_SPATIAL_LAYOUT.md` and `HUB_FIRST_SET_BLOCKOUT.md` already place the first Hub along the Historical City continuation. Gate of Dust belongs to Awakening; ordinary deployment is the **Muster Court Continuity Port**. The drafted overall Hub Doctrine also describes the city, not a remote outpost.
2. **Lattice geography:** `LATTICE_DOCTRINE.md` establishes persistent geographic Domains with settlements, biomes, roads and finite coherence pressure. A `CampaignRegion` is a runtime representation of a portion, not a fabricated/expendable world.
3. **Runtime scene lifecycle:** `WORLD_TRANSITION_SYSTEM.md` distinguishes major context handoff from `RouteTraversalManager`/authored level transitions *within* one campaign.
4. **Current scale:** `PROCGEN_REGION_FRAME_PROFILES.md` sets Alpine starting canvas to 192–208 semantic cells/side at 32 world units/cell; irregular playable terrain smaller than canvas. `PERSISTENT_COMPOUND_LAYOUT_SYSTEM.md` offers a 10–13-room campus, not multiple separated regional settlements.
5. **Generation/streaming:** `STREAMING_PROCGEN_REVEAL.md` generates entire finite map before chunked reveal; remote chunk unload is presentation-only. It explicitly excludes true endless generation and per-chunk enemy lifecycle. `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` already owns expensive generation and streaming hardening. **Do not enlarge one TileMap and call it global geography.**
6. **Separate identifiers:** `WorldIdentityContract.MACRO_SECTOR_IDS` names facility functions, while `Sector` scenes are physical built structures. Neither should become the region/district identity registry by accident.

## Findings

- **F15-01 · CONFIRMED:** Hub location and ordinary deployment threshold were more specific than the prior discussion: Historical City continuity and an ordinary Continuity Port already have design authority. Moving Hub to a remote base would reopen design.
- **F15-02 · CONFIRMED:** Current finite generated-world canvas and chunk *presentation* streaming cannot directly deliver the user's multi-settlement campaign geography.
- **F15-03 · CONFIRMED:** Existing procgen has compound/room/local-biome and region-frame modeling, but these do not themselves define a world-wide settlement/territory/route topology.
- **F15-04 · DESIGN GAP:** Campaign World as one physically traversable, wide-area player experience needs an explicit overarching geographic/world-session contract consistent with the persistent Lattice Domain. Exact boundaries and spatial representation are not locked.
- **F15-05 · DESIGN GAP:** Territorial borders, biomes, coherence gradients, local interest, and infrastructure sectors are overlapping semantic axes, not one interchangeable “sector” taxonomy.
- **F15-06 · DOC DRIFT:** Old `REGION_GENERATION_SYSTEM.md` describes the initial one-active-portion procedural operation and phase milestones. Do not claim it proves a unified traversable campaign geography. Upgrade its scope only through explicit reviewed redesign.
- **F15-07 · MEASUREMENT PENDING:** Actual travel time, visual-recognition distance, biome transition cadence, settlement footprint, spawn/perf pressure and acceptable world size must be established by gameplay/runtime instrumentation; no raw pixel prescription is justified yet.

## Recommended design path (proposal, not approval)

See the full [geography/topology design discussion draft](../CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md).

- Preserve **Historical City → Hub Forum → Muster Continuity Port → accepted Domain's campaign world → Hub return**.
- Treat one campaign as a **single geographic and stateful visit/session**, even if internal scenes/chunks stream separately.
- Give global topology/locations/road/water/settlement geography stable deterministic identity **independent of loaded nodes**.
- Use macro geography as constraints on compatible smaller deterministic generators. Biomes, factions and coherence are overlays over that topology.
- Prefer testing *large but finite coherent domain geography* and *graph-backed streamable cells* rather than requiring literal endless terrain upfront. An actual infinite-world contract would need a separate user choice.
- Preserve existing authored routes and campaign/Domain persistence owners; never infer “world generated by Archive Engine” from procgen.

## F14 local audit handoff (2026-10-08)

The [F14 read-only local runtime characterization](F14_LIVING_WORLD_SIMULATION.md#local-read-only-runtime-audit-and-validation-receipt-2026-10-08) reports six focused Godot checks **PASS** on matched runtime sources, but **none** demonstrates unloaded-actor identity handoff or causal distant-area progression. `WorldSimulationRuntime` and the interest-manager tier implementation are real; the missing bridge needs **geographic identity independent of existing physical `Sector` nodes and macro infrastructure-sector IDs**.

**F15 responsibility before F14 production integration:** choose stable `campaign/domain → geographic location/region/site → location-owned actor/group` identities and relationships, plus how those identities survive local scene/chunk unloading. The *initial* F14 two-location deterministic unit/lifecycle proof can use synthetic IDs with no new art or world-size expansion; full production reification cannot bind to undefined geographic ownership. Do not create duplicate simulation clocks, parallel procgen, or a new save silo for F14.

## F14-C1 accepted → production geography/residency gate (2026-10-09)

[Production F14-C2/F15 contract refresh](../F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md) synthesizes live F02/F04/F14/F15 ownership, design choices and proposed packet sequence. **F14-C1 is now independently accepted after correction R0-01/R0-02/R0-03**, confirmed by [fresh review summary](../../../REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md) and archived re-review receipt. It proves **explicit** synthetic A/B Grunt physical/abstract handoff, deterministic repeated return, IDs/health/intent, snapshot compatibility and physical ownership suspension. It does **not** provide geographic production auto-residency or make synthetic sites real traverseable localities.

**F15 required identity before C2:**
- Stable `DomainId + LocationId` durable across CampaignVisit, node reload and scene recreation; optional region/route topology must not substitute locale ownership. Geographic references are not POWER/COMMS macro sector IDs, physical `Sector` nodes, scene node IDs, visual chunks or `stable_spawn_ordinal`.
- A canonical mapping from actual generated/authored locality, safe spawn anchor and active physical scene residency to that geographic address; the current `ActorReificationCoordinator.bind(kernel, anchors)` takes synthetic location keyed live `Node2D` anchors, not geographic residency descriptors.
- Distinguish *physical actor/scene residency* from M6 `ProcGenChunkResidencyPolicy`'s disposable painted/cache unload and Archive Resolve's presentation reveal. Neither is an actor unload signal.
- The ambient camp/spawner `_spawn_queue` and per-camp quota lifecycle must reconcile F14-managed durable ActorId reservations before loading/restoring actors, so default proximity spawning never duplicates a reified Grunt.
- Define scene/route staging rollback and campaign continuity. `RouteTraversalManager` already owns authored/generated scene transitions, but its route node identity is not automatically the Lattice geography registry.
- Choose world extent/topology/seams **after a read-only F15-A runtime benchmark**. Graph-backed deterministic locality geometry over a coherent finite footprint is a *preferred hypothesis*, not an approved global generator.

**Gates:** only F15's continuous-travel **player experience** is locked. No F15-B topology/generator or F14-C2 automatic production residency packet is yet authorized. Next source/test slice is F15-A geographic/route/scene authority and real travel-scale evidence; do not fabricate new world IDs or mix visual cache eviction with Enemy life cycle. Preserve F09 vehicles and REMAP-3 persistence owners.

## Player-facing travel and world-access decision lock (2026-10-09)

**User-owned design choice:** **Continuous geography**. Within one accepted Campaign World, the Operator ordinarily walks, drives or otherwise traverses connected landscapes, changing biome, town, city district and political territory without an obligatory loading cutscene or switching campaign instances. This is a player-experience commitment, **not evidence that the present finite procgen map already supports it**.

**Passes and local thresholds:** A mountain pass, bridge, tunnel, canyon, district boundary, highway, valley, and ordinary town gate belong to the **same traversable geographic context** by default. They are not synonyms for cinematic loading gates. Exceptional authored interiors/transit events *may* use concealed technical scene handoff; if an explicit cinematic is appropriate, the design must justify it as a significant fiction/navigation event. Preserve consistent approach/exit geometry, Operator/campaign identity, route history, and means of travel on both sides.

**Archive Resolve is presentation, not generation:** [Archive Resolve](../../02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md) governs the visual settlement/frontier of newly available **already-authoritative** terrain. [Streaming Procgen Reveal](../../02_features/procgen/STREAMING_PROCGEN_REVEAL.md) currently builds a finite full map first and reveals/evicts **presentation** in chunks; it does **not** yet stream/generate an unbounded global landscape or unload/reify actors. F15's world-scale geographic topology, semantic cell materialization, world-boundary/route stitching, road continuity, navigation/residency and saved region identities need separate source-grounded design and testing. **Archive Resolve remains the visual treatment** wherever compatible; do not assign it geographic creation or route-transition authority.

**Ports and special travel:** The Hub's ordinary campaign deployment uses the **Continuity Port** in Muster Court. Other Ports, apertures, relays and allowed Domain-to-Domain routes are meaningful transit infrastructure, with route/risk/return authority governed by the existing lore and major world transitions. They may legitimately carry cinematic travel, but are not “the way to cross between two hills.” Do not imply every Port can freely link arbitrary Domains.

**Vehicles are a major campaign-world traversal system:** Long distance and topographic scale must make meaningful room for a vehicle's road choices, access restrictions, recovery, storage and on-foot/vehicle route planning. The project already has [Vehicle System](../../02_features/vehicles/VEHICLES.md), the [Field Scout Buggy Mk I](../../02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md), and an active [Vehicle Recovery Implementation Roadmap](../../02_features/vehicles/VEHICLE_RECOVERY_IMPLEMENTATION_ROADMAP.md). Their **PilotableVehicle + registry + restoration/Asset V2 owners remain canonical**. F09 must audit travel/handling and route suitability before proposing upgrades; no replacement controller, new unapproved vehicle class, or blanket art-manifest work is authorized here.

### Minimum continuous-world proof

A later authorized F15 prototype should prove:
1. Two distinct recognizable sites/settlements separated by a meaningful wilderness/biome journey in **one** CampaignVisit.
2. Operator travels continuously on foot across the full intervening route; any hidden technical handoff must preserve apparent world geometry and campaign/Operator continuity.
3. A road-capable **existing** vehicle can traverse the same logical route after its active implementation dependencies are ready, with credible road/terrain interaction, collision/navigation and correct enter/exit/restore state. Treat this as a **distinct follow-on acceptance slice** rather than blocking initial foot-only topology proof.
4. Archive Resolve can present correctly on newly materialized local terrain without visible chunk rectangles or implying the world was created by the Operator's approach.
5. Landmarks, biome edges, watercourses, routes and local names remain repeatably recognizable across seed reload and physical reentry.
6. F14 unloaded groups may remain active abstractly while the Operator travels, without assuming the entire Campaign World is physically loaded.

**Not yet decided:** large finite versus expandable geographic extent; exact world-cell API; kilometers/minutes of travel; ground vehicle speed and fuel; crossing long-range Ports inside the same Campaign; optional explicit cinematic moments; later scope for airborne/waterborne vehicles. These are **engineering or subsequent content locks**, not reasons to overturn the selected continuous-geography player target.

## Upcoming idea mechanics decisions, post-F15-A only

[Hall of Great Ideas dependency register](CODEX_IDEA_DEPENDENCY_REFRESH_REGISTER.md) is the durable refresh checklist. At the **F15-B geographic identity and procgen implementation-spec refresh**, explicitly decide the generator-stage ownership, semantic data fields, deterministic placement/validation and minimal fixed-seed proofs for **Encounter Language** (honest danger/opportunity motifs), **Landmark Hierarchy** (dominant/supporting/local geographic cues), **Spatial Compression** (truthful long-range sightlines) and **Mystery Budget** (intentional unanswered regional questions). Preserve authored lore exceptions and the current F02 generator/Material Intelligence owners. Reserve only typed site/room/failure metadata for the later **Procedural Ruin Generator**, not its assets or causal generation implementation.

At **F15-C**, assess actual rendered/traversable legibility and stable return from two sites; don't claim the four early ideas implemented until those acceptance tests pass. **World Autopsy, networked infrastructure, factions, world events, and economy** have later explicit triggers in the register and must be re-assessed rather than omitted. Do not change the read-only F15-A packet. Decisions that affect campaign scale, authored lore or aesthetics stay in this authoring chat.

## Audit and decision checklist

- [ ] Local runtime crossing/time/biome/landmark/wayfinding benchmark for current accepted seeds and operator camera/speed.
- [ ] Active `ProcGenTilemap`, `CustodianContractMap`, road/topology, claim, streaming and level/route graph API mapping after current procgen hardening.
- [ ] Existing location and region/surface identity collision review; prove actual missing global geographic data seam rather than naming-only concern.
- [ ] Concrete options A connected local regions, B enlarged finite one-canvas (control), C macro graph + on-demand deterministic materialization, D unbounded generation; measure tradeoffs before choosing.
- [ ] Art-free/placeholder geographic prototype acceptance: two distinct sites separated by meaningful travel and biome transition in **one active campaign**; stable return identities.
- [ ] Coordinate F14 background activity and REMAP-3 persistence/revisit semantics; no duplicate save/clock/scene authority.
- [ ] Design approval for intended campaign extent, boundaries, on-foot/vehicle distances, route seams, biome and wayfinding grammar, and settlement scale.
- [ ] Documentation drift: Hub remote-base ambiguity resolved against locked current geometry; old one-region wording explicitly classified for migration/deprecation rather than wholesale rewrite.
- [ ] Only after decision lock, convert any conceptual F15 roadmap slot into authorable packet under existing queue/AGENTS, with paired validation/review and authoring-chat backlink.

**Decision:** **CONTINUOUS PLAYER EXPERIENCE LOCKED**; preferred **finite seeded procgen with persistent geography and selective authored lore sites** remains a design direction, while production topology/materialization and numeric scale stay **UNLOCKED**. The F15-A read-only evidence and independent review packet pair is now **published `ready/auto` on current main**, not expanded by the Codex review. [F15-A packet](../../../custodian/docs/ai_context/task_packets/CAMPAIGN_GEOGRAPHY_RESIDENCY_AUTHORITY_AUDIT.md) · [review](../../../custodian/docs/ai_context/task_packets/REVIEW_CAMPAIGN_GEOGRAPHY_RESIDENCY_AUTHORITY_AUDIT.md). Next: targeted authoring preflight/promotion, then current geographic/scene/residency runtime measurement. F15-B/C2 implementation still needs post-evidence design locks; existing F09 vehicle owners remain authoritative.
