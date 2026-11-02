# PORTAL COLLISION DEBUG TUNING

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-14
- Created: 2026-05-14
- Last updated: 2026-05-14

## Task

Add a visual debug view for portal collision and correct the authored portal-ring side blockers that were too high and shifted left.

## Outcome

`portal_ring_01` has a reusable procedural-prop collision debug overlay available, but it is disabled by default after tuning. The authored portal collision scene maps the requested source-image blocker pixel points into prop-local bottom-center coordinates:

- Left blocker: source `(0,80)->(54,54)` maps to local center `(-53.5,-47)` with size `54x26`.
- Right blocker: source `(100,80)->(160,54)` maps to local center `(49.5,-47)` with size `60x26`.
- Trigger zone: the platform portal trigger is now a rectangular `46x24` top-zone shape, offset `(-3.5,0)` from the trigger anchor so it spans the full walkable gap between the side blocker inner edges instead of the old small circular trigger.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active runtime/docs files: `custodian/content/props/ruins/`, `custodian/game/world/procgen/`
- Historical reference only: `python-sim/`

## Work Surface

- Files changed:
  - `custodian/content/props/ruins/scripts/PropDefinition.gd`
  - `custodian/content/props/ruins/scripts/ProceduralProp.gd`
  - `custodian/content/props/ruins/scenes/ProceduralProp.tscn`
  - `custodian/content/props/ruins/scenes/portal_ring_collision.tscn`
  - `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
- Out-of-scope areas:
  - Manual in-editor visual confirmation.
  - Further portal platform tuning beyond the blocker and trigger-zone alignment.

## Constraints

- Determinism concerns: none; debug geometry is generated from existing collision shapes.
- Simulation/UI boundary concerns: debug overlay is visual-only and does not alter physics.
- Asset requirements: none.
- Compatibility or migration concerns: collision debug is opt-in per `PropDefinition`.
- Clarifying questions or assumptions: the pixel points are interpreted in the portal source image coordinate frame, then converted to prop-local bottom-center coordinates using the current `anchor_offset`.

## Implementation Plan

1. Add opt-in collision debug styling fields to `PropDefinition`.
2. Add `CollisionDebugRoot` to `ProceduralProp.tscn`.
3. Generate filled/outlined debug polygons from rectangle collision shapes under `CollisionRoot`.
4. Correct `portal_ring_collision.tscn` side blocker positions.
5. Tune the platform portal trigger to cover the full top gap between blockers.
6. Disable the debug overlay for `portal_ring_01` after the blocker correction.

## Acceptance

- Runtime behavior: portal side blockers use corrected local positions; the portal trigger covers the full top gap between blockers.
- Documentation: current state and task-packet index updated.
- Path/reference validation: touched files exist.
- Manual validation: pending in-editor/playtest visual check.
- Automated/headless validation: Godot script checks and whitespace check.

## Completion Notes

- Implemented: opt-in collision debug overlay, corrected portal blocker positions, rectangular platform trigger support, and `portal_ring_01` top-gap trigger sizing.
- Validated: `PropDefinition.gd` and `ProceduralProp.gd` parse checks passed.
- Deferred: manual Godot visual pass to confirm the whole top gap now triggers teleport.

## Next Steps

- Next action: open the live procgen map in Godot and walk across the full top gap between the portal blockers to confirm teleport triggers everywhere it should.
- Best starting files: `custodian/content/props/ruins/scenes/portal_ring_collision.tscn`, `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`.
- Required context: source-image blocker points `(0,80)->(54,54)` and `(100,80)->(160,54)`.
- Validation to run: `cd custodian && godot`, then walk around both portal side blockers.
- Blockers or open questions: if the sprite has changed since the pixel reference, the blocker and trigger points should be remeasured from the current portal source image.
