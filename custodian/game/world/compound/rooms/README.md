# Room Templates

This directory contains Tiled room templates for the Edgar-style procedural level generation.

## Supported Format

Use **`.tmj` only**.

- `.tmj` is Tiled JSON and is what the current Godot loader reads.
- `.tmx` is XML and is not supported by the current runtime.

## Quick Start

1. Open Tiled and create a new map, usually `20x15` tiles at `32x32px`.
2. Build the room on tile layers such as `Floor`, `Walls`, `Props`, and `Collision`.
3. Add door properties via Map → Map Properties:
   - `doors_north`: `[{"x": 8, "width": 4}]`
   - `doors_south`: `[{"x": 8, "width": 4}]`
   - `doors_east`: `[{"y": 6, "height": 3}]`
   - `doors_west`: `[{"y": 6, "height": 3}]`
4. Add room metadata:
   - `room_type`: `command_post`, `hangar`, `corridor`, `storage`, `landing_pad`
   - `min_players`: `1`
   - `max_players`: `4`
   - `floor_index`: `0`
   - `template_family`: optional grouping tag such as `command_deck`
5. Add an object layer named `Markers` for authored anchors.
6. Save/export as `.tmj` to `custodian/game/world/compound/rooms/templates/`.

## Room Types

| Type | Purpose | Required |
|------|---------|----------|
| command_post | Starting room, player spawn | Yes (1) |
| hangar | Combat encounters | No (2-4) |
| corridor | Connectivity | No (3-8) |
| storage | Loot rooms | No (1-2) |
| landing_pad | Extract points | No (1-2) |

## Door Format

```json
[
  {"x": 8, "width": 4}
]
```

- `x` or `y`: position of door (tile coordinate)
- `width` or `height`: size of door in tiles

Door properties should be JSON arrays. The loader also accepts older loose string formats, but JSON is the canonical path.

## Marker Object Layer

Create an object layer named `Markers`.

The loader resolves the marker type from the object `type` first, then falls back to `name`.

Supported marker types:

| Marker | Meaning |
|------|---------|
| `player_spawn` | authored operator spawn tile |
| `terminal` | command terminal anchor |
| `enemy_spawn` | enemy spawn marker |
| `turret_mount` | turret anchor |
| `stairs_up` | transition to a higher floor/template |
| `stairs_down` | transition to a lower floor/template |

## Stair Metadata

For `stairs_up` and `stairs_down`, add custom object properties as needed:

| Property | Type | Example |
|------|------|---------|
| `stair_id` | string | `alpha_up_01` |
| `target_template` | string | `command_post_upper` |
| `target_stair_id` | string | `alpha_down_01` |
| `target_floor` | int | `1` |

Important: stairs are currently authored transitions between separate 2D maps. They do not provide true freeform Z traversal in the live runtime.

## Template Naming

- `command_post.tmj`
- `hangar_large.tmj`
- `hangar_small.tmj`
- `corridor_h.tmj`
- `corridor_v.tmj`
- `storage.tmj`
- `landing_pad.tmj`

## Adding to the Graph

Edit `custodian/game/world/compound/rooms/graphs/default_compound.json` to:
- Add new room types
- Adjust room counts
- Modify connections

## Runtime Notes

The room loader now preserves:

- tile layers
- map properties
- object layers
- normalized markers
- normalized stairs
- shortcut fields such as `player_spawn`, `terminal_marker`, `enemy_spawns`, and `turret_mounts`

Layout assembly also carries those fields forward into placed room instances so authored metadata survives generation.
