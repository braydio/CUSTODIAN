# Procgen Surface Materials V1

Status: implementation

Surface materials classify final generated floor presentation without owning
floor membership, traversal, collision, navigation, elevation, biome, roads,
or topology.

For the current generated campaign world, material selection and authored replacement art must preserve the palette/composition authority in `FIRST_CAMPAIGN_WORLD_VISUAL_LOCK.md`: cold stone/earth, patchy snow/frost, restrained vegetation, weathered hardened civic/military surfaces, and faded ochre/amber route markings. `ProcGenTilemap` resolves the read-only map after final terrain
and biome authority, before visual floor clustering.

## Precedence

Highest precedence wins: authored landmark/reserved surface, bridge, explicit
industrial/service hardstand, civic hardstand/parking/plaza, ruined road or
explicit constructed-road classification, wet ground, Rocky Upland natural
rock, then natural soft. Generic `soft_path` and path-centerline metadata alone
do not classify a constructed road.
Only existing floor cells receive a material; walls and chasm remain untyped.

## Road Semantics V2

`ProcGenTilemap` runs the pure Road Semantics resolver after route/playability
and the existing archived-road refresh. It derives intermittent
`ruined_road` cells from already eligible route floor and a bounded
site-adjacent service apron. Connectivity remains route/playability-owned; the
resolver does not change floor/wall membership, route topology, elevation,
collision, or navigation. Generic `soft_path` retains the biome's natural
material unless independently marked as a road. Service-apron cells resolve to
`hardened_industrial`, and its parking export matches the apron.

Ruined fragments use the existing 15-piece 32px filled-surface road grammar as
presentation-only decals with a distinct `ruined_road` identity. The archived
wide-road generator remains opt-in through `intent_main_roads_enabled` and
production keeps it disabled. Soft paths keep their independent
connection-bitmask renderer. `SurfaceMaterialOverlay` continues to draw only
hardened civic/industrial base treatment; it does not render ruined-road art.
No new production road art is approved in this slice.

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
