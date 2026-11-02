# Interior Tile Registration

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-05
- Created: 2026-05-05
- Last updated: 2026-05-05

## Task

Add a repeatable workflow for registering runtime interior floor and wall PNGs into the canonical Godot TileSet and procgen interior source lists.

## Outcome

Dropping `floor_*_32.png`, non-corner `wall_*_32.png`, or `wall_*corner*_32.png` files into `custodian/content/tiles/interiors/runtime/` and running the registration script should make those tiles available to constructed-interior procgen.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_map.tscn`, `custodian/content/tiles/tilesets/procgen_world_tileset.tres`, `custodian/content/tiles/interiors/README.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/tools/tiles/`, `custodian/content/tiles/tilesets/`, `custodian/game/world/procgen/proc_gen_map.tscn`, active docs
- Files or folders expected to be read but not changed: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Out-of-scope areas: exterior floor atlas packing, production art creation, multi-tile wall connector authoring

## Constraints

- Determinism concerns: source ID lists must be sorted deterministically from filenames.
- Simulation/UI boundary concerns: none.
- Asset requirements: runtime files must be `32x32` PNGs named `floor_*_32.png`, non-corner `wall_*_32.png`, or `wall_*corner*_32.png`.
- Compatibility or migration concerns: preserve existing TileSet sources and add missing sources without reassigning existing IDs.
- Clarifying questions or assumptions: option 1 means one TileSet source per PNG.

## Implementation Plan

1. Add a script that scans interior runtime floor/wall PNGs and registers missing TileSet sources.
2. Refresh all `interior_floor_source_ids`, `interior_wall_source_ids`, `interior_wall_source_id`, and `interior_wall_corner_source_id` entries in `proc_gen_map.tscn`.
3. Document the naming convention and validation command.

## Acceptance

- Runtime behavior: constructed interiors can select the added floor and wall source IDs.
- Documentation: interior tile README explains the workflow.
- Path/reference validation: script reports the registered source IDs.
- Manual validation: visual tile distribution can be checked in Godot.
- Automated/headless validation: `cd custodian && godot --headless --quit`

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: convention-based interior TileSet registration for floor, wall, and wall-corner runtime PNGs; procgen now supports deterministic non-corner interior wall source arrays with the existing single-ID fallback preserved; stale interior TileSet sources are pruned when their runtime PNGs are missing; interior floors use deterministic patch/accent selection plus stable flip/transpose alternatives to reduce repetition.
- Validated: `python -m py_compile tools/tiles/register_interior_floor_tiles.py`; `python tools/tiles/register_interior_floor_tiles.py --dry-run`; `python tools/tiles/register_interior_floor_tiles.py`; `godot --headless --quit`.
- Deferred: visual in-editor inspection of new tile distribution; production doorway/top/threshold art.

## Next Steps

- Next action: inspect interior tile distribution visually in the editor when tuning art.
- Best starting files: `custodian/tools/tiles/register_interior_floor_tiles.py`
- Required context: interior runtime tile naming convention
- Validation to run: `cd custodian && python tools/tiles/register_interior_floor_tiles.py && godot --headless --quit`
- Blockers or open questions: none
