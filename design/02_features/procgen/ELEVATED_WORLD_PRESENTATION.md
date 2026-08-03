# Elevated World Presentation

Status: complete

## Purpose

The deterministic `ASCENT_FIELD` campaign world is presented as a bright, walkable upper plateau bounded by hard cliff lips and vertical fascia. Chasm cells form an impassable, darker depth layer. A low-contrast endless forest composition sits beneath and beyond that depth as scenery only.

## Authority

- Procgen retains authority over geometry, floor cells, roads, paths, elevation, navigation, collision, and streaming reveal.
- `ProcgenDepthBackdrop` owns only the global far-haze, canopy, and near-wall-growth presentation.
- The backdrop has no collision or navigation and never creates reachable forest terrain.
- Bounds come from the authoritative generated floor dictionary before streaming clears visible TileMap cells.

## Visual Contract

Visual order is cold abyss haze, recognizable distant canopy, dark near-wall growth, deep chasm/void, cliff fascia, plateau floor, then roads, paths, props, actors, and effects. Walkable cells remain on the upper plane. Every exposed boundary uses the existing deterministic terrain semantics; this pass does not change topology.

Gameplay terrain files are individual 32x32 PNGs under `content/tiles/mountain_cliffs/` and `content/tiles/terrain/runtime/chasm_bridge/`. IDs 44-59 and 100-114 are stable semantic TileSet IDs. The three runtime forest textures are 1536x1024 non-repeating compositions under `content/backgrounds/procgen/endless_forest/`. Explicit chasm sources and symbolic gap cells are split into connected regions; each meaningful region receives one centered haze/canopy/wall-growth stack clamped to `0.75–1.25` scale. Ordinary generated floor does not create forest presentation.

## Source Versus Runtime Art

The contact-shadow composition is retained at `content/backgrounds/procgen/endless_forest/source/endless_forest_chasm_contact_shadow_source_1536x1024.png`. It is source-only and must not be stretched globally. A later pass may derive deterministic 512x256 broad, broken, and rooted decals placed beneath qualifying chasm-edge runs. The older `content/backgrounds/procgen_world/forest_underlay_*` files are stale/source-only and are not runtime authority.

## Streaming And Determinism

The live general-world compatibility path is configured once per complete generation from authoritative generated-floor cells. Those cells establish the complete world bounds for one far-haze, canopy, and near-wall-growth stack behind opaque generated terrain; gaps reveal the underlay. This fallback remains necessary until procgen exports reliable, complete abyss semantics. `configure_from_chasm_cells()` retains the localized-region implementation for that later handoff, but is not the live general-world call path. The backdrop does not participate in simulation or per-tile reveal and therefore does not alter deterministic fingerprints. Runtime images use linear filtering without mipmaps, disabled repeat, and lossless compression.

## Candidate Promotion And Runtime Visibility

Contract candidate evaluation currently commits structural TileMap output so
layout, terrain, required-cell connectivity, roads, regions, and ingress can be
validated against the same structural authority used at runtime. It is not yet
a semantics-only evaluator.

Once accepted, that exact candidate is promoted in place. Promotion preserves
its structural TileMaps, generated floor/wall dictionaries, terrain result,
roads, regions, and current streaming visibility. It executes only final work
skipped by evaluation: registered floor-value decoration, final foliage setup
when streaming is disabled, ruin/interior props, final playability audit,
shadows, overlays, and navigation refresh. It must never call the complete
generation or `_fill_tilemaps()` pipeline again.

Streaming reveal defers foliage/terrain painting across frames, but ruin and
interior prop construction remains synchronous during promotion. Their costs
are reported separately and remain the next finalization optimization surface.

Navigation continues to derive from painted floor/wall TileMaps under the
locked TileMap structural-authority rule. The navigation debug snapshot reports
authoritative generated-floor, painted-floor, and AStar point counts so reveal
lifecycle coverage can be measured explicitly. Changing navigation to consume
unpainted semantic floor requires a separate authority decision; it is not an
implicit performance optimization.

Floor-value clustering runs only when at least two registered variant sources
exist. The export may be enabled while the live scene has no usable variant
registration; that state is an explicit no-op and is logged.

## Validation

Run `elevated_world_asset_contract_smoke.gd` for asset, TileSet, scene, and backdrop contracts. Run `procgen_candidate_promotion_smoke.gd` to prove that accepted structural state is promoted without a second generation or streaming reveal expansion. Run `elevated_world_seed_review.gd` for fixed-seed geometry summaries, followed by the established terrain, road, and route-clearance smokes.
