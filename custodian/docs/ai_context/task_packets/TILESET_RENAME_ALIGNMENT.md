# TILESET RENAME ALIGNMENT

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-05
- Created: 2026-05-05
- Last updated: 2026-05-05

## Task

Rename the active runtime TileSet away from the stale `dungeon_tileset.tres` name and update active scene, design, and documentation references.

## Outcome

The canonical world/procgen TileSet is named `custodian_world_tileset.tres`, and no active `custodian/` or `design/` reference points at `dungeon_tileset.tres`.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/features/implementation/PROCGEN_WALL_TILE_BRIDGE.md`, `design/02_features/procgen/*`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_map.tscn`, `custodian/game/world/tilemaps/test_map.tscn`, `custodian/docs/TILEMAP_REFERENCE.md`
- Historical reference only: legacy Python runtime and legacy design archives

## Work Surface

- Files or folders changed: TileSet resource filename, scene references, tile/procgen docs, AI context packet/index files
- Files or folders read but not changed: `custodian/AGENTS.md`, AI context current state/index, procgen scene refs
- Out-of-scope areas: Tile atlas contents, TileSet source IDs, wall generation behavior

## Constraints

- Determinism concerns: none; this is a resource path migration only.
- Simulation/UI boundary concerns: none.
- Asset requirements: preserve the existing TileSet UID and contents.
- Compatibility or migration concerns: update all text references in active runtime and docs; scene references resolve the TileSet by explicit path so a stale local Godot UID cache cannot redirect the renamed resource to the old path.
- Clarifying questions or assumptions: `custodian_world_tileset.tres` is the aligned canonical name because the resource is used by world/procgen maps, not only dungeon content.

## Implementation Plan

1. Rename active and dev TileSet resources to `custodian_world_tileset.tres`.
2. Update active scenes and documentation references.
3. Search for stale old-name references and run headless Godot validation.

## Acceptance

- Runtime behavior: scenes load the renamed TileSet.
- Documentation: active docs and AI context point to the aligned filename.
- Path/reference validation: no stale runtime, scene, or active design reference loads `dungeon_tileset.tres`; remaining mentions only document the retired name.
- Manual validation: inspect procgen/test map scene external resources.
- Automated/headless validation: `godot --headless --path custodian --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes, add canonical TileSet path note.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, index the canonical TileSet path.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, update stale TileSet path mentions.

## Completion Notes

- Implemented: active/dev TileSet resources renamed to `custodian_world_tileset.tres`; scene and docs references updated; scene TileSet references now resolve by explicit path to avoid stale local UID-cache redirects.
- Validated: stale old-name search completed; `godot --headless --path custodian --quit` loads without missing TileSet errors.
- Deferred: none.

## Next Steps

- Next action: use `custodian/content/tiles/tilesets/custodian_world_tileset.tres` for world/procgen TileSet work.
- Best starting files: `custodian/docs/TILEMAP_REFERENCE.md`, `custodian/game/world/procgen/proc_gen_map.tscn`
- Required context: procgen wall bridge docs and tilemap reference.
- Validation to run: `godot --headless --path custodian --quit`
- Blockers or open questions: none.
