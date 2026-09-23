# Procgen Surface Materials V1

Status: implementation

Surface materials classify final generated floor presentation without owning
floor membership, traversal, collision, navigation, elevation, biome, roads,
or topology. `ProcGenTilemap` resolves the read-only map after final terrain
and biome authority, before visual floor clustering.

## Precedence

Highest precedence wins: authored landmark/reserved surface, bridge, explicit
industrial/service hardstand, civic hardstand/parking/plaza, ruined road or
constructed path, wet ground, Rocky Upland natural rock, then natural soft.
Only existing floor cells receive a material; walls and chasm remain untyped.

The first presentation seam is `NavigationRegion2D/SurfaceMaterialOverlay`, a
collision-free and navigation-free `TileMapLayer`. Meridian hardened-floor
art is a separate Asset Pipeline V2 family and remains `SOURCE_PENDING` until
all three production atlases are supplied and ingested.

## Runtime

- `game/world/procgen/surfaces/surface_material_ids.gd` owns stable IDs.
- `game/world/procgen/surfaces/surface_material_resolver.gd` is pure data.
- `ProcGenTilemap` exports the material map, summary, and deterministic
  fingerprint through level data and debug accessors.
- Floor-value clusters skip constructed and authored material cells; natural
  material cells retain the existing visual-cluster policy.

## Validation

`tools/validation/procgen_surface_material_smoke.gd` proves precedence,
determinism, floor-only classification, semantic immutability, cluster policy,
and presentation-layer collision/navigation isolation.
