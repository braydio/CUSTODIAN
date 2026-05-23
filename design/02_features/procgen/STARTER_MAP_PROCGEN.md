> This design document has a supporting reference at design/reference/STARTER_MAP_PROCGEN_REFERENCE.png
>
To procgen levels like that image, do **not** try to generate the whole illustrated blueprint. Generate a **semantic tile grid** from a **room-flow graph**, then render it through your Godot TileMap + props + encounter scenes. The image is basically a “starter maintenance complex profile”: entry → terminal → repair workshop → powered door/security corridor → exit.

Your repo guidance says active runtime is `custodian/`, Godot-native specs belong in `design/`, and runtime/architecture changes should update `custodian/docs/ai_context/` too.  The uploaded tree map confirms the repo has `custodian/`, content folders, dev tile material like `custodian/content/dev/in_progress/new_wall_tiles.png`, and tile/tooling material under `custodian/assets/tiles/`. 

## Main Map Road Surface Slice

The live contract map should also generate a modest functional road/path network outside the gothic compound using the resized road-piece exports at `custodian/content/tiles/roads_paths/runtime/roads/` and footpath exports at `custodian/content/tiles/roads_paths/runtime/paths/`. The exported pieces are variable-size road/path stamps mapped by `road_piece_manifest.game32.json` and `path_piece_manifest.game32.json`, not fixed `32x32` TileMap cells. The raw sheets, raw slices, and `Pathways.json` role map stay under `custodian/content/tiles/roads_paths/source/`. This is not the ornate connected-map gothic compound road grammar; it is a low-decoration tactical route pass that:

- carves a readable road from the player-side spawn area toward compound ingress and constructed-interior thresholds
- repairs the road graph after carving so spawn, edge access, compound ingress, connector end, and constructed-base thresholds stay in one connected road component
- keeps this road generation in the main contract map; the authored gothic compound submap keeps its own road grammar
- adds a long compound-connector road segment on the main map, running outward from the chosen compound ingress toward the generated map
- contains that connector with procgen wall rails so it reads as a walled approach instead of an open scatter path
- applies a deterministic elevation/ramp section to the connector after TerrainBuilder runs, using existing industrial elevation metadata and visuals
- widens a small parking-like apron beside the primary road
- marks road and parking cells as semantic movement surfaces
- leaves procedural floor cells on the default floor sources and overlays road art as manifest-selected `Sprite2D` stamps
- clears wall tiles, generated wall metadata, and runtime wall collision from road/parking cells after wall visuals and terrain builder have run
- keeps foliage/tree placement off road and parking cells, with only nearby natural scatter allowed
- gives the operator a small walking speed boost on road/path surfaces
- gives occupied vehicles a larger driving speed boost on road/path surfaces
- exposes parking cells in level data so `ContractWorldLoader` can place vehicles there before falling back to old compound placement

## Exact code files I would add

```txt
design/features/implementation/PROCGEN_MAINTENANCE_COMPLEX.md
design/features/implementation/PROCGEN_MAINTENANCE_COMPLEX_CODE.md
```

Use these as the implementation spec and copy-ready code proposal. This matches the repo workflow instead of burying rules only in runtime scripts.

```txt
custodian/game/world/procgen/data/maintenance_complex_profile.json
```

Defines the map family:

```json
{
  "id": "maintenance_complex_starter",
  "tile_size": 32,
  "map_size": [120, 120],
  "critical_flow": [
    "drop_zone",
    "central_terminal",
    "repair_workshop",
    "security_corridor",
    "hub_exit"
  ],
  "room_count_range": [5, 8],
  "primary_path_length_tiles": [75, 95],
  "threat_level": "low",
  "required_systems": [
    "movement",
    "interaction",
    "combat_basic",
    "door_power_gate",
    "repair",
    "exit"
  ]
}
```

```txt
custodian/game/world/procgen/data/room_archetypes.json
```

Defines room types and placement rules:

```json
{
  "drop_zone": {
    "size": [[15, 15], [22, 18]],
    "required_props": ["info_terminal", "tutorial_marker"],
    "enemy_budget": 0,
    "exits": ["east", "south"]
  },
  "central_terminal": {
    "size": [[18, 18], [26, 22]],
    "required_props": ["data_terminal", "locked_door_panel"],
    "enemy_budget": 1,
    "exits": ["west", "east", "south"]
  },
  "repair_workshop": {
    "size": [[15, 15], [22, 20]],
    "required_props": ["repair_workbench", "power_node"],
    "enemy_budget": 1,
    "exits": ["north", "east"]
  },
  "security_corridor": {
    "size": [[28, 6], [44, 10]],
    "required_props": ["access_door", "cover_low"],
    "enemy_budget": 2,
    "exits": ["west", "east"]
  },
  "hub_exit": {
    "size": [[14, 14], [20, 18]],
    "required_props": ["hub_exit_marker", "supply_crate"],
    "enemy_budget": 0,
    "exits": ["west", "south"]
  }
}
```

```txt
custodian/game/world/procgen/procgen_types.gd
```

Small shared constants/types: tile semantic IDs, room IDs, prop IDs, direction constants.

```txt
custodian/game/world/procgen/sector_graph_builder.gd
```

Builds the high-level flow graph. This is what makes the generated level feel like the blueprint instead of random rooms.

Responsibilities:

```txt
seed -> required flow rooms -> optional side rooms -> graph edges -> door/gate metadata
```

```txt
custodian/game/world/procgen/maintenance_complex_generator.gd
```

Main generator. Calls all passes and returns a generated layout object.

Pipeline:

```txt
load profile
build sector graph
place rooms
route corridors
stamp floors
stamp doors/thresholds
derive walls
scatter damage/debris/props
place enemies/objectives/exits
validate path
return map data
```

```txt
custodian/game/world/procgen/room_placer.gd
```

Places rectangular/asymmetric rooms on the 120×120 tile canvas while avoiding overlap.

```txt
custodian/game/world/procgen/corridor_router.gd
```

Connects rooms with readable 3–5 tile wide corridors. This is what creates the orange-dotted-path feel in the image.

```txt
custodian/game/world/procgen/wall_autotile_pass.gd
```

Takes the floor mask and creates walls, wall caps, inner corners, outer corners, broken wall sections, and doorway openings.

```txt
custodian/game/world/procgen/damage_overlay_pass.gd
```

Adds ruined/damaged sections: cracked floors, rubble clusters, broken walls, dark void edges, scuffed paths.

```txt
custodian/game/world/procgen/prop_placement_pass.gd
```

Places terminals, workbenches, crates, lockers, barrels, cable bundles, access panels, supply containers, etc.

```txt
custodian/game/world/procgen/encounter_placement_pass.gd
```

Places enemy spawns by room budget and prevents unfair placement near the player spawn.

```txt
custodian/game/world/procgen/procgen_validator.gd
```

Mandatory. Validates:

```txt
entry can reach terminal
terminal can reach repair workshop
repair workshop can unlock security corridor
security corridor can reach exit
no critical room is sealed
no door is placed without reachable access/power source
enemy spawn is not inside walls
hub exit exists
```

```txt
custodian/game/world/procgen/tile_palette.gd
```

Maps semantic tile names to actual Godot TileSet atlas coordinates.

Example:

```gdscript
const FLOOR_CONCRETE := {
    "source_id": 0,
    "atlas": Vector2i(0, 0)
}

const WALL_MILITARY_TOP := {
    "source_id": 11,
    "atlas": Vector2i(4, 0)
}
```

This file is critical because your generator should not directly hardcode atlas coords everywhere.

```txt
custodian/game/world/procgen/proc_gen_tilemap.gd
```

Modify existing file. It should become the renderer that receives generated map data and writes to TileMap layers.

Needed methods:

```gdscript
generate_from_profile(profile_id: String, seed: int) -> void
apply_generated_map(map_data: Dictionary) -> void
paint_floor(tile: Vector2i, semantic_id: String) -> void
paint_wall(tile: Vector2i, semantic_id: String) -> void
paint_overlay(tile: Vector2i, semantic_id: String) -> void
clear_runtime_map() -> void
```

```txt
custodian/game/world/procgen/proc_gen_map.tscn
```

Modify existing scene. It should contain the TileMaps and spawn containers:

```txt
ProcGenMap
├── FloorTileMap
├── WallTileMap
├── OverlayTileMap
├── NavigationRegion2D / navigation-backed TileMap setup
├── Props
├── Enemies
├── Interactables
├── DebugOverlay
└── ProcGenTilemap.gd
```

## Exact runtime scenes needed

```txt
custodian/game/interactables/dataterminal/DataTerminal.tscn
custodian/game/interactables/dataterminal/data_terminal.gd
```

For the blue terminal/info icons.

```txt
custodian/game/interactables/repair/RepairWorkbench.tscn
custodian/game/interactables/repair/repair_workbench.gd
```

For the repair objective room.

```txt
custodian/game/interactables/doors/PoweredDoor.tscn
custodian/game/interactables/doors/powered_door.gd
```

For locked access-control doors.

```txt
custodian/game/interactables/doors/AccessPanel.tscn
custodian/game/interactables/doors/access_panel.gd
```

For yellow key/access-control panels.

```txt
custodian/game/interactables/loot/SupplyCrate.tscn
custodian/game/interactables/loot/supply_crate.gd
```

For orange supply crates.

```txt
custodian/game/world/exits/HubExit.tscn
custodian/game/world/exits/hub_exit.gd
```

For the final exit-to-hub trigger.

```txt
custodian/game/spawning/EnemySpawnPoint.tscn
custodian/game/spawning/enemy_spawn_point.gd
```

For red enemy spawn markers / runtime spawn points.

## Exact tile assets needed

Minimum practical set:

```txt
custodian/content/tiles/interiors/runtime/floor_concrete_32.png
custodian/content/tiles/interiors/runtime/floor_concrete_32_b.png
custodian/content/tiles/interiors/runtime/floor_concrete_32_c.png
custodian/content/tiles/interiors/runtime/floor_panel_32.png
custodian/content/tiles/interiors/runtime/floor_grate_32.png
custodian/content/tiles/interiors/runtime/floor_damaged_32.png
custodian/content/tiles/interiors/runtime/floor_debris_32.png
custodian/content/tiles/interiors/runtime/threshold_metal_32.png
```

Walls:

```txt
custodian/content/tiles/interiors/runtime/wall_military_32.png
custodian/content/tiles/interiors/runtime/wall_military_top_32.png
custodian/content/tiles/interiors/runtime/wall_military_corner_inner_32.png
custodian/content/tiles/interiors/runtime/wall_military_corner_outer_32.png
custodian/content/tiles/interiors/runtime/wall_military_terminal_left_32.png
custodian/content/tiles/interiors/runtime/wall_military_terminal_right_32.png
custodian/content/tiles/interiors/runtime/wall_broken_32.png
custodian/content/tiles/interiors/runtime/wall_rubble_edge_32.png
```

Doors/openings:

```txt
custodian/content/tiles/interiors/runtime/doorway_military_32.png
custodian/content/tiles/interiors/runtime/door_locked_military_32.png
custodian/content/tiles/interiors/runtime/door_open_military_32.png
custodian/content/tiles/interiors/runtime/door_powered_frame_32.png
```

Overlays:

```txt
custodian/content/tiles/interiors/runtime/overlay_crack_01_32.png
custodian/content/tiles/interiors/runtime/overlay_crack_02_32.png
custodian/content/tiles/interiors/runtime/overlay_scuff_01_32.png
custodian/content/tiles/interiors/runtime/overlay_oil_stain_32.png
custodian/content/tiles/interiors/runtime/overlay_hazard_stripe_32.png
custodian/content/tiles/interiors/runtime/overlay_shadow_edge_32.png
```

## Exact prop assets needed

```txt
custodian/content/props/interiors/runtime/terminal_info_32x48.png
custodian/content/props/interiors/runtime/terminal_data_32x48.png
custodian/content/props/interiors/runtime/repair_workbench_64x48.png
custodian/content/props/interiors/runtime/access_panel_32x32.png
custodian/content/props/interiors/runtime/power_node_32x48.png
custodian/content/props/interiors/runtime/supply_crate_32x32.png
custodian/content/props/interiors/runtime/loot_container_32x32.png
custodian/content/props/interiors/runtime/crate_stack_32x32.png
custodian/content/props/interiors/runtime/barrel_32x32.png
custodian/content/props/interiors/runtime/locker_32x48.png
custodian/content/props/interiors/runtime/console_48x32.png
custodian/content/props/interiors/runtime/cable_bundle_32x32.png
custodian/content/props/interiors/runtime/hazard_marker_32x32.png
custodian/content/props/interiors/runtime/cover_low_32x32.png
custodian/content/props/interiors/runtime/rubble_pile_32x32.png
custodian/content/props/interiors/runtime/hub_exit_marker_32x48.png
```

## Exact TileMap layers

You want at least this:

```txt
Layer 0: Void / background darkness
Layer 1: Floor
Layer 2: Floor overlays / damage
Layer 3: Walls
Layer 4: Wall tops / occlusion caps
Layer 5: Door thresholds
Layer 6: Props static
Layer 7: Debug markers only in editor/dev mode
```

If you keep everything in one TileMap layer, this kind of map becomes painful fast.

## Exact generated map data shape

Have the generator output one dictionary like this:

```gdscript
{
    "seed": 12345,
    "profile_id": "maintenance_complex_starter",
    "size": Vector2i(120, 120),

    "floors": {
        Vector2i(10, 10): "floor_concrete",
        Vector2i(11, 10): "floor_concrete_b"
    },

    "walls": {
        Vector2i(10, 9): "wall_military_top",
        Vector2i(9, 10): "wall_military"
    },

    "overlays": {
        Vector2i(15, 16): "overlay_crack_01"
    },

    "rooms": [
        {
            "id": "drop_zone",
            "rect": Rect2i(12, 8, 20, 16),
            "tags": ["start", "tutorial"]
        }
    ],

    "doors": [
        {
            "id": "security_door_01",
            "tile": Vector2i(78, 55),
            "requires_power_from": "repair_workshop"
        }
    ],

    "props": [
        {
            "scene": "res://custodian/game/interactables/dataterminal/DataTerminal.tscn",
            "tile": Vector2i(20, 14),
            "id": "intro_terminal"
        }
    ],

    "enemy_spawns": [
        {
            "enemy_id": "basic_security_drone",
            "tile": Vector2i(62, 48),
            "room_id": "central_terminal"
        }
    ],

    "critical_flow": [
        "drop_zone",
        "central_terminal",
        "repair_workshop",
        "security_corridor",
        "hub_exit"
    ]
}
```

## Minimal implementation order

Build it in this order:

1. `tile_palette.gd`
2. `procgen_types.gd`
3. `room_archetypes.json`
4. `maintenance_complex_profile.json`
5. `sector_graph_builder.gd`
6. `room_placer.gd`
7. `corridor_router.gd`
8. `wall_autotile_pass.gd`
9. `procgen_validator.gd`
10. Update `proc_gen_tilemap.gd`
11. Add props/interactables
12. Add damage/decoration pass
13. Add enemy/encounter pass

That gets you the layout first, then the vibe.

## One-time scaffold command

Run this from repo root:

```bash
cd ~/Projects/CUSTODIAN

mkdir -p \
  design/features/implementation \
  custodian/game/world/procgen/data \
  custodian/game/interactables/dataterminal \
  custodian/game/interactables/repair \
  custodian/game/interactables/doors \
  custodian/game/interactables/loot \
  custodian/game/world/exits \
  custodian/game/spawning \
  custodian/content/tiles/interiors/runtime \
  custodian/content/props/interiors/runtime

touch \
  design/features/implementation/PROCGEN_MAINTENANCE_COMPLEX.md \
  design/features/implementation/PROCGEN_MAINTENANCE_COMPLEX_CODE.md \
  custodian/game/world/procgen/data/maintenance_complex_profile.json \
  custodian/game/world/procgen/data/room_archetypes.json \
  custodian/game/world/procgen/procgen_types.gd \
  custodian/game/world/procgen/tile_palette.gd \
  custodian/game/world/procgen/sector_graph_builder.gd \
  custodian/game/world/procgen/maintenance_complex_generator.gd \
  custodian/game/world/procgen/room_placer.gd \
  custodian/game/world/procgen/corridor_router.gd \
  custodian/game/world/procgen/wall_autotile_pass.gd \
  custodian/game/world/procgen/damage_overlay_pass.gd \
  custodian/game/world/procgen/prop_placement_pass.gd \
  custodian/game/world/procgen/encounter_placement_pass.gd \
  custodian/game/world/procgen/procgen_validator.gd \
  custodian/game/interactables/dataterminal/data_terminal.gd \
  custodian/game/interactables/repair/repair_workbench.gd \
  custodian/game/interactables/doors/powered_door.gd \
  custodian/game/interactables/doors/access_panel.gd \
  custodian/game/interactables/loot/supply_crate.gd \
  custodian/game/world/exits/hub_exit.gd \
  custodian/game/spawning/enemy_spawn_point.gd
```

## Documentation drift check

The uploaded `.tree-map.txt` looks stale/partial for this specific ask: it shows `custodian/`, addons, content/dev assets, and tile work, but the procgen runtime paths you have been working from recently are not visible in the uploaded tree snippet. Regenerate the tree before handing this to Codex:

```bash
cd ~/Projects/CUSTODIAN

tree -L 6 \
  -I ".godot|.import|addons|node_modules|.git" \
  > .tree-map.txt

grep -R \
  "proc_gen_tilemap.gd\|proc_gen_map.tscn\|dungeon_tileset.tres\|game/world/procgen" \
  .tree-map.txt custodian/docs/ai_context/FILE_INDEX.md custodian/docs/ai_context/CURRENT_STATE.md
```
