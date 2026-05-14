# INTERIOR TILE ART WIRING

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-05
- Created: 2026-05-05
- Last updated: 2026-05-05

## Task

Organize the new interior tile art under `custodian/content/tiles/interiors/`, add usable runtime tiles to the active TileSet, and wire the constructed interior procgen region to use those tiles where possible.

## Outcome

The indoor procgen section visually reads as a constructed military/warehouse interior using available authored tile art, while oversized source images remain preserved for future slicing or replacement.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/tiles/tilesets/procgen_world_tileset.tres`, `custodian/content/tiles/interiors/REQUIRED_ASSETS_CHECKLIST.md`
- Historical reference only: legacy Python runtime and archived docs

## Work Surface

- Files or folders expected to change:
  - `custodian/content/tiles/interiors/`
  - `custodian/content/tiles/tilesets/procgen_world_tileset.tres`
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/world/procgen/proc_gen_map.tscn`
  - active docs/context files as needed
- Files or folders expected to be read but not changed:
  - `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Out-of-scope areas:
  - Full wall connector atlas authoring
  - Door/objective/enemy interior semantics
  - Hand-authored collision changes beyond existing runtime wall collision

## Constraints

- Determinism concerns: tile selection must use existing seeded tile hash paths.
- Simulation/UI boundary concerns: visual tile family selection should not change gameplay ownership.
- Asset requirements: only runtime-ready 32px tiles should be referenced by TileSet sources.
- Compatibility or migration concerns: preserve large source/reference art and avoid orphaned root import files.
- Clarifying questions or assumptions: oversized `_32` files are source/reference art, not runtime-ready tile assets; downsampled runtime copies are acceptable temporary wiring until final 32px tiles are supplied.

## Implementation Plan

1. Split interior art into `source/` and `runtime/`.
2. Add available `32x32` interior runtime tiles to `procgen_world_tileset.tres`.
3. Add interior tile source exports and deterministic selection to `ProcGenTilemap`.
4. Update procgen scene defaults to point interior region rendering at the new source IDs.
5. Validate with stale path checks and headless Godot.

## Acceptance

- Runtime behavior: constructed interior floors and walls can use interior TileSet sources.
- Documentation: current state and file index mention the interior tile wiring.
- Path/reference validation: no active runtime reference points at moved root interior PNGs.
- Manual validation: inspect organized interior asset folder and TileSet source IDs.
- Automated/headless validation: `godot --headless --path custodian --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, add current interior art wiring note.

## Completion Notes

- Implemented: organized interior art into `source/` and `runtime/`; added five runtime interior TileSet sources; wired `ProcGenTilemap` interior floor/wall rendering to dedicated source IDs; updated scene defaults and docs.
- Validated: `godot --headless --path custodian --quit` completed without missing-resource or script-load errors; existing shutdown leak warnings remain.
- Deferred: clean transparent doorway tile, wall-top tile, threshold tile, and fuller wall connector family.

## Next Steps

- Next action: generate the remaining clean runtime interior tiles, then refine doorway/top/corner selection.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/tiles/tilesets/procgen_world_tileset.tres`
- Required context: interior region design doc and tile asset checklist.
- Validation to run: `godot --headless --path custodian --quit`
- Blockers or open questions: final doorway/wall-top/connector art is still incomplete.
