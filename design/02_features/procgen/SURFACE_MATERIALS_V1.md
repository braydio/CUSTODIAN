# Procgen Surface Materials V1

Status: implementation

Surface materials classify final generated floor presentation without owning
floor membership, traversal, collision, navigation, elevation, biome, roads,
or topology. `ProcGenTilemap` resolves the read-only map after final terrain
and biome authority, before visual floor clustering.

## Precedence

Highest precedence wins: authored landmark/reserved surface, bridge, explicit
industrial/service hardstand, civic hardstand/parking/plaza, explicit ruined
road or connector, wet ground, Rocky Upland natural rock, then natural soft.
Only existing floor cells receive a material; walls and chasm remain untyped.

Road Semantics V2 derives intermittent ruined-road fragments from existing
route/playability cells and at most one site-adjacent service apron. Generic
`soft_path` and path-centerline metadata are not constructed-road authority;
they fall through to the biome's natural material unless a cell is explicitly
classified by the road resolver.

The first presentation seam is `NavigationRegion2D/SurfaceMaterialOverlay`, a
collision-free and navigation-free `TileMapLayer`. Meridian hardened-floor
art is a separate Asset Pipeline V2 family. The three 32px production atlases
are ingested; this slice adds ten larger Meridian macro compositions over the
same presentation-only material layer.

The live macro contract is 36 profiles total: 16 CHASM, 10 Rocky Upland
SURFACE, and 10 Meridian Hardstand SURFACE profiles. Meridian is global,
material-backed, and capped at two macro stamps per map. Planner budgets are
eight CHASM, eight SURFACE, and sixteen total stamps.

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
