# Authored Tiled Room Pipeline

**Project:** CUSTODIAN  
**Status:** In Progress  
**Created:** 2026-03-26  
**Depends On:** `design/EDGAR_ROOM_TEMPLATE_SYSTEM.md`

## Purpose

Add a stable authored-room pipeline on top of the current Edgar/Tiled room-template work so designers can:

- build rooms in Tiled against a shared tileset
- place authored markers like spawns, terminals, and stairs
- export to a format the Godot runtime actually supports
- preserve authored metadata through room loading and layout assembly

## Supported Tiled Format

Only **`.tmj`** is supported.

- `.tmj` is Tiled JSON and matches the current Godot loader.
- `.tmx` is XML and is intentionally rejected.

If a room is authored in Tiled, it must be exported or saved as `.tmj`.

## Runtime Model

The current Godot runtime is still fundamentally 2D.

That means:

- stairs do **not** imply free Z-axis traversal
- stairs are authored **transitions between separate 2D floor maps**
- each floor remains its own room/template space

The intended production model is:

1. Author floor A as one `.tmj`
2. Author floor B as another `.tmj`
3. Place `stairs_up` / `stairs_down` markers in each
4. Link them by stair metadata

## Required Template Data

Each template must provide:

- `width`
- `height`
- tile layers for the room artwork
- map properties for room metadata and doors

Recommended tile layers:

- `Floor`
- `Walls`
- `Props`
- `Collision`

Recommended object layer:

- `Markers`

## Map Properties

Supported map properties:

| Property | Type | Purpose |
|---|---|---|
| `room_type` | string | semantic room category |
| `min_players` | int | minimum supported players |
| `max_players` | int | maximum supported players |
| `floor_index` | int | logical floor identifier |
| `template_family` | string | groups related floor/template variants |
| `doors_north` | string/array | north door definitions |
| `doors_south` | string/array | south door definitions |
| `doors_east` | string/array | east door definitions |
| `doors_west` | string/array | west door definitions |

Door properties should use JSON arrays:

```json
[{"x": 8, "width": 4}]
```

or

```json
[{"y": 6, "height": 3}]
```

## Marker Objects

Author gameplay markers on an object layer named `Markers`.

The loader resolves a marker's effective type from:

1. the object's `type`
2. otherwise the object's `name`

Supported marker types:

| Marker Type | Purpose |
|---|---|
| `player_spawn` | operator spawn tile for authored rooms |
| `terminal` | command terminal anchor |
| `enemy_spawn` | enemy spawn marker |
| `turret_mount` | authored turret mount/anchor |
| `stairs_up` | link to another floor/template above |
| `stairs_down` | link to another floor/template below |

## Stair Properties

Each `stairs_up` or `stairs_down` marker may define:

| Property | Type | Purpose |
|---|---|---|
| `stair_id` | string | local stair identifier |
| `target_template` | string | target room/template basename |
| `target_stair_id` | string | stair identifier in the destination template |
| `target_floor` | int | destination floor index |

This is enough to support explicit authored floor transitions without pretending the map is true 3D.

## Loader Output

The room loader should preserve:

- map properties
- tile layers
- object layers
- normalized markers
- normalized stairs
- shortcut fields:
  - `player_spawn`
  - `terminal_marker`
  - `enemy_spawns`
  - `turret_mounts`

Layout assembly should carry these fields forward into placed room instances.

## Notes

- Marker coordinates are interpreted in tile space.
- Authoring should assume 32x32 tiles unless the runtime tile size is intentionally changed.
- The first production consumer is authored room placement and floor transitions, not full 3D navigation.

## Next Steps

- consume authored markers in world placement/runtime systems
- use `player_spawn` and `terminal` from authored templates when present
- add authored stair transitions between separate room/floor maps
- optionally support authored sector markers and loot anchors later
