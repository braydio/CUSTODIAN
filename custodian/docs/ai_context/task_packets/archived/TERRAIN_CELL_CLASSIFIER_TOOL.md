# TERRAIN CELL CLASSIFIER TOOL

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-12
- Created: 2026-05-12
- Last updated: 2026-05-12

## Task

Create a terminal-driven helper script for reviewing terrain sheets cell by cell and recording semantic mapping data for procgen use. Support larger authored cliff chunks as multi-cell stamps.

## Outcome

The user can run a script against a terrain PNG, preview each `32x32` cell or larger stamp in the terminal when supported, see surrounding atlas context, inspect alpha-aware bounds, answer structured prompts, and produce a reusable JSON mapping file.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/CURATED_WALL_PERIMETER_PROCGEN.md`, `design/features/implementation/PROCGEN_WALL_TILE_BRIDGE.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/tiles/terrain/`
- Historical reference only: legacy Python runtime

## Work Surface

- Files or folders expected to change:
  - `custodian/tools/tiles/classify_terrain_cells.py`
  - `custodian/tools/tiles/preview_terrain_mapping.py`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/content/tiles/terrain/`
  - current procgen wall/tile docs
- Out-of-scope areas:
  - TileSet mutation
  - procgen runtime integration
  - automatic semantic inference

## Constraints

- Determinism concerns: output JSON records explicit cell coordinates and user-entered metadata.
- Simulation/UI boundary concerns: this is offline tooling only.
- Asset requirements: requires ImageMagick `magick` to crop previews; terminal image preview uses `kitten icat` or `chafa` if available.
- Compatibility or migration concerns: output schema should be stable enough to feed a later terrain/procgen integration pass.
- Clarifying questions or assumptions: the default terrain grid is `32x32`, matching the active TileSet cell workflow.

## Implementation Plan

1. Add an interactive Python script that slices tile cells through ImageMagick.
2. Support resume/back/skip/quit and compact shortcut prompts.
3. Persist mapping JSON after each classified cell.
4. Support `stamp 96x128` pixel-size and `stamp 3x4` cell-size commands from the current origin cell.
5. Show a context crop with a red target outline so small terrain pieces are recognizable in relation to neighboring cells.
6. Detect non-transparent pixel bounds for each cell/stamp and use them as defaults for visual/collision rect metadata.

## Acceptance

- Runtime behavior: not applicable.
- Documentation: packet records usage and validation.
- Path/reference validation: script path exists under `custodian/tools/tiles/`.
- Manual validation: run `--help`.
- Automated/headless validation: Python compile check passes.
- Mapping validation: preview script parses generated mapping JSON, checks stamp ownership, reports control characters, and renders a preview contact sheet.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No, offline helper only.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No, tool is narrow and discoverable in final response.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: `classify_terrain_cells.py` with terminal preview, structured prompts, resume support, stamp support, and JSON output.
- Stamp behavior: `stamp 96x128` records a `3x4` stamp on `32px` tiles; `stamp 3x4` is treated as a cell count shorthand; explicit `stamp 3cx4c` is also supported.
- Output behavior: whole stamps are stored under `stamps`, while covered cells in `cells` receive `stamp_owner` markers for resume/procgen lookup.
- Preview behavior: default scale increased to `10`; `--context-cells` controls surrounding atlas cells shown around the current target.
- Alpha behavior: previews outline reserved grid/stamp space in red and detected opaque pixels in green; mappings store `opaque_bounds_px`, `visual_rect_px`, `placement_offset_px`, and `collision_rect_px`.
- Preview validation: `preview_terrain_mapping.py` renders classified cells/stamps as a contact sheet and reports structural mapping issues.
- Validated: `python3 -m py_compile custodian/tools/tiles/classify_terrain_cells.py`; `python3 custodian/tools/tiles/classify_terrain_cells.py --help`.
- Deferred: direct TileSet/procgen integration.

## Next Steps

- Next action: run the classifier against one `custodian_recolor` terrain sheet and classify enough cells to create first terrain buckets.
- Best starting files: `custodian/content/tiles/terrain/custodian_recolor/mountain_custodian_deadworld.png`
- Required context: current procgen expects TileSet source IDs plus atlas coordinates.
- Validation to run: inspect generated JSON and wire a small subset into a terrain source prototype.
- Blockers or open questions: none
