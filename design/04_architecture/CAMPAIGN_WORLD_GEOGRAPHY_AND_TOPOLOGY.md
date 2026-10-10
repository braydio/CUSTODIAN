# Campaign-World Geography and Topology · Design Discussion Draft

**Status:** **continuous campaign geography PLAYER-EXPERIENCE LOCKED** (2026-10-09); exact topology/generation/scale, route seams, vehicle feel and implementation architecture remain **PROPOSAL**, not runtime authority or an executable task packet  
**Date:** 2026-10-08  
**Workstream:** `campaign-world-geography-design-audit`  
**Audit focus:** [F15 Geographic Scale and Traversable Campaign-World Topology](codebase_systems_audit/F15_CAMPAIGN_WORLD_GEOGRAPHY.md)  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31

## Planning continuation: accepted F14-C1 and production residency (2026-10-09)

[**F14-C2/F15 Geographic Identity and Physical Residency Refresh**](F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md) reconciles the independently accepted synthetic real-Grunt physical/abstract handoff with current route scenes, generated locality staging, M6 visual-only chunk eviction, and ambient spawning. It proposes a **read-only F15-A geographic authority and travel-scale evidence pass first**, then a decision on stable Domain/Location and real locality residency, before any automatic F14-C2 implementation. The proposed finite graph-backed materialization strategy is *not yet a design lock*. The locked player target remains continuous geography within one Campaign World.

## 0. User-described target (design input, not yet a locked change)

The intended player experience is:

1. Awakening begins within the Historical City.
2. The persistent Hub is the site of Contract/campaign adjudication and deployment preparation.
3. A transit/gateway threshold delivers the Operator to the chosen **Campaign World**.
4. **Everything geographically/physically reachable during that campaign belongs to that campaign world**, including different biomes, territories, wilderness, settlements, cities, infrastructure, sites and routes. Visiting those places does not automatically end the campaign or require selecting another Contract.
5. The player explores, fights, investigates, preserves/changes local systems, and moves within one coherent campaign loop until the campaign is resolved, abandoned or otherwise exited.
6. The current small, packed generated map and insufficiently distinct visual geography do **not** deliver this experience.

Do not infer that “Campaign World” must be mathematically infinite or that the entire persistent Lattice Domain must be fully reachable. The extent and boundary rules remain a design decision, as do travel-time targets.

## User decision: continuous travel, bounded offscreen simulation and major transport (2026-10-09)

This discussion now has **two explicit user-owned choices**, captured in the [F14 V1 behavioral lock](codebase_systems_audit/F14_LIVING_WORLD_SIMULATION.md#f14-v1-behavioral-decision-lock-user-approved-2026-10-09) and [F15 continuous-geography decision](codebase_systems_audit/F15_CAMPAIGN_WORLD_GEOGRAPHY.md#player-facing-travel-and-world-access-decision-lock-2026-10-09):

1. **Offscreen state is Bounded:** unloaded groups/patrols may move, work, retreat, consume resources and resolve suitably constrained causal encounters; full offscreen physical combat or unreviewed irreversible special-character deaths are not promised. Retain the existing kernel's deterministic time.
2. **Campaign travel is continuous:** forests, terrain, passes, cities, districts and local biomes belong to one explorable Campaign World, without mandatory load-screen/cutscene segmentation. A **mountain pass is geography**, not a default teleport. Concealed engine scene stitching may be acceptable only if the player experiences geographic continuity.
3. **Archive Resolve retains its existing visual-only role**: it can make local streamed/instantiated terrain settle into visibility, but it does not generate the macro world or preserve unloaded actors. Current finite-map reveal must not be advertised as infinite/large-world streaming.
4. **Ports and vehicles are serious travel infrastructure.** The standard Hub departure is Muster Court's Continuity Port. Other Ports/routes are major lore-constrained transit mechanics, potentially cinematic. Existing [Vehicle System](../02_features/vehicles/VEHICLES.md), [Scout Mk I](../02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md), and the [Vehicle Recovery Roadmap](../02_features/vehicles/VEHICLE_RECOVERY_IMPLEMENTATION_ROADMAP.md) remain the production vehicle implementation authority. Long routes, road continuity and vehicle-friendly world traversal are a major later proof for F15, not license to spawn a second vehicle program.
5. The player-experience direction is locked **without locking** physical world extent, map-coordinate architecture, area names, special travel cinematics, vehicle speeds, or additional art families. F15 still requires performance-scale evidence and a reviewed streaming/topology owner.

## 1. Existing locks to preserve, and explicit historical distinctions

- [Awakening](AWAKENING_FIRST_RETURN.md) includes Crèche, Undercity, **Gate of Dust**, Custodian Approach, and Road of Witnesses South Reach. The Gate of Dust already has a prologue/world-entry function.
- [Hub Spatial Layout](HUB_SPATIAL_LAYOUT.md) and [Hub First Set Blockout](HUB_FIRST_SET_BLOCKOUT.md) treat the initial Hub as the **continuation of the Historical City's long processional spine**, not a remote military base. Hub Doctrine is still labeled `draft`, while the first-set geometry is locked/implemented as a blockout with explicit human topology approval. Moving the Hub to a remote base would reopen those decisions; do not do so implicitly.
- The ordinary Contract deployment path is **Ashen Forum/Adjudication Dais → Muster Court → Continuity Port**, not the Gate of Dust and not an abstract Field Terminal. Twin Solaria is an optional detached Crown route, not the ordinary Contract ingress.
- [Lattice Doctrine](../03_world/LATTICE_DOCTRINE.md) and [Cosmology Migration](../03_world/LATTICE_DOMAIN_COSMOLOGY_MIGRATION.md) establish persistent **Lattice Domains**. A Domain is an existing place with settlements, biomes, societies, roads and changing coherent boundaries. Contracts intervene in Domains; neither the Contract nor Archive Engines create terrain/worlds.
- A `CampaignRegion` is a **runtime representation of a portion of a persistent Domain**. “Transient” applies to scene data, not the existence of its people and geography.
- [World Transition](WORLD_TRANSITION_SYSTEM.md) distinguishes major Hub↔Campaign context changes from within-campaign route-node/scene transitions, which already use `RouteTraversalManager`/`LevelLoader`. Retain one authoritative gameplay world and persistent Operator ownership within the campaign. Seamless player-facing travel is possible even if technical scene handoff or streaming is used internally.
- [Region Generation](REGION_GENERATION_SYSTEM.md) targets scenario-conditioned topology, but its historical wording still focuses on one generated intervention region. This needs scope reconciliation for a larger campaign geography, **not** a rewrite of Lattice cosmology.

## 2. Proposed conceptual vocabulary

Use a **player-facing** “Campaign World” for the explorable geographic runtime/session assigned by the accepted Contract. Do not assert a new cosmological substance called `CampaignWorld`.

| Concept | Lifetime | Responsibility |
| --- | --- | --- |
| **Lattice Domain** | Persistent across Contracts/visits | Existing coherent place, geography/history/political/Archive-field state; may be revisitable |
| **Campaign World (visit/session)** | One accepted campaign loop, with save/restore | All physically reachable geographic play associated with that campaign, not merely one compact map |
| **Geographic region** | Domain-geography data, projected into campaign runtime | Large topographic landscape unit such as highland plateau, forest basin, floodplain, coast, ruined metro |
| **Site / settlement / district** | Stable identifiers, possibly persistent | Places with recognizable local topology, function and population |
| **Room / structure / compound** | Local physical scene/detail | Built environment, interaction and tactical simulation |
| **Macro infrastructure sector** | Strategic functional state, not geographic by default | POWER/COMMS/DEFENSE_GRID/etc. in `WorldSimulationState` |
| **Physical Sector scene** | Local structure | A named facility module with 24-unit logical tiles; must not define campaign geography |

**Overlay axes, not always nested containers:** polity territory/control borders, biome/ecological distribution, field-coherence gradient, threat/influence, travel network, and simulation interest/fidelity. A single polity can span multiple ecological regions; biome boundaries need not be administrative borders. A town can contain several local districts. Choose formal names to avoid collision with existing `Sector`, `Region`, `Chunk` APIs.

The previous discussion's simple hierarchy, **Domain → Campaign World/region → territory/district → site → structure**, is useful to communicate scale, but implementation should model geography, politics, ecology and actor interest as overlapping layers over stable location IDs.

## 3. Geographic feel contract (proposal)

**Space must have enough duration and contrast to become intelligible.**

- A coherent travel sequence should read as **leaving one place, crossing a transition, and entering another**, not stepping from forest patch into wetland patch beside the same fortification.
- Towns and outposts need **distinct catchments**: roads, resource/economic logic, approaches, outskirts, internal circulation, landmarks and defended/unguarded boundaries. Do not place independent settlements as adjacent decorative props.
- Biomes should emerge from **topography, water, exposure, climate, elevation and land use**, with broad cores, mixed edge zones and recognizable transition cues. A noisy per-cell biome checkerboard is not a sufficient geographic language.
- Landmark hierarchy must function at **far, approach and local scales**: silhouette/skyline or geologic spine, signed/constructed approach, identifiable street/entrance language.
- Repeated routes should support mental mapping. Roads, waterways, ridgelines, sightlines, signs and named places tell the player which way they traveled; a UI pin may complement rather than replace geography.
- Empty or low-activity land is not wasted procedural space when it gives travel, threat anticipation, quiet discovery and distance significance. Distinguish deliberate negative space from flat repetitive filler.
- Spatial scale should be proved using **real Operator travel times, traversable distance, visibility and camera framing**, not guessed tile counts or new lore kilometers. Vehicle traversal can establish a second scale, but must not be required to make pedestrian travel viable unless explicitly approved.

## 4. Current runtime limitation and why resizing alone is insufficient

[Streaming Procgen Reveal](../02_features/procgen/STREAMING_PROCGEN_REVEAL.md) explicitly generates the **entire finite map** from one seed before revealing its visual chunks. Distant chunk unload evicts presentation only; semantic world data and core scene authority remain. Its document excludes true endless geography and per-chunk enemy lifecycle.

[Procgen Region Frame Profiles](../02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md) locks Alpine starting-region target **192–208 × 192–208 semantic cells**, 32 units each, inside a finite irregular playable frame. This is an operation-sized **starting map**, not an entire world containing cities/biomes/wilderness. Do not quietly upscale that art frame into a world atlas.

[Persistent Compound Layout](../02_features/procgen/PERSISTENT_COMPOUND_LAYOUT_SYSTEM.md) owns a 10–13-room semantic campus, not a world geography. Existing macro presentation can make one locality visually coherent but not alone supply a world-scale settlement network.

Simply increasing one `ProcGenTilemap` canvas multiplies acceptance, navigation, rendering, memory, streaming and save costs while retaining the same missing higher-level topology. **Do not solve the geographic program by enlarging the existing map or by lowering content density without design intent.**

## 5. Candidate target architecture (NOT LOCKED)

```text
Persistent Lattice Domain state
  geography seed / stable location IDs / historical consequences
        |
        +-- CampaignWorld visit/session
        |    accepted Contract, accessible territory, campaign objectives
        |    authoritative clock, world history, persistence
        |
        +-- Geographic topology
        |    region adjacency; terrain masses; water; roads; settlements
        |    major landmarks; routes; coherence boundary
        |       |
        |       +-- spatial cell/chunk descriptors by absolute world coordinates
        |       +-- compatible local procgen and authored sites
        |       +-- local biomes / macro presentation
        |
        +-- Living-world simulation (F14)
             geographic interest / abstract actors and factions
             physical↔strategic reification / consequences
        |
        +-- Loaded physical world
             Operator, encounters, structures, navigation, collision
```

The world topology must exist **independently of currently instantiated scene nodes and visual chunks**. Once topology/identity is decided, local generators should fill it at a smaller scale without inventing contradictory roads, coastlines, city entrances or neighborhood relationships.

**Potential solution path:** generate a stable, global **geographic backbone** (macro terrain/route/settlement graph) for the reachable Domain/campaign footprint, then materialize only requested local spatial cells with deterministic coordinate-derived seeds and seam contracts. Keep inactive cell state serialized/abstract. This is a proposal, not a claim that current procgen supports it.

Explore **large but finite, expandable, and true unbounded** alternatives explicitly. Lore supports meaningful coherence/fringe boundaries, so no design requirement currently demands literal endless infinite worlds. If expansion exists, it must reveal/reconnect **existing** Domain geography, not create fictionally new land.

Player-facing travel can be continuous even if a canyon, gatehouse, road or authored landmark performs an internal scene transfer. Never disguise unrelated disconnected arenas as physically adjacent terrain without stable geography and sensible approach/exit correspondence.

## 6. Relationship to current programs and dependency gates

1. **No blocker for design:** create scale/topology vocabulary, settle campaign visit/Domain relationship, terrain hierarchy, settlement spacing and acceptance journeys now. Do not gate thought on art or GenerationGrid.
2. **Procgen semantic foundation:** F02 and [optimization roadmap](../02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md) own current generation state, accepted-world semantics, streaming and heavy runtime optimization. Audit their interfaces before introducing global coordinate stitching or multi-cell generation. This proposal must not secretly replace or parallelize existing owner.
3. **World Context and Routes:** reuse `WorldTransitionManager` target for major context changes and existing `RouteTraversalManager` for intra-campaign authored traversal, without creating a second campaign clock or teleport-based fake topology.
4. **F14 Living World:** can validate current near/far actor behavior now. Actual uninstantiated territory/actor handoff needs stable geographic IDs and state schema from this design.
5. **REMAP-3/persistence:** incorporate Domain geography deltas, actor/group identities, visit state, and deterministic continuation into approved persistence work. Do not independently create a second save system.
6. **Visual art:** use existing terrain, stamps, biome families, region frames and debug geometric overlays to validate scale/mental map first. Once spatial types and visual grammar are locked, make focused **Asset Pipeline V2** families with source/inbox/runtime paths, canvas dimensions, frame counts and attribution. No new art manifest or requested art production is authorized by this draft.

## 7. Alternatives worth evaluating

**Option A · Multiple finite connected local regions.** Fast to prototype with existing intra-campaign route/level stack. Preserves a single logical campaign and physical continuity when named corridors/roads/edges reconcile. Risks obvious seams and limited truly continuous geography.

**Option B · Single finite but substantially larger canvas.** Lowest conceptual change, highest danger of compounding expensive generation/streaming and retaining cramped micro-biomes. Useful only as measured temporary comparison.

**Option C · Macro-graph plus deterministic local-cell streaming.** Best candidate for broad, coherent travel and living-world scalability; requires a genuine new geographic data authority, cross-cell continuity and persistent identity rules. Avoid calling this implemented.

**Option D · Literally endless coordinates/on-demand generation.** Only if user locks an unbounded world requirement. Greater state/persistence/biome and world-boundary complexity; not necessary to solve the core experiential problem.

**Recommendation for review:** B is not the architecture target. A can serve as a transitional playable proof if topologically honest. C is the strongest long-term hypothesis. D remains conditional.

## 8. First acceptance proof and progression (not packets)

1. **Vocabulary/canon pass:** map Hub–Port–Domain–CampaignRegion terms to real code paths and audit contradictory old docs. Lock what “physically reachable in one campaign” means.
2. **Scale/legibility benchmark:** measure current crossing/approach times and record playtest evidence of adjacency, repeated visuals, biome edge quality, wayfinding, region depth and meaningful empty terrain.
3. **Macro geography prototype:** draw/generate a seed-stable geographical graph with **at least three distinguishable areas**, meaningful travel connectors, one settlement/site cluster, one wild transition, and coherent water/road/elevation identities. No new authored art required. Validate graph rather than painting a giant world.
4. **One connected playable journey:** leave an inhabited/site space, traverse meaningful wilderness, arrive at a second distinct site **within one accepted campaign**, keeping the same Operator, campaign state, map identity, mission progress and route history.
5. **Living-world reentry:** a distant area changes while unloaded, then reconstructs its meaningful state on approach, without duplicate actors or reset site state. Coordinate with F14 and save authority.
6. **Performance and visual closeout:** deterministic repeatability, seam identity, navigation/clearance and framerate cost, then focused human art-direction review of district/biome/landmark grammar.

No hard map dimensions, travel-minutes budget, number of towns, art products or executable tasks should be approved until source-level performance and first design proof answer the open questions.

## 9. Open design decisions to bring back to user

- Is the campaign world **one accessible geographic portion** of a Domain with explicit coherence/travel boundaries, or a footprint that may expand significantly during a campaign?
- Should the Operator ordinarily move between every district through contiguous terrain, or may **physically explained** roads, ports, tunnels and regional passes support local route scene seams?
- What player journey is the minimum useful scale for two settlements and a biome change? Decide from traversal testing instead of speculative raw pixel counts.
- How much may the accepted Contract change Domain geography compared with merely accessing an existing, persistent place?
- Does leaving a campaign preserve local progress for later revisits as lore suggests; what persists across visits versus current run only? Coordinate with REMAP-3.
- Which visual and UI wayfinding cues make transitions legible without replacing discovery with objective markers?

## 10. Documentation drift and protection

- `REGION_GENERATION_SYSTEM.md` uses the one-region/one-operation assumption appropriate to initial prototype; it is **insufficient** for this campaign-geography target, but remains the existing implementation architecture until a replacement is approved.
- `HUB_DOCTRINE.md` remains draft but its core Historical City direction is aligned with the **locked Hub First Set Blockout**. Do not say remote base is an equally implemented/locked option.
- `STREAMING_PROCGEN_REVEAL.md` correctly declares no endless generation; do not call existing chunk reveal world expansion.
- Keep CampaignRegion = transient portion-of-Domain runtime and Domain = enduring place per [Lattice Doctrine](../03_world/LATTICE_DOCTRINE.md). A campaign resolving must never magically delete its represented world.
- Existing code with `Sector` should not be renamed or assigned world-geography authority just to match new design vocabulary.

**Governance:** This draft records the user's design intent and source-backed candidate architecture only. It does not override existing locked spec, queue or asset requirements. Promotion requires F15 evidence, user design lock, exact owner/API boundaries, and existing packet-queue reconciliation.
