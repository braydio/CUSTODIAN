# Special Room Insertion

## Status

Live V1 — 2026-06-24. No production special-room definitions are currently registered.

## Purpose

Special rooms are authored encounter scenes inserted into the generated contract map after a procgen layout has been accepted. They are not debug spawners and are not metadata-only story-room markers.

V1 preserves a deterministic insertion path for future encounters that genuinely belong inside a generated map. It is not the correct authority for fixed destinations with their own traversal, lifecycle, or route identity.

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

## Current Production Definitions

None.

## Retired Definition: Forlorn Ritualant

The former definition:

`res://content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json`

was deleted on 2026-07-30. The Forlorn-Ritualant is now a fixed authored Underground destination loaded through:

- level: `res://content/levels/ash_bell/forlorn_ritualant_underground.json`
- route: `res://content/routes/ash_bell/forlorn_ritualant_underground_route.json`
- scene: `res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn`

Procgen may place the exterior cave ingress, but it no longer inserts or clears a `35x27` encounter footprint.

## Non-goals

- Do not use special-room insertion for authored destinations that need route lifecycle or fixed spatial sequencing.
- Do not invent campaign completion flags in this V1.
- Do not convert `rarity` into probabilistic hiding yet; it is metadata for future weighting.
- Do not move gameplay/collision authority into JSON. Authored scenes and `ProcGenTilemap` remain the runtime authorities.

## Validation

Use:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/special_room_insertion_smoke.gd
godot --headless --path . --script res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd
```

With no registered production definitions, the generic smoke validates that contract generation remains healthy and that the Ritualant is never reported in `special_room_sites`. The focused Underground smoke validates its replacement authored level and route.
