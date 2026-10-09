# F15 · Campaign-World Geographic Scale, Topology and Traversable Domain

[← Audit overview](../CODEBASE_SYSTEMS_AUDIT.md) · [Discussion draft](../CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md) · [Conceptual roadmap](PACKET_ROADMAP.md#cs-f15-a)

> **Audit status:** source/design comparison recorded; full runtime topology, regional playtest measurements and design lock pending  
> **Decision status:** **NOT LOCKED**. No executable implementation task packets authorized or authored.  
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

**Decision:** **UNLOCKED**, zero new implementation packets; next is benchmark + architectural choice. Design doc is a proposal and does not supersede canon or runtime specifications.
