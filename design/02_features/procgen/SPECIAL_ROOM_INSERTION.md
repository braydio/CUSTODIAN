# Special Room Insertion

## Status

Live V1 — 2026-06-24.

## Purpose

Special rooms are authored encounter scenes inserted into the generated contract map after a procgen layout has been accepted. They are not debug spawners and are not metadata-only story-room markers.

V1 exists to let authored encounters such as the Ash-Bell / Forlorn-Ritualant site appear in the normal main-game runtime while preserving deterministic procgen and existing gameplay authority.

## Runtime Contract

- Definitions live under `res://content/procgen/special_rooms/*.json`.
- Each definition declares at minimum:
  - `id`
  - `display_name`
  - `scene_path`
  - `size_tiles`
  - `max_instances_per_run`
  - optional `tags`, `rarity`, and `spawn_conditions` metadata
- `CustodianContractMap` owns when insertion happens:
  - generate candidate maps
  - choose the accepted/best map
  - insert special rooms into that accepted map
  - include `special_room_sites` in contract `level_data`
- `SpecialRoomRuntimeInserter` owns loading definitions, deterministic placement, footprint claiming, scene instancing, and inserted-site reporting.
- `ProcGenTilemap.claim_procgen_floor_rect_for_authored_scene_tiles(...)` remains the floor/wall/elevation authority boundary.

## Placement Rules

V1 placement is deterministic from the accepted map seed. A special room candidate must:

- be inside map bounds with margin
- be centered on a valid spawn/floor cell
- avoid protected center tiles such as walls, roads, parking, compound/interior/faction/story/special zones, and main route anchors
- avoid overlapping another special room claim

The full footprint does not need to already be walkable. The authored-footprint claim API intentionally clears procgen walls, road/decal authority, foliage, blocked elevation, and region metadata before forcing walkable authored floor authority.

## Current Live Definition

- `res://content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json`
  - scene: `res://game/world/events/ash_bell/forlorn_ritualant_site.tscn`
  - footprint: `35x27`
  - max instances per run: `1`

## Non-goals

- Do not invent campaign completion flags in this V1.
- Do not convert `rarity` into probabilistic hiding yet; it is metadata for future weighting.
- Do not move gameplay/collision authority into JSON. Authored scenes and `ProcGenTilemap` remain the runtime authorities.

## Validation

Use:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/special_room_insertion_smoke.gd
```

The smoke fails if contract generation completes without a `special_room_sites` entry.
