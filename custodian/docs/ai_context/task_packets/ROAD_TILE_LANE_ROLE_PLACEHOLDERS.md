# Road Tile Lane Role Placeholders

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-05
- Created: 2026-06-05
- Last updated: 2026-06-05

## Task

Update procgen road visual stamping and placeholder metadata for upcoming 32x32 road artwork labeled by distance from road centerline: `center`, `left_1`, `left_2`, `right_1`, and `right_2`.

## Outcome

Road generation keeps the existing deterministic walkability/collision surface but chooses road overlay sprites by lane-offset role instead of only connection bitmask, so future labeled 32x32 road tiles can replace placeholders without changing generation logic.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/03_architecture/REGION_GENERATION_SYSTEM.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/tiles/roads_paths/`, `custodian/tools/validation/procgen_placeholder_roads_smoke.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: legacy road exports under `custodian/content/tiles/roads_paths/legacy/`

## Work Surface

- Files or folders expected to change: procgen road stamping, active placeholder road manifest, roads README, focused smoke test, AI context docs.
- Files or folders expected to be read but not changed: existing placeholder PNGs and path manifest.
- Out-of-scope areas: importing final production road art, changing road collision/walkability, replacing path art.

## Constraints

- Determinism concerns: role selection must derive from centerline/offset and seeded layout only.
- Simulation/UI boundary concerns: visual overlay roles must not alter road movement/collision authority.
- Asset requirements: use current placeholder PNGs as temporary role aliases until new labeled 32x32 art is provided.
- Compatibility or migration concerns: keep bitmask road/path entries available as fallback for intersections or older placeholder art.
- Clarifying questions or assumptions: interpret "left/right 1/2" as the tile's signed perpendicular offset from the nearest road centerline.

## Implementation Plan

1. Extend the placeholder road manifest with lane-role metadata.
2. Teach `ProcGenTilemap` to load road role entries and stamp road decals per road surface tile by nearest-centerline offset.
3. Add debug/smoke validation that road overlays include lane roles.
4. Update road asset README and AI context references.

## Acceptance

- Runtime behavior: generated roads still connect and remain wall-free; road decals spawn with `center`, `left_1`, `left_2`, `right_1`, and `right_2` role names when available.
- Documentation: active road asset README and AI context mention the role contract.
- Path/reference validation: active manifest path still exists and all referenced placeholder files are loadable.
- Manual validation: not required for this metadata/runtime contract update.
- Automated/headless validation: run the focused procgen road smoke test.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No, this is a runtime asset-contract refinement under existing road/path implementation.

## Completion Notes

- Implemented: Added road lane-role entries to the active placeholder manifest, taught `ProcGenTilemap` to load and stamp road overlays by nearest-centerline lane role, added debug role counts, expanded the focused procgen road smoke, and updated road asset docs plus required asset tracking.
- Validated: `godot --headless --path custodian --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `python -m json.tool custodian/content/tiles/roads_paths/runtime/placeholders/roads/PLACEHOLDER_road_piece_manifest.game32.json`; `godot --headless --path custodian --script res://tools/validation/procgen_placeholder_roads_smoke.gd`.
- Deferred: final 32x32 production road art import and exact tile-art replacement.

## Next Steps

- Next action: Replace the placeholder lane aliases with production `road_lane_center`, `road_lane_left_1`, `road_lane_left_2`, `road_lane_right_1`, and `road_lane_right_2` artwork when supplied.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/tiles/roads_paths/runtime/placeholders/roads/PLACEHOLDER_road_piece_manifest.game32.json`
- Required context: current road/path placeholder contract and procgen road centerline generation.
- Validation to run: `godot --headless --path custodian --script res://tools/validation/procgen_placeholder_roads_smoke.gd`
- Blockers or open questions: none.
