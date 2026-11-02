# Procgen Macro Presentation System

Status: implementation

Last updated: 2026-09-08

Surface Materials V1 is a separate implementation slice governed by
`SURFACE_MATERIALS_V1.md`.

Macro presentation consumes the active region-frame contract from `PROCGEN_REGION_FRAME_PROFILES.md`. The first starting region uses `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`, but future frames may select different compatible macro/depth vocabularies. Presentation must never infer the permanent region border from whichever local biome happens to dominate. It classifies final floor presentation before
macro composition without changing the macro stamp subsystem or gameplay
authority.

## Purpose

Track the migration from visibly cell-first procgen rendering toward a
deterministic, region-composed top-down 2.5D world. Large authored terrain
stamps, environmental clusters, hardstand shapes, and landmarks will present
the existing semantic world without becoming gameplay authority.

This document is active implementation authority. Its hardened V1 contract was
reconciled against the live procgen scene and pipeline on 2026-09-04.

## Authority Boundary

The existing 32×32 semantic grid remains authoritative for:

- walkability, collision, and navigation;
- floor, wall, blocker, road, and structure state;
- biome and elevation metadata;
- spawn validity and authored claims;
- deterministic generation and saves.

Presentation composition may read those facts. It may not mutate them, derive
collision from sprite alpha, infer blockers from artwork, or make an authored
sprite shape responsible for navigation.

## Target Rendering Model

The world renderer has three scales:

1. **Semantic cells** — the existing 32×32 gameplay authority.
2. **Material tiles** — quiet ground families describing what is underfoot.
3. **Macro presentation** — large transparent cliff masses, shelves, clusters,
   hardstands, road margins, and landmarks fitted to semantic regions.

Visual composition is region-first. A rocky region asks what kind of place it
is, then selects a compatible archetype and stamp vocabulary. Individual cells
do not independently choose conspicuous detail.

## Locked Migration Invariants

- `ProcGenTilemap` retains floor/wall semantic authority.
- `TerrainBuilder` retains terrain, elevation, and connectivity metadata.
- Biome classification remains separate from presentation selection.
- Presentation fitting never alters terrain, navigation, collision, claims, or
  saves.
- The same accepted seed and semantic terrain produce the same placements.
- Regions without a fitting macro asset retain current TileMap presentation.
- Existing authored and foliage clearances remain placement constraints.
- The new subsystem is not embedded directly into the `ProcGenTilemap`
  monolith.
- The system does not generate one giant map texture.
- Quiet ground and negative space are deliberate composition outcomes.
- Streaming reveal gates each stamp using all of its actual live TileMap probe
  cells and hides it again when those cells unload.
- Missing or unfittable presentation art never rejects a structurally valid map.
- V1 changes neither day/night nor weather behavior.

## Planned Runtime Ownership

The proposed implementation surface is:

```text
custodian/game/world/procgen/presentation/
  procgen_macro_presentation_composer.gd
  terrain_region_extractor.gd
  terrain_stamp_profile.gd
  terrain_stamp_catalog.gd
  terrain_stamp_placer.gd
```

The generated map will expose separate presentation roots:

```text
TerrainPresentationBack
TerrainPresentationGround
TerrainPresentationFront
```

The roots are live children of `NavigationRegion2D` on the native-scale `ProcGenMap`
root. BACK/GROUND/FRONT use absolute z indices `-5/0/4`. V1 places BACK and
GROUND only. Procgen runs at native 32px with root scale `Vector2.ONE`;
spawned sprites retain authored pivots and use nearest filtering.

## Planned Data Contracts

`TerrainStampProfile` is expected to describe at least:

- stable stamp identifier and texture;
- footprint dimensions and/or explicit cell mask;
- anchor cell;
- required terrain class and allowed biome IDs;
- facing and elevation bounds;
- deterministic placement weight;
- foliage and prop clearance behavior;
- presentation depth band.

`BiomeProfile` adds only `macro_stamp_families` and
`macro_stamp_min_region_cells`. It does not absorb biome classification,
surface gameplay authority, or weather.

### Production BACK-band depth vocabulary

The first production depth-chunk vocabulary is live in the existing terrain
stamp catalog. `TerrainStampProfile` now distinguishes `SURFACE` and `CHASM`
placement domains. CHASM profiles author a `chasm_core_rect`; they never infer
semantic coverage from texture alpha, own gameplay occupancy, or mutate the
32×32 world. They are restricted to the BACK band and to deterministic
`depth_south_edge` runs whose first chasm row provides placement anchors.

The approved families are `procgen_depth_universal`,
`procgen_depth_scrubland`, `procgen_depth_woodland`, and
`procgen_depth_chunks`. Scrubland enables universal plus its specific family;
Woodland enables universal, its specific family, and depth chunks; Wetland and
Rocky Upland enable universal plus depth chunks. At most eight depth stamps are
realized for one active procgen map.

The first Rocky Upland SURFACE production family is also live: ten authored
RGBA assets and ten explicit-mask profiles cover cliff/corner, shelf, and scree
compositions. Meridian Hardstand adds ten material-backed, biome-independent
SURFACE compositions. The terrain stamp catalog contains 36 profiles total:
16 CHASM/BACK depth profiles, 10 Rocky Upland SURFACE profiles, and 10 Meridian
Hardstand SURFACE profiles. Meridian is capped at two stamps per map; planner
budgets are eight CHASM, eight SURFACE, and sixteen total stamps.

The biome field is built after faction/story geometry, parking, final road
repair, and the final generated-state capture. It continues to run in candidate
evaluation, while macro Sprite2D realization runs only for direct final output
or accepted-candidate promotion.

## Generation Pipeline Target

1. Generate structure, connectivity, and intent.
2. Apply elevation and terrain semantics.
3. Classify the biome field.
4. Assign surface materials.
5. Extract contiguous presentation regions and explicit boundaries.
6. Fit deterministic macro compositions.
7. Fill remaining visible ground through existing material TileMaps.
8. Place clearance-aware environmental clusters.
9. Place minor, major, and rare hero landmarks.
10. Apply the existing lighting, atmosphere, and weather presentation.

## V1 Slice: Rocky Upland

The first implementation slice targets `terran_wet / rocky_upland` and should
prove one normal gameplay view containing:

- broad quiet natural ground;
- one large rocky escarpment;
- a small number of boulder/tree clusters;
- a weathered hardened road or apron;
- Ash Bell embedded in a memorable mountain composition.

The broader planned art vocabulary still enumerates 19 reusable assets:

- six cardinal/corner granite cliff masses;
- three large/small rock shelves;
- six boulder, pine-rock, and scrub-rock clusters;
- four rock-ground and scree overlays.

The first production subset resolves ten of those assets: six cliff/corner
masses, three shelves, and one scree overlay. Runtime art belongs
under `content/tiles/procgen_macro/runtime/rocky_upland/`; oversized masters
are retained through Asset Pipeline V2 source-work/archive provenance. The
remaining cluster and material-overlay vocabulary is still deferred.

Masks are authored resource data and are never inferred from PNG alpha.
`solid_mask_cells` must already map to wall/blocked/ledge/drop authority;
`walkable_overlay_cells` must already map to walkable floor. Empty reveal probes
resolve to the union of both masks.

## Migration Phases

| Phase | Deliverable | Status |
| --- | --- | --- |
| 0 | Contract hardening | VALIDATED |
| 1 | Rocky Upland macro composition | VALIDATED |
| 2a | Semantic surface materials | VALIDATED |
| 2b | Meridian hardstand and Road Semantics V2 | VALIDATED |
| 2c | Rocky Upland dressing cluster composition | VALIDATED (three proof profiles) |
| 3 | Landmark vocabulary | NEXT |
| 4 | Woodland, Wetland, and Scrubland surface expansion | DEFERRED |
| 5 | Environment and weather finish | DEFERRED |

### Phase 0 — Contract hardening (complete)

- Reconcile the forthcoming hardened implementation spec.
- Audit current terrain, biome, clearance, streaming, depth, and authored-claim
  APIs.
- Lock resource schemas, ownership boundaries, and migration order.

### Phase 1 — Deterministic rocky-upland composition

- Extract qualifying rocky-upland regions and cliff boundaries.
- Add profile/catalog/placer/composer foundations.
- Fit stamps without semantic mutation.
- Preserve existing TileMap fallback.
- Expose debug selection and rejection evidence.

### Phase 2c — Dressing cluster composition (validated)

Rocky Upland now has three deterministic data-only proof compositions, placed
after macro planning and before residual foliage. Cluster children reuse the
existing foliage renderer, material, collision, and bookkeeping paths. A
0.62 residual foliage multiplier applies only to Rocky Upland `natural_rock`;
the accepted-candidate promotion and streaming reveal paths use the same plan.
These are proof compositions rather than the final six-piece vocabulary.
Reusable natural-rock prop art is not approved, so true boulder clusters remain
deferred; no placeholder boulders are used.

Meridian hardstand and Road Semantics V2 are validated in Phase 2b. The existing
15-piece filled-surface road grammar is reused for local road presentation.

### Phase 3 — Landmark vocabulary (next)

- Add minor, major, and rare hero landmark placement contracts.
- Establish a target cadence of roughly one memorable feature per one to two
  screen widths without sacrificing combat readability.

### Phase 4 — Biome expansion (deferred)

- Extend archetype and asset families to woodland, wetland, and scrubland.
- Retain deterministic fallback when a biome lacks production art.

### Phase 5 — Environmental finish (deferred)

- Integrate day/night, weather, wet/snow/ash overlays, and landmark light
  anchors through existing environment authorities.

## Validation Intent

The planned focused smoke is:

```text
custodian/tools/validation/procgen_macro_presentation_smoke.gd
```

It must prove deterministic selection, footprint containment, required-cell
non-overlap, semantic terrain immutability, correct depth-root placement, and
fallback behavior when no asset fits. Existing terrain, elevation, route,
foliage, streaming, and procgen validation must remain green.

Visual acceptance requires a fixed-seed gameplay capture demonstrating the V1
composition target. Baselines may not be approved automatically.

## Deferred Beyond V1 Architecture

- additional rocky-upland vocabulary beyond the live ten-state production family;
- FRONT-band actor occlusion behavior;
- non-rocky biome catalogs;
- performance tuning informed by production texture/node counts;
- persistence beyond deterministic rebuild from accepted semantics.

## Next Agent Slice

Landmark Vocabulary V1. The three Rocky Upland dressing profiles are only
proof compositions; do not describe them as the complete six-piece cluster
vocabulary. The immediate next milestone is deterministic minor/major/hero
landmark placement without changing terrain authority or combat readability.

## Known visual debt

Gameplay screenshot dated 2026-09-27: two dark ruined-road areas in open
procgen ground read at current gameplay zoom as isolated rounded/blotchy patches
rather than remnants of a linear roadway. This is a presentation observation;
Road Semantics V2 remains valid and this cluster slice does not change road
generation or the 15-piece role grammar. Later review should distinguish road
texture/role art, short fragment geometry, and camera scale before proposing a
fix.
