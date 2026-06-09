# Elevation Suite

Implementation status as of 2026-05-20: the metadata-first elevation slice is live under `custodian/game/world/elevation/` and `custodian/game/world/procgen/terrain/`. Clean runtime PNGs exist under `custodian/content/tiles/elevation/industrial/` and `custodian/content/tiles/mountain_cliffs/`; `procgen_world_tileset.tres` registers those tiles as source IDs `32..59`, and `ProcGenTilemap` maps terrain-builder symbolic tile IDs onto those sources. Remaining work is dedicated elevation/shadow layer separation if needed, movement/pathing enforcement beyond current spawn/prop filtering and contract scoring, and visual tuning in live maps.

Treat this tileset as a contained elevation module, not as a whole new terrain system yet. In CUSTODIAN terms: it becomes a raised industrial platform / ruined military slab kit that your procgen can stamp into rooms, roads, compounds, and exterior ruins.

Your repo guidance says active runtime is Godot under custodian/, active docs are custodian/docs/, and Godot-native specs should live under ./design/. ￼ So integrate this as a small vertical-slice feature, not a giant rewrite.

The right mental model

Separate the system into three layers:

1. Visual tile = what the player sees
2. Elevation data = what height the cell is
3. Traversal rule = whether actors can move between cells

Do not let the art itself decide movement. The tile image is just presentation. The actual gameplay should come from metadata:

cell height: 0, 1, 2, -1
cell traversal_type: flat, edge, ramp, stair, blocked, drop

Where this tileset fits

The generated sheet should become a source asset first:

custodian/content/tiles/elevation/elevation_industrial_source.png

Then slice/export clean runtime tiles into:

custodian/content/tiles/elevation/
├── ground_flat_32.png
├── elevated_floor_32.png
├── elevation_edge_north_32.png
├── elevation_edge_south_32.png
├── elevation_edge_east_32.png
├── elevation_edge_west_32.png
├── ramp_north_32.png
├── ramp_south_32.png
├── ramp_east_32.png
├── ramp_west_32.png
├── cliff_shadow_32.png
└── stair_metal_32.png

Your tree already has tile-related project structure under custodian/assets/tiles and broader runtime content under custodian/content/, so putting final game tiles under custodian/content/tiles/elevation/ keeps it aligned with the active Godot project. ￼

Important: do not use the generated sheet raw

The image is useful, but it is probably not actually clean 32×32 runtime art. It has spacing, scale drift, and likely fake checkerboard background. Treat it as a concept/source sheet.

Before Godot import:

1. Open in Aseprite.
2. Crop each tile manually.
3. Resize/redraw each to exact 32x32.
4. Remove checkerboard pixels if they are baked in.
5. Export individual PNGs.
6. Then build the Godot TileSet from those clean PNGs.

How elevation should work in-game

Ground tile

ground_flat_32.png
height = 0
traversal = flat

Normal walkable floor.

Elevated floor tile

elevated_floor_32.png
height = 1
traversal = flat

Walkable, but only reachable through ramp/stair access.

Edge tiles

elevation_edge_north_32.png
elevation_edge_south_32.png
elevation_edge_east_32.png
elevation_edge_west_32.png
height = 1
traversal = blocked_edge or ledge

These are not regular floors. They visually communicate the side of a raised platform. Most actors should not stand on them unless you intentionally make them walkable lip tiles.

Ramps

ramp_north_32.png
ramp_south_32.png
ramp_east_32.png
ramp_west_32.png
height = transition
traversal = ramp
direction = north/south/east/west

Ramps are the only normal way to move between height 0 and height 1.

Stairs

stair_metal_32.png
height = transition
traversal = stair

Use stairs for compound interiors, towers, hangar decks, and service walkways.

Cliff shadow

cliff_shadow_32.png
height = void/drop
traversal = blocked

Pure visual + blocker. Use under ledges, pits, broken slabs, sunken roads, chasms, industrial trenches.

Godot TileMap structure

Use multiple TileMap/TileMapLayer roles:

WorldRoot
├── GroundTileMap # normal floor/base terrain
├── ElevationTileMap # elevated floor, ledges, ramps, stairs
├── ShadowTileMap # cliff shadows/drop darkness
├── PropTileMap # crates, machines, consoles, cover props
└── Navigation/Elevation # script-owned metadata, not visual

Do not bake all of this into one visual layer yet. You will hate yourself when debugging pathing.

Add metadata through a script-owned elevation map

Create:

custodian/game/world/elevation/elevation_map.gd
extends Node
class_name ElevationMap
const DEFAULT_HEIGHT := 0
enu
