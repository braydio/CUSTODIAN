# Elevated World Presentation

Status: complete

## Purpose

The deterministic `ASCENT_FIELD` campaign world is presented as a bright, walkable upper plateau bounded by hard cliff lips and vertical fascia. Chasm cells form an impassable, darker depth layer. A low-contrast endless forest repeats beneath and beyond that depth as scenery only.

## Authority

- Procgen retains authority over geometry, floor cells, roads, paths, elevation, navigation, collision, and streaming reveal.
- `ProcgenDepthBackdrop` owns only the global distant-forest and mist presentation.
- The backdrop has no collision or navigation and never creates reachable forest terrain.
- Bounds come from the authoritative generated floor dictionary before streaming clears visible TileMap cells.

## Visual Contract

Visual order is distant forest, forest mist, deep chasm/void, cliff fascia, plateau floor, then roads, paths, props, actors, and effects. Walkable cells remain on the upper plane. Every exposed boundary uses the existing deterministic terrain semantics; this pass does not change topology.

Gameplay terrain files are individual 32x32 PNGs under `content/tiles/mountain_cliffs/` and `content/tiles/terrain/runtime/chasm_bridge/`. IDs 44-59 and 100-114 are stable semantic TileSet IDs. The forest textures are 512x512 repeating backgrounds under `content/backgrounds/procgen/endless_forest/`.

## Source Versus Runtime Art

The concept montages under `content/tiles/procgen/elevated_world/source/` are 1536x1024 reference files. They are not atlases and are never loaded by runtime resources. Replaced art is retained under `archive/pre_elevated_world_v1/`, which is also excluded from runtime.

## Streaming And Determinism

The backdrop is configured once per complete generation from generated floor bounds plus a fixed margin. It remains globally visible while terrain chunks reveal. It does not participate in simulation or per-tile reveal and therefore does not alter deterministic fingerprints.

## Validation

Run `elevated_world_asset_contract_smoke.gd` for asset, TileSet, scene, and backdrop contracts. Run `elevated_world_seed_review.gd` for fixed-seed geometry summaries, followed by the established terrain, road, and route-clearance smokes.
