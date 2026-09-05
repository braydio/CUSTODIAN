# Procgen Macro Presentation System

Status: implementation

Last updated: 2026-09-04

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

The roots are live children of `NavigationRegion2D` on the scaled `ProcGenMap`
root. BACK/GROUND/FRONT use absolute z indices `-5/0/4`. V1 places BACK and
GROUND only. Spawned sprites compensate for the map's `Vector2(2, 2)` parent
scale, retain authored pivots, and use nearest filtering.

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

The initial planned art vocabulary currently enumerates 19 reusable assets:

- six cardinal/corner granite cliff masses;
- three large/small rock shelves;
- six boulder, pine-rock, and scrub-rock clusters;
- four rock-ground and scree overlays.

The hardened contract resolves this as 19 runtime assets. Runtime art belongs
under `content/tiles/procgen_macro/runtime/rocky_upland/`; oversized masters
belong under the sibling `source/rocky_upland/` domain. The catalog remains
empty-safe until approved art and explicit authored semantic masks exist.

Masks are authored resource data and are never inferred from PNG alpha.
`solid_mask_cells` must already map to wall/blocked/ledge/drop authority;
`walkable_overlay_cells` must already map to walkable floor. Empty reveal probes
resolve to the union of both masks.

## Migration Phases

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

### Phase 2 — Cluster and hardstand composition

- Replace visual confetti with clearance-aware cluster scenes.
- Generate meaningful road, apron, foundation, and service-lane shapes.
- Keep material tiles visually subordinate to macro composition.

### Phase 3 — Landmark vocabulary

- Add minor, major, and rare hero landmark placement contracts.
- Establish a target cadence of roughly one memorable feature per one to two
  screen widths without sacrificing combat readability.

### Phase 4 — Biome expansion

- Extend archetype and asset families to woodland, wetland, and scrubland.
- Retain deterministic fallback when a biome lacks production art.

### Phase 5 — Environmental finish

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

- production rocky-upland art and its explicit masks/pivots;
- FRONT-band actor occlusion behavior;
- non-rocky biome catalogs;
- performance tuning informed by production texture/node counts;
- persistence beyond deterministic rebuild from accepted semantics.

## Next Agent Slice

Goal: finish validation of the hardened runtime foundation, then populate the
empty-safe catalog only when approved rocky-upland production art exists.

Read first:

- this document;
- `custodian/docs/ai_context/task_packets/PROCGEN_MACRO_PRESENTATION_V1.md`;
- `design/02_features/procgen/ELEVATED_WORLD_PRESENTATION.md`;
- `design/02_features/procgen/TERRAIN_BUILDER_ELEVATION_INTEGRATION.md`;
- `design/02_features/environment/WORLD_ENVIRONMENT_BIOME_DAYNIGHT_WEATHER.md`;
- current procgen, biome, foliage-clearance, authored-claim, and streaming APIs.

Acceptance for that slice:

- focused and existing procgen validation remains green;
- candidate promotion and direct final generation agree on plan fingerprint;
- the first approved asset profiles have explicit semantic masks and pivots;
- a fixed-seed visual capture is reviewed without automatic baseline approval.
