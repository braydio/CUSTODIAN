# PLACEHOLDER TILESET SOURCE RELOCATION TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Move the placeholder 0x72 tileset out of the repository-root `dev/` folder into a Godot-visible, tile-domain content directory and restore `procgen_world_tileset.tres` loading.

## Outcome

The placeholder atlas files used by the world TileSet now live under `res://content/tiles/source/placeholder-tileset/`, and the TileSet references that canonical location instead of the deleted `res://content/dev/placeholder-tileset/` path.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active runtime/docs files: `custodian/content/tiles/tilesets/procgen_world_tileset.tres`, `custodian/game/world/camera.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`

## Work Surface

- Changed: placeholder tileset file location, world TileSet external texture paths, camera procgen-bounds tile-size guard, AI context docs.
- Out of scope: redesigning TileSet source IDs or replacing the placeholder art with production tiles.

## Constraints

- Godot resources must be under `custodian/` to be addressable as `res://`.
- Runtime code should tolerate a temporarily missing TileSet without hard-crashing on camera bounds.

## Implementation Plan

1. Move `dev/placeholder-tileset` into `custodian/content/tiles/source/placeholder-tileset`.
2. Rewrite TileSet/import resource paths from `res://content/dev/placeholder-tileset/` to `res://content/tiles/source/placeholder-tileset/`.
3. Remove stale texture UID bindings from the moved placeholder atlas references so Godot resolves by the new path.
4. Guard camera bounds against a null `tile_set`.
5. Validate script parsing and headless scene loading.

## Acceptance

- `procgen_world_tileset.tres` no longer references `res://content/dev/placeholder-tileset/`.
- Procgen map scene loads headless without missing placeholder-atlas errors or `tile_set.is_null()` floods.
- Camera bounds no longer throws invalid `tile_size` access when a TileMapLayer has no TileSet.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does any design doc need an update? No.

## Completion Notes

- Implemented: moved placeholder tileset under `content/tiles/source`, updated TileSet/import paths, removed stale atlas UIDs, and added a camera fallback tile size.
- Validated: `godot --headless --check-only --script res://game/world/camera.gd`; `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --quit --scene res://game/world/procgen/proc_gen_map.tscn`.
- Deferred: full main-scene boot still has the existing headless exit leak warnings; no missing placeholder TileSet errors were seen after the relocation.

## Next Steps

- Next action: keep future source-only tile art under `custodian/content/tiles/source/` or another `custodian/content/tiles/*` directory, not repository-root `dev/`.
- Validation to run: `cd custodian && godot --headless --quit` after any further TileSet source moves.
