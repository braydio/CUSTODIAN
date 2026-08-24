# Elevated World Presentation

Status: complete

Last updated: 2026-08-09

## Purpose

The deterministic `ASCENT_FIELD` campaign world is presented as a bright, walkable upper plateau bounded by hard cliff lips and vertical fascia. Chasm cells form an impassable, darker depth layer. A low-contrast endless forest composition sits beneath and beyond that depth as scenery only.

## Authority

- Procgen retains authority over geometry, floor cells, roads, paths, elevation, navigation, collision, and streaming reveal.
- `ProcgenDepthBackdrop` owns only the global FAR, MIDDLE, and NEAR scenic underlay presentation.
- The backdrop has no collision or navigation and never creates reachable forest terrain.
- The general compatibility stack records generated-floor bounds for diagnostics, but its visual placement is native-scale and camera-following. It is not scaled to the full world rectangle.

## Visual Contract

Visual order is cold abyss depth, recognizable middle architecture, dark near ruin mass, deep chasm/void, cliff fascia, plateau floor, then roads, paths, props, actors, and effects. Walkable cells remain on the upper plane. Every exposed boundary uses the existing deterministic terrain semantics; this pass does not change topology.

Gameplay terrain files are individual 32x32 PNGs under `content/tiles/mountain_cliffs/` and `content/tiles/terrain/runtime/chasm_bridge/`. IDs 44-59 and 100-114 are stable semantic TileSet IDs. Runtime underlay profiles use 1536x1024 non-repeating compositions. Both generated-world and explicit-chasm configuration use one native-scale, camera-following FAR/MIDDLE/NEAR stack. Explicit chasm bounds and counts remain diagnostic metadata rather than finite scenic placement authority.

## Authored Void Cliff Face

- Endless forest remains presentation-only.
- Explicit chasm semantics remain authoritative structural state, but no longer
  create finite centered forest compositions in production.
- `configure_from_cells()` and `configure_from_chasm_cells()` use the same
  native-scale, camera-following 1536×1024 three-layer composition.
- Chasm configuration records bounds/count metadata for diagnostics.
- Chasm cells additionally drive a presentation-only `VoidCliffFace` at
  absolute z `-120`.
- The face may paint only authoritative chasm cells: never floor or ocean.
- It owns no collision, navigation, occupancy, traversal, placement, minimap,
  simulation, streaming, or wall authority.
- Fascia depth varies deterministically from three to eight cells. Distance one
  uses authored top source 149; interior depth uses weighted, clustered body
  sources 150–152; terminal depth uses weighted bottom sources 153–154.
- Cosmetic choices are stable by map seed and cell. Source 45,
  `rock_plateau_raised_32.png`, is no longer a fascia dependency.
- Roots and contact-shadow decals remain deferred.

## Source Versus Runtime Art

The contact-shadow composition is retained at `content/backgrounds/procgen/endless_forest/source/endless_forest_chasm_contact_shadow_source_1536x1024.png`. It is source-only and must not be stretched globally. A later pass may derive deterministic 512x256 broad, broken, and rooted decals placed beneath qualifying chasm-edge runs. The older `content/backgrounds/procgen_world/forest_underlay_*` files are stale/source-only and are not runtime authority.

## Streaming And Determinism

Procgen now exports complete deterministic `chasm_cells` semantics for every
in-map non-floor cell not replaced by an explicit surface claim. These
semantics are structural state and remain independent of wall dressing.

Both configuration paths retain received cell bounds as metadata and create one native-scale FAR/MIDDLE/NEAR stack that follows the active camera with a small overscan. Authored edge pockets and map-wide chasms therefore cannot expose a finite left/right seam. The backdrop does not participate in simulation or per-tile reveal and therefore does not alter deterministic fingerprints. Runtime images use linear filtering without mipmaps, disabled repeat, and lossless compression. Endless Forest is the production default; Drowned Basilica is an explicit development override through `ProcGenTilemap.underlay_profile_override`, with A/B selection derived from the accepted `ProcGen.seed`. Tonal normalization of Drowned Basilica derivatives remains pending visual review.

The runtime override authority is `ProcGenTilemap.set_underlay_profile_override("DROWNED_BASILICA")` (or the exported `underlay_profile_override` inspector field). Its explicit values are `ENDLESS_FOREST` and `DROWNED_BASILICA`, with `ENDLESS_FOREST` initialized as the production default. It resolves the selected profile and passes the accepted `ProcGen.seed` to `ProcgenDepthBackdrop`; the backdrop then updates an already-instantiated FAR/MIDDLE/NEAR stack in place.

Finite connected-region forest stacks are not production authority: one
1536×1024 stack centered on a large region cannot safely cover a map-wide
chasm. Chasm locality is instead expressed by the bounded stone fascia.

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
- Underlay profiles are presentation-only FAR/MIDDLE/NEAR resources. Endless
  Forest remains the default `ProcgenUnderlayProfile`; Drowned Basilica is an
  explicit alternate profile with deterministic A/B selection by seed,
  profile, and layer. Profiles never own chasm cells, cliffs, collision,
  navigation, occupancy, minimap, or generation.
