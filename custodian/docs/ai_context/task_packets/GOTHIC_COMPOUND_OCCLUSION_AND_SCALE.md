# Gothic Compound Occlusion And Scale

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-20
- Created: 2026-05-20
- Last updated: 2026-05-20

## Task

Fix gothic compound draw ordering so the player renders above floor/road/decal tiles, renders in front of buildings until behind them, and make the connected compound larger and more complex.

## Outcome

- Floor, roads, and decals are always below the operator.
- Large structures and tall props depth-sort against the operator feet.
- Compound footprint is larger with more room for readable complexity.
- Required gate-to-keep path remains walkable.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/GOTHIC_COMPOUND_PROCGEN.md`
- Active runtime/docs files: `custodian/game/world/procgen/gothic_compound/`, `custodian/game/world/gothic_compound/gothic_compound_map.gd`
- Historical reference only: archived gothic compound packets

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/procgen/gothic_compound/`
  - `custodian/game/world/gothic_compound/gothic_compound_map.gd`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `design/02_features/procgen/GOTHIC_COMPOUND_PROCGEN.md`
- Files or folders expected to be read but not changed:
  - `custodian/game/actors/operator/`
  - `custodian/content/procgen/special_rooms/gothic_compound/`
- Out-of-scope areas:
  - replacing the sprite prototype with TileMapLayer
  - new production art

## Constraints

- Determinism concerns: layout expansion must remain seed-derived.
- Simulation/UI boundary concerns: visual draw order only; do not alter movement/combat simulation.
- Asset requirements: use existing gothic compound art.
- Compatibility or migration concerns: preserve connected-map travel.
- Clarifying questions or assumptions: use operator `global_position` as feet/depth point.

## Implementation Plan

1. Add render/depth metadata and z bands for floor/road/decal/building classes.
2. Add depth-sort tracking in the gothic sprite context and update it from the connected map.
3. Increase connected map and compound config size; add a few more planned structures/clusters without adding random density.

## Acceptance

- Runtime behavior:
  - Player appears above floor/road/decal sprites.
  - Tall structures switch in front of the player only when the player is behind their depth horizon.
  - Larger compound still validates required paths.
- Documentation:
  - Current state and design note mention occlusion/scale pass.
- Path/reference validation:
  - Script/resource paths resolve.
- Manual validation:
  - Next screenshot should show correct player/building layering.
- Automated/headless validation:
  - Godot check-only for changed scripts and full headless load.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: render/depth metadata for gothic compound assets; Sprite2D context depth-sort tracking and per-frame operator-relative occluder z switching; larger connected-map and compound bounds; service paths to utility/terminal areas; extra clustered exterior complexity; active docs updates.
- Validated: Godot check-only passed for changed gothic compound scripts; full headless `res://scenes/game.tscn` load completed successfully.
- Deferred: visual screenshot/playtest pass for exact occlusion horizon tuning; existing project shutdown resource leak warnings remain outside this task.

## Next Steps

- Next action: capture or playtest the connected compound to tune exact building horizon ratios if any sprite feels early/late.
- Best starting files: `gothic_compound_sprite_context.gd`, `gothic_compound_asset_defs.gd`, `gothic_compound_map.gd`
- Required context: operator z behavior and existing procgen prop occlusion conventions.
- Validation to run: Godot check-only and full headless load.
- Blockers or open questions: none.
