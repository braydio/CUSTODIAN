# PROCGEN PROP STREAMING VISIBILITY

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-08
- Created: 2026-05-08
- Last updated: 2026-05-08

## Task

Fix generated decorative props not appearing in runtime procgen maps.

## Outcome

Outdoor ruin props and interior runtime props survive streaming reveal setup and appear under `NavigationRegion2D/PropLayer` during live maps.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`, interior tile/prop docs
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/tiles/interiors/README.md`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/game/world/procgen/proc_gen_map.tscn`
  - `custodian/content/tiles/interiors/README.md`
- Out-of-scope areas:
  - authored prop art changes
  - prop collision/gameplay interactions
  - chunk-based prop reveal/unload optimization

## Constraints

- Determinism concerns: prop candidate selection remains seeded by procgen tile hashes.
- Simulation/UI boundary concerns: decorative props remain presentation-only sprites/procedural prop nodes.
- Asset requirements: existing `prop_*.png` and `props_*.png` runtime files are used.
- Compatibility or migration concerns: non-streaming maps should still generate props after tile capture.
- Clarifying questions or assumptions: immediate fix is to preserve generated props through streaming startup; per-chunk prop reveal can be a later optimization.

## Implementation Plan

1. Stop generating props inside `_capture_generated_tile_state()` before streaming setup clears presentation layers.
2. Generate foliage/props after streaming preparation for the active map mode, keeping foliage streamed per tile and props persistent.
3. Update docs and validate with Godot headless checks.

## Acceptance

- Runtime behavior: streaming maps no longer clear generated props immediately after creating them.
- Runtime behavior: interior runtime prop textures from `content/tiles/interiors/runtime/` can be scattered into constructed interiors.
- Runtime behavior: outdoor ruin props can spawn under `PropLayer`.
- Documentation: current state and task packet record the fix.
- Automated/headless validation: procgen script check and game scene boot pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: moved outdoor ruin and interior prop generation out of tile-state capture and after streaming reveal setup so the reveal clear pass no longer deletes newly generated props.
- Validated: `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --quit --scene res://scenes/game.tscn`.
- Deferred: chunk-streamed prop reveal/unload optimization and authored prop-density tuning.

## Next Steps

- Next action: playtest interior/outdoor prop density in a live generated map.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: streaming reveal setup and interior prop loader.
- Validation to run: Godot procgen script parse and scene boot.
- Blockers or open questions: none.
