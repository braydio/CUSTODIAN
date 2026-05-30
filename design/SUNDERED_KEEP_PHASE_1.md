Start with **one playable production slice**, not the whole haunted planet castle. The right first slice is:

> **Main Gate → Courtyard → Great Hall → one stair up + one stair down + one cliff edge**

## Implementation status

Status: implemented as first runtime slice on 2026-05-30.

Runtime files:

- `custodian/game/world/sundered_keep/sundered_keep_map.gd`
- `custodian/content/tiles/sundered_keep/`
- `custodian/content/props/sundered_keep/`
- `custodian/content/levels/sundered_keep/sundered_keep_assets.json`
- `custodian/game/systems/core/systems/contract_world_loader.gd`

The current slice uses generated first-pass runtime PNGs and an authored connected-map script rather than a Godot `TileMapLayer`/`TileSet` resource. The node tree still follows the requested layer grammar names (`TerrainBase`, `TerrainEdges`, `WallsLow`, `WallsHigh`, `PropsStatic`, `PropsBlocking`, `Traversal`, `Hazards`, `Overlays`, `RoofOccluders`) and includes collision blockers, traversal stubs, camera bounds, entry travel, and return travel.

That slice proves almost every system you need: gothic walls, doors, cliffs, wet floors, props, collision, traversal, verticality, and mood.

# 0. Implementation target

Build this first:

```text
sundered_keep_v0
├── Main Gate
├── Courtyard
├── Great Hall
├── East Rampart stub
├── Lower stair placeholder
├── Upper stair placeholder
└── Ocean cliff boundary
```

Do **not** start with the full multi-floor map. Start with a complete **tile grammar** that can build the rest.

Recommended size for the first playable map:

```text
64 tiles wide × 44 tiles tall
32 px tiles
2048×1408 px total map footprint
```

---

# 1. Folder structure to create

Use a clean biome pack structure:

```bash
cd ~/Projects/CUSTODIAN

mkdir -p custodian/content/tiles/sundered_keep/{floors,walls,cliffs,doors,stairs,hazards,roofs,overlays}
mkdir -p custodian/content/props/sundered_keep/{courtyard,great_hall,gatehouse,chapel,library,dungeon,exterior,observatory}
mkdir -p custodian/content/levels/sundered_keep
mkdir -p custodian/content/levels/sundered_keep/runtime
mkdir -p custodian/content/levels/sundered_keep/source
mkdir -p design/20_levels/in_progress
```

Then create a design stub:

```bash
cat > design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md <<'EOF'
# The Sundered Keep Level Set

Status: draft

## Goal

A renaissance gothic castle level set on a mountainous ocean planet, using 32×32 production tileable assets, cliffs, storm overlays, multi-floor traversal, and haunted temporal anomalies.

## First Runtime Slice

Main Gate → Courtyard → Great Hall with cliff boundary, one upper traversal placeholder, and one lower traversal placeholder.

## Runtime Authority

Godot 4 runtime under custodian/.

## Asset Pack

custodian/content/tiles/sundered_keep/
custodian/content/props/sundered_keep/
custodian/content/levels/sundered_keep/
EOF
```

---

# 2. Tile size rules

Use these sizes consistently.

| Asset type          |                 Runtime size | Notes                                |
| ------------------- | ---------------------------: | ------------------------------------ |
| Floor tiles         |                      `32×32` | Tileable, no collision unless hazard |
| Wall base footprint |                 `32×32` cell | Collision lives in this cell         |
| Wall art            |           `32×64` or `32×96` | Extends upward visually              |
| Cliff edge tile     |                      `32×32` | Defines walkable edge                |
| Cliff face slice    |           `32×64` or `32×96` | Visual drop below edge               |
| Doors               |           `32×64` or `64×64` | Depends single/double                |
| Stairs              | `32×32`, `64×32`, or `32×64` | Directional                          |
| Small props         |                      `32×32` | Crates, candles, rubble              |
| Medium props        |           `64×32` or `64×64` | Tables, fountains, pews              |
| Large props         |            `96×64`, `128×64` | Great hall tables, gates             |
| Tall props          |             `32×64`, `64×96` | Statues, columns, banners            |

For your game, I would treat walls as **one tile of collision with tall art drawn above the occupied cell**. That keeps navigation and collision simple.

---

# 3. Start with the minimum production tile kit

You need three kits first:

1. **Ground/floor kit**
2. **Wall/edge kit**
3. **Traversal/door kit**

Props come after these, because props are useless if the room grammar does not work.

---

# 4. First floor tiles to make

Create these first. These are enough to build the Main Gate, Courtyard, Great Hall, and cliff edge.

## Core floors

```text
main_courtyard_flagstone_01.png
main_courtyard_flagstone_02.png
main_courtyard_flagstone_cracked_01.png
main_courtyard_flagstone_cracked_02.png
main_courtyard_flagstone_wet_01.png
main_courtyard_flagstone_mossy_01.png
main_gate_threshold_stone_01.png
great_hall_marble_floor_01.png
great_hall_marble_floor_cracked_01.png
great_hall_marble_floor_wet_01.png
great_hall_carpet_runner_vertical_01.png
great_hall_carpet_runner_horizontal_01.png
```

## Exterior / cliff floors

```text
cliff_rock_floor_01.png
cliff_rock_floor_cracked_01.png
cliff_rock_floor_mossy_01.png
rampart_walkway_floor_01.png
rampart_walkway_wet_01.png
ocean_void_01.png
```

## Overlays

```text
rain_puddle_overlay_01.png
rain_puddle_overlay_02.png
storm_splash_overlay_01.png
moss_overlay_01.png
crack_overlay_01.png
temporal_echo_overlay_01.png
```

For the first implementation, make floors **simple but readable**. Do not over-detail every tile. You need tile repetition to look intentional.

---

# 5. First wall kit to make

This is the most important part. Build a modular gothic castle wall kit before making unique buildings.

## A. Exterior gothic castle wall kit

This is your main castle wall family.

```text
gothic_castle_wall_straight_n.png
gothic_castle_wall_straight_e.png
gothic_castle_wall_straight_s.png
gothic_castle_wall_straight_w.png

gothic_castle_wall_inner_corner_ne.png
gothic_castle_wall_inner_corner_nw.png
gothic_castle_wall_inner_corner_se.png
gothic_castle_wall_inner_corner_sw.png

gothic_castle_wall_outer_corner_ne.png
gothic_castle_wall_outer_corner_nw.png
gothic_castle_wall_outer_corner_se.png
gothic_castle_wall_outer_corner_sw.png

gothic_castle_wall_endcap_n.png
gothic_castle_wall_endcap_e.png
gothic_castle_wall_endcap_s.png
gothic_castle_wall_endcap_w.png
```

## B. Damaged wall variants

You need these immediately because the castle should feel ruined.

```text
gothic_castle_wall_damaged_n.png
gothic_castle_wall_damaged_e.png
gothic_castle_wall_damaged_s.png
gothic_castle_wall_damaged_w.png

gothic_castle_wall_breach_n.png
gothic_castle_wall_breach_e.png
gothic_castle_wall_breach_s.png
gothic_castle_wall_breach_w.png

gothic_castle_wall_window_tall_n.png
gothic_castle_wall_window_tall_e.png
gothic_castle_wall_window_tall_s.png
gothic_castle_wall_window_tall_w.png

gothic_castle_wall_arch_n.png
gothic_castle_wall_arch_e.png
gothic_castle_wall_arch_s.png
gothic_castle_wall_arch_w.png
```

## C. Great Hall wall kit

Make this slightly richer than the generic wall kit.

```text
great_hall_wall_straight_n.png
great_hall_wall_straight_e.png
great_hall_wall_straight_s.png
great_hall_wall_straight_w.png

great_hall_wall_column_n.png
great_hall_wall_column_e.png
great_hall_wall_column_s.png
great_hall_wall_column_w.png

great_hall_wall_banner_n.png
great_hall_wall_banner_e.png
great_hall_wall_banner_s.png
great_hall_wall_banner_w.png

great_hall_wall_broken_exterior_n.png
great_hall_wall_broken_exterior_e.png
great_hall_wall_broken_exterior_s.png
great_hall_wall_broken_exterior_w.png
```

## D. Rampart/parapet kit

Needed for cliffside castle edges and upper paths.

```text
rampart_parapet_n.png
rampart_parapet_e.png
rampart_parapet_s.png
rampart_parapet_w.png

rampart_crenellation_n.png
rampart_crenellation_e.png
rampart_crenellation_s.png
rampart_crenellation_w.png

rampart_broken_gap_n.png
rampart_broken_gap_e.png
rampart_broken_gap_s.png
rampart_broken_gap_w.png

rampart_corner_ne.png
rampart_corner_nw.png
rampart_corner_se.png
rampart_corner_sw.png
```

---

# 6. Cliff and ocean boundary tiles

The castle only works if the landmass edge is readable. Make cliffs before making fancy props.

```text
cliff_edge_n.png
cliff_edge_e.png
cliff_edge_s.png
cliff_edge_w.png

cliff_inner_corner_ne.png
cliff_inner_corner_nw.png
cliff_inner_corner_se.png
cliff_inner_corner_sw.png

cliff_outer_corner_ne.png
cliff_outer_corner_nw.png
cliff_outer_corner_se.png
cliff_outer_corner_sw.png

cliff_face_slice_01.png
cliff_face_slice_02.png
cliff_face_slice_wet_01.png
cliff_face_slice_mossy_01.png

ocean_foam_edge_n.png
ocean_foam_edge_e.png
ocean_foam_edge_s.png
ocean_foam_edge_w.png

ocean_dark_water_01.png
ocean_dark_water_02.png
ocean_whitecap_01.png
ocean_whitecap_02.png
```

For collision:

- `cliff_edge_*` = walkable if it is the top ledge.
- `cliff_face_*` = non-walkable visual.
- `ocean_*` = non-walkable lethal/fall hazard.

---

# 7. Doors, gates, stairs, traversal

You need these in the first pass so the map can become an actual level instead of a painting.

```text
main_gate_portcullis_closed.png
main_gate_portcullis_open.png

gothic_double_door_closed_n.png
gothic_double_door_open_n.png
gothic_double_door_closed_s.png
gothic_double_door_open_s.png

gothic_single_door_closed_n.png
gothic_single_door_open_n.png
gothic_single_door_closed_s.png
gothic_single_door_open_s.png

stone_stairs_up_n.png
stone_stairs_up_e.png
stone_stairs_up_s.png
stone_stairs_up_w.png

stone_stairs_down_n.png
stone_stairs_down_e.png
stone_stairs_down_s.png
stone_stairs_down_w.png

floor_hatch_closed_01.png
floor_hatch_open_01.png
ladder_wall_n.png
ladder_wall_s.png
```

For the first vertical slice, you only need:

```text
main_gate_portcullis_closed.png
main_gate_portcullis_open.png
gothic_double_door_closed_n.png
gothic_double_door_open_n.png
stone_stairs_up_n.png
stone_stairs_down_s.png
floor_hatch_closed_01.png
```

---

# 8. First props to make

Do not make every prop category yet. Make only the props that define gameplay spaces.

## Courtyard props

```text
prop_courtyard_fountain_broken_01.png        # 96×96, blocking center
prop_gothic_statue_broken_01.png             # 64×64, blocker
prop_gothic_statue_intact_01.png             # 64×96, blocker
prop_broken_cart_01.png                      # 64×32, cover
prop_crate_stack_wet_01.png                  # 32×32 or 64×32, cover
prop_barrel_wet_01.png                       # 32×32, cover/destructible
prop_fallen_masonry_01.png                   # 64×32, blocker
prop_low_garden_wall_01.png                  # 64×32, low cover
```

## Gatehouse props

```text
prop_gate_winch_01.png                       # 64×64, interactable
prop_murder_hole_marker_01.png               # 32×32, decorative/hazard
prop_portcullis_chain_01.png                 # 32×64, decorative
prop_gate_barricade_01.png                   # 64×32, blocker
prop_torch_wall_gothic_01.png                # 32×64, light source
```

## Great Hall props

```text
prop_banquet_table_long_01.png               # 128×32, cover
prop_banquet_table_broken_01.png             # 96×32, cover
prop_great_hall_column_01.png                # 32×64 or 64×96, blocker
prop_fallen_chandelier_01.png                # 96×64, blocker/hazard
prop_throne_ruined_01.png                    # 64×64, blocker/story
prop_brazier_iron_01.png                     # 32×32, light/hazard
prop_banner_torn_large_01.png                # 32×96, wall decoration
```

## Exterior / cliff props

```text
prop_gargoyle_perch_01.png                   # 32×64, blocker/decor
prop_lightning_rod_01.png                    # 32×64, hazard marker
prop_rope_bridge_anchor_01.png               # 32×32, traversal dressing
prop_sea_spray_rock_01.png                   # 32×32, decorative
prop_broken_spire_chunk_01.png               # 64×64, blocker
```

That gives you roughly **28 props**. That is enough for a convincing first slice.

---

# 9. First map layout to build

Use this rough layout:

```text
┌────────────────────────────────────────────────────────────────┐
│ Ocean / cliff void                                             │
│     ┌───────────── East Rampart Stub ─────────────┐             │
│     │                                             │             │
│ ┌───┴─────────────── Great Hall ──────────────────┴─────┐       │
│ │ columns     tables      central aisle        dais      │       │
│ │ columns     tables      broken chandelier    throne    │       │
│ └───────────────┬───────────────────────────────┬────────┘       │
│                 │                               │                │
│        upper stair placeholder          locked keep door          │
│                 │                                                │
│ ┌───────────────┴──────────── Courtyard ─────────────────┐       │
│ │ broken statue     fountain       wet flagstone          │       │
│ │ crates            carts          low walls              │       │
│ │ side hatch down                  rampart stairs         │       │
│ └───────────────┬─────────────────────────────────────────┘       │
│                 │                                                │
│          Main Gate / Portcullis                                  │
│                 │                                                │
│          Spawn / approach bridge                                 │
└────────────────────────────────────────────────────────────────┘
```

Recommended tile dimensions:

```text
Main Gate:      14×8 tiles
Courtyard:      28×20 tiles
Great Hall:     24×16 tiles
Rampart stub:   18×6 tiles
Cliff boundary: 4–8 tiles deep around the east/north edge
```

---

# 10. Godot TileMap layers

Use multiple layers instead of one monster TileMap.

```text
TerrainBase
TerrainEdges
WallsLow
WallsHigh
PropsStatic
PropsBlocking
Traversal
Hazards
Overlays
RoofOccluders
```

## Layer usage

### `TerrainBase`

Floors:

```text
flagstone
marble
rock
roof
water
```

### `TerrainEdges`

Cliff edges, ocean edges, drop shadows.

### `WallsLow`

Wall collision base. Mostly 32×32 logical cells.

### `WallsHigh`

Tall wall art, upper wall caps, arches, windows, banners.

### `PropsStatic`

Non-blocking decoration.

### `PropsBlocking`

Tables, statues, columns, rubble, barricades.

### `Traversal`

Doors, stairs, hatches, ladders, bridges.

### `Hazards`

Lightning targets, temporal rifts, deep water, wind gusts.

### `Overlays`

Rain puddles, cracks, moss, blood, temporal glow.

---

# 11. Tile custom data you should define

In the Godot TileSet, add custom data fields like:

```text
walkable: bool
blocks_movement: bool
blocks_projectile: bool
fall_hazard: bool
water_hazard: bool
slows_movement: bool
cover_type: String
elevation_level: int
traversal_target: String
destructible: bool
```

Example values:

```text
main_courtyard_flagstone_01
walkable = true
blocks_movement = false
elevation_level = 0
```

```text
gothic_castle_wall_straight_n
walkable = false
blocks_movement = true
blocks_projectile = true
elevation_level = 0
```

```text
cliff_edge_n
walkable = true
fall_hazard = false
elevation_level = 0
```

```text
ocean_void_01
walkable = false
fall_hazard = true
water_hazard = true
```

```text
prop_banquet_table_long_01
walkable = false
blocks_movement = true
blocks_projectile = false
cover_type = low
destructible = true
```

---

# 12. Suggested manifest format

Create:

```text
custodian/content/levels/sundered_keep/sundered_keep_assets.json
```

Use this structure:

```json
{
  "level_pack": "sundered_keep",
  "tile_size": 32,
  "biome": "sundered_keep",
  "tiles": {
    "floors": [
      {
        "id": "main_courtyard_flagstone_01",
        "path": "custodian/content/tiles/sundered_keep/floors/main_courtyard_flagstone_01.png",
        "size": [32, 32],
        "walkable": true
      }
    ],
    "walls": [
      {
        "id": "gothic_castle_wall_straight_n",
        "path": "custodian/content/tiles/sundered_keep/walls/gothic_castle_wall_straight_n.png",
        "size": [32, 64],
        "collision_cell": [32, 32],
        "blocks_movement": true,
        "blocks_projectile": true
      }
    ],
    "props": [
      {
        "id": "prop_banquet_table_long_01",
        "path": "custodian/content/props/sundered_keep/great_hall/prop_banquet_table_long_01.png",
        "size": [128, 32],
        "blocks_movement": true,
        "cover_type": "low",
        "destructible": true
      }
    ]
  }
}
```

---

# 13. Implementation order

## Phase 1 — Build the tile grammar

Make only these:

```text
12 floor tiles
24 gothic wall tiles
12 cliff/ocean tiles
8 door/traversal tiles
10 props
```

Goal: confirm the map can be built cleanly.

## Phase 2 — Build the first playable room chain

Build:

```text
Main Gate
Courtyard
Great Hall
```

Do not add chapel, library, observatory, dungeon, rooftops yet.

## Phase 3 — Add gameplay blockers

Add:

```text
fountain
statues
tables
columns
barricades
rubble
crates
barrels
```

Then check:

```text
Can the player path through it?
Do enemies navigate around props?
Are cover objects readable?
Are cliff edges obvious?
Are doors readable?
```

## Phase 4 — Add vertical stubs

Add fake/stub transitions:

```text
stair_up_to_upper_01
stair_down_to_lower_01
floor_hatch_to_undercroft_01
rampart_bridge_exit_01
```

They do not need destination maps yet. They just need to exist visually and structurally.

## Phase 5 — Expand into floors

Only after the first slice works:

```text
Lower Level 1: barracks/storage
Lower Level 2: dungeon/service works
Upper Level 1: chapel/library/ramparts
Upper Level 2: observatory/keep
Rooftops: bell tower/spires
Detached: lighthouse/arena/grotto
```

---

# 14. Minimum complete asset checklist

This is the smallest set I would make before calling it a real biome kit.

## Floors — 18

```text
main_courtyard_flagstone_01.png
main_courtyard_flagstone_02.png
main_courtyard_flagstone_cracked_01.png
main_courtyard_flagstone_wet_01.png
main_courtyard_flagstone_mossy_01.png
main_gate_threshold_stone_01.png
great_hall_marble_floor_01.png
great_hall_marble_floor_cracked_01.png
great_hall_carpet_runner_vertical_01.png
great_hall_carpet_runner_horizontal_01.png
rampart_walkway_floor_01.png
rampart_walkway_broken_01.png
cliff_rock_floor_01.png
cliff_rock_floor_cracked_01.png
roof_slate_dark_01.png
dungeon_stone_floor_01.png
undercroft_wet_stone_floor_01.png
ocean_void_01.png
```

## Walls — 48 minimum

```text
gothic_castle_wall_straight_n/e/s/w.png
gothic_castle_wall_inner_corner_ne/nw/se/sw.png
gothic_castle_wall_outer_corner_ne/nw/se/sw.png
gothic_castle_wall_endcap_n/e/s/w.png
gothic_castle_wall_damaged_n/e/s/w.png
gothic_castle_wall_breach_n/e/s/w.png
gothic_castle_wall_window_tall_n/e/s/w.png
gothic_castle_wall_arch_n/e/s/w.png

great_hall_wall_straight_n/e/s/w.png
great_hall_wall_column_n/e/s/w.png
great_hall_wall_banner_n/e/s/w.png
great_hall_wall_broken_exterior_n/e/s/w.png

rampart_parapet_n/e/s/w.png
rampart_crenellation_n/e/s/w.png
rampart_broken_gap_n/e/s/w.png
```

## Cliffs / ocean — 20

```text
cliff_edge_n/e/s/w.png
cliff_inner_corner_ne/nw/se/sw.png
cliff_outer_corner_ne/nw/se/sw.png
cliff_face_slice_01.png
cliff_face_slice_wet_01.png
cliff_face_slice_mossy_01.png
ocean_foam_edge_n/e/s/w.png
ocean_dark_water_01.png
```

## Doors / traversal — 14

```text
main_gate_portcullis_closed.png
main_gate_portcullis_open.png
gothic_double_door_closed_n.png
gothic_double_door_open_n.png
gothic_double_door_closed_s.png
gothic_double_door_open_s.png
stone_stairs_up_n.png
stone_stairs_up_e.png
stone_stairs_up_s.png
stone_stairs_up_w.png
stone_stairs_down_n.png
stone_stairs_down_s.png
floor_hatch_closed_01.png
floor_hatch_open_01.png
```

## Props — 28

```text
prop_courtyard_fountain_broken_01.png
prop_gothic_statue_broken_01.png
prop_gothic_statue_intact_01.png
prop_broken_cart_01.png
prop_crate_stack_wet_01.png
prop_barrel_wet_01.png
prop_fallen_masonry_01.png
prop_low_garden_wall_01.png

prop_gate_winch_01.png
prop_portcullis_chain_01.png
prop_gate_barricade_01.png
prop_torch_wall_gothic_01.png

prop_banquet_table_long_01.png
prop_banquet_table_broken_01.png
prop_great_hall_column_01.png
prop_fallen_chandelier_01.png
prop_throne_ruined_01.png
prop_brazier_iron_01.png
prop_banner_torn_large_01.png

prop_gargoyle_perch_01.png
prop_lightning_rod_01.png
prop_rope_bridge_anchor_01.png
prop_sea_spray_rock_01.png
prop_broken_spire_chunk_01.png

prop_bookshelf_tall_01.png
prop_chapel_pew_01.png
prop_sarcophagus_01.png
prop_telescope_broken_01.png
```

Total first serious kit:

```text
18 floors
48 walls
20 cliff/ocean tiles
14 traversal tiles
28 props
= 128 runtime assets
```

That sounds like a lot, but it is the right size for a reusable biome.

---

# 15. What I would make first today

Make this exact first batch:

```text
main_courtyard_flagstone_01.png
main_courtyard_flagstone_cracked_01.png
main_courtyard_flagstone_wet_01.png
great_hall_marble_floor_01.png
great_hall_carpet_runner_vertical_01.png
cliff_rock_floor_01.png
ocean_void_01.png

gothic_castle_wall_straight_n.png
gothic_castle_wall_straight_e.png
gothic_castle_wall_straight_s.png
gothic_castle_wall_straight_w.png
gothic_castle_wall_inner_corner_ne.png
gothic_castle_wall_inner_corner_nw.png
gothic_castle_wall_inner_corner_se.png
gothic_castle_wall_inner_corner_sw.png
gothic_castle_wall_outer_corner_ne.png
gothic_castle_wall_outer_corner_nw.png
gothic_castle_wall_outer_corner_se.png
gothic_castle_wall_outer_corner_sw.png

cliff_edge_n.png
cliff_edge_e.png
cliff_edge_s.png
cliff_edge_w.png
cliff_face_slice_01.png
ocean_foam_edge_n.png
ocean_foam_edge_e.png
ocean_foam_edge_s.png
ocean_foam_edge_w.png

main_gate_portcullis_closed.png
gothic_double_door_closed_n.png
stone_stairs_up_n.png
stone_stairs_down_s.png

prop_courtyard_fountain_broken_01.png
prop_banquet_table_long_01.png
prop_gothic_statue_broken_01.png
prop_gate_barricade_01.png
prop_great_hall_column_01.png
```

That is **34 assets**. With those, you can build the first playable mockup.

---

# 16. Practical build sequence

Do it in this order:

```text
1. Create folder structure.
2. Create design stub.
3. Generate/slice first 34 assets.
4. Import into Godot.
5. Create TileSet resource.
6. Add custom data fields.
7. Build 64×44 test map.
8. Add collision.
9. Add navigation.
10. Add player spawn.
11. Add 2–3 enemy spawns.
12. Add one locked gate.
13. Add one upper stair marker.
14. Add one lower stair marker.
15. Playtest readability.
```

Do not move to chapel/library/dungeon until this loop feels good.

---

# 17. First sanity checklist

When the first slice is in Godot, check these before expanding:

```text
Can I instantly tell what is floor vs wall?
Can I tell what is cliff vs walkable rock?
Can I tell which objects block movement?
Can enemies path around courtyard props?
Do tall walls visually sort correctly?
Do doors read as interactable?
Do stairs read as traversal?
Does the storm/ocean mood work without making the floor unreadable?
Do repeated tiles look intentional rather than copy-pasted?
```

The biggest risk is not asset quantity. The biggest risk is **tile grammar confusion**: walls, cliffs, tall props, and elevation all competing visually. Solve that first with the Main Gate/Courtyard/Great Hall slice.
