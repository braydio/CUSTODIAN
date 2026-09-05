# Procgen Native-32px Spatial Normalization

- **Status:** active implementation
- **Owner:** gameplay/procgen + gameplay/world
- **Runtime target:** Godot 4 (`custodian/`)
- **Active spec path:** `design/02_features/procgen/PROCGEN_32PX_SPATIAL_NORMALIZATION.md`
- **Related:** `custodian/docs/ai_context/task_packets/PROCGEN_32PX_SPATIAL_NORMALIZATION.md`

## The contract

```
PROCGEN_CELL_SIZE_PX = 32

one semantic procgen cell  =  32 x 32 Godot world pixels
TileSet logical tile size  =  32 x 32
ProcGenMap root scale      =  Vector2.ONE
```

This is the single spatial contract for the live procgen world. It replaces
the legacy scheme of a 16px logical `TileMap` grid multiplied by a
`ProcGenMap.scale = Vector2(2, 2)` root transform to reach the same 32
world-px-per-cell result. World coordinates did not change — only the
representation did: the doubling used to happen in the root transform, now it
happens nowhere, because the grid is natively 32px.

`custodian/game/world/procgen/procgen_spatial_contract.gd`
(`ProcgenSpatialContract`) is the single canonical fallback for this constant
(`CELL_SIZE_PX`, `CELL_SIZE`, `CELL_SIZE_I`, `HALF_CELL`). It exists only to
prevent a future 16/32 drift in the handful of defensive
`tile_set == null` fallback branches that predate a real TileSet being
assigned — it is not a coordinate service, and it must never replace an
appropriate `TileMap.map_to_local()` / `local_to_map()` call with manual
multiplication merely because the constant exists.

## Historical origin of the retired 2× scale

`git blame` / `git log -S 'scale = Vector2(2, 2)'` on
`custodian/game/world/procgen/proc_gen_map.tscn` both converge on a single
commit: `d16c2d7109` ("Track custodian Godot project [no-docs]",
2026-03-27) — a 3141-file bulk import of an already-built local Godot
project into this monorepo. No later commit ever touched the `scale`
property. At that same commit, the TileSet's floor/low-wall atlas sources
pointed at literally named `atlas_floor-16x16.png` /
`atlas_walls_low-16x16.png` (the `0x72_DungeonTilesetII_v1.7` placeholder
pack) with no `texture_region_size` override, and the TileSet's own
`tile_size` was also unset (implicit Godot default `16x16`). The root
`scale = Vector2(2, 2)` existed purely to make that genuinely-16px
placeholder grid land at 32 world px, matching other already-32px-native
content mixed into the same original file. **There is no documented,
deliberate design rationale for the 2× scale anywhere in this repository's
history — it was inherited from a bulk import, not decided.**

## What is prohibited

This contract is violated by any of the following, regardless of how locally
convenient it seems:

- **Root-scale compensation** — reintroducing `ProcGenMap.scale != Vector2.ONE`
  (or an equivalent wrapper node scale) to paper over an asset or formula that
  assumes the old 16px grid.
- **Camera zoom compensation** — adjusting camera zoom to make the map "look
  the old size" instead of fixing the actual spatial data.
- **Blanket child-scale compensation** — setting `scale = Vector2(2, 2)` (or
  its inverse) on `Floor`, `Walls`, `NavigationRegion2D`, or any other
  structural container node to compensate for a scale change made elsewhere.
- **Collision derived from visual scaling** — sizing `CollisionShape2D`/
  `NavigationPolygon` geometry by copying a rendered sprite's scaled size
  instead of deriving it from `TileSet.tile_size` / `TileMap.map_to_local()`.
- **Silently maintaining parallel 16px and 32px spatial contracts** — e.g. a
  fallback constant that still says 16 "just in case," or a new system that
  reads raw `TileSet.tile_size` in one place and `get_runtime_tile_size()` in
  another without a documented reason for the difference.

## TileSet inventory and disposition

`custodian/content/tiles/tilesets/procgen_world_tileset.tres` now declares an
explicit `tile_size = Vector2i(32, 32)` in its own `[resource]` block (it
previously had none, defaulting to Godot's implicit `16x16`). Every source
actually painted by the live `ProcGenMap` root already declared an explicit
`texture_region_size = Vector2i(32, 32)` and needed no further change:
`floor_source_id=10`, `walls_source_id=12`, all seven `interior_*` ids, and
everything the `TerrainTileIds` / Sundered Keep vista presentation code
addresses by name (ids 32-153: elevation, mountain-cliff, connector, ascent,
chasm-bridge, ocean, void-cliff-face packs).

| source_id | status | disposition |
|---|---|---|
| 0, 1, 4-9, 11 | UNUSED LEGACY | Default/unset `texture_region_size` (16×16) or an unreferenced 32×32 atlas; not wired to any live export or code path. Left in place, untouched — no live output depends on them. |
| 2 (`walls_high`, `atlas_walls_high-16x32.png`) | COMPATIBILITY-ONLY | Explicit `Vector2i(16, 32)` legacy dungeon asset. Only reachable via `high_walls_source_id`, which is never overridden on the live root node (falls back to script default `2`) — but `use_high_walls` defaults `false` and is never enabled anywhere in `proc_gen_map.tscn` (root or the disabled `"ProcGen"` compatibility child), so **this source cannot affect live output today.** Documented here rather than converted; promoting it to a real 32×32 asset is out of scope for a coordinate migration (no art redesign). |
| 3 (`"ProcGen"` compatibility child's `high_walls_source_id`) | COMPATIBILITY-ONLY | The `"ProcGen"` child node has `generation_output_enabled = false` — it never generates output at all. Its source configuration is dead by construction; do not let it dictate the live spatial architecture. |
| 10, 12, 16-31, 32-153 | LIVE | Already native 32×32 — no changes required for this migration. |

## What changed vs. what didn't

Nearly every tile↔world coordinate-conversion function in
`proc_gen_tilemap.gd` (`_global_to_tile`, `tile_to_global_position`,
`minimap_tile_to_global`, `global_to_minimap_tile`, `get_runtime_tile_size`,
`_tile_to_chunk`, the runtime wall/boundary collision call sites, and
`NavigationRegion2D.bake_navigation_polygon()`) already delegated to
`TileMapLayer.map_to_local/to_local/local_to_map/to_global` or
`tile_set.tile_size` and required **zero logic changes** — this migration
only had to change the underlying data (`TileSet.tile_size`,
`ProcGenMap.scale`) for those already-correct formulas to produce the native
result. `streaming_chunk_size_tiles` (16 tiles) and all chunk-index math stay
in tile units, unaffected by any pixel-size change, by design.

The edits that were required:

1. **Defensive `tile_set == null` fallback constants** (six sites in
   `proc_gen_tilemap.gd`, plus `shadow_system.gd`,
   `sundered_keep_world_vista.gd`, `sundered_keep_procgen_vista_presentation.gd`,
   `contract_world_loader.gd`, `world_ingress_spawner.gd`) — bumped from 16 to
   32. None of these branches execute in the live scene (a TileSet is always
   assigned); this is fallback-consistency hygiene, and in two cases
   (`contract_world_loader.gd`, `world_ingress_spawner.gd`) a pre-existing
   correctness fix, since the authored `Node2D` interior maps
   (`gothic_compound_map.gd`, `sundered_keep_map.gd`) already use
   `TILE_SIZE := 32.0`.
2. **Local-space presentation pixel constants under the (now-retired) scaled
   root** — `ShadowOverlay.shadow_offset_px` (6→12), `ShadowOverlay.edge_inset_px`
   (3→6), `horizontal_wall_endcap_vertical_jitter_px` (12→24), and the
   south-connector decorative sprite's footprint/offset (`Vector2(28, 48.5)`
   → `Vector2(56, 97)`, `-4.0` → `-8.0`). These are genuinely live constants
   drawn in local space under nodes that inherited the root's 2× scale with
   no scale of their own; left unchanged they would visibly halve on screen
   once the root scale is retired. Doubling preserves current appearance —
   this is the "map-local legacy pixel value whose previous effective world
   distance was intentionally doubled by the root" case, not an accidental
   art-scale artifact to discard.
3. **The TileSet's own `tile_size`** and **`ProcGenMap.scale`** — the two
   single-line changes that actually retire the legacy contract.

**Confirmed unaffected, no code change:** `ash_bell_threadway_causeway.gd`
already declares `SOURCE_TILE_SIZE := Vector2(32.0, 32.0)` and derives its
floor-sprite scale as `runtime_tile_size / SOURCE_TILE_SIZE` — this already
evaluated to `Vector2.ONE` before this migration (32/32) and continues to
after. The in-flight Macro Presentation V1 draft
(`procgen_macro_presentation_composer.gd`) reads its world scale dynamically
via `macro_presentation_back.global_transform.get_scale()` — it also required
zero code changes and now correctly resolves to `Vector2.ONE`.

## Design rule going forward

Gameplay geometry and world distances must remain stable across this kind of
migration. Accidental visual enlargement of native art caused solely by an
inherited root transform is not something to preserve — the correct fix is to
retire the transform, not to keep multiplying by it forever. Where a local
constant's *current* effective world size was a deliberate design choice
(shadows, decorative jitter), preserve that choice explicitly in the new
coordinate frame; where it was purely mechanical (the root scale existing
because 16px placeholder art needed doubling), let the removal of the root
scale be the whole fix.
