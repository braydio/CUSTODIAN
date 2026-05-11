# PORTAL DUAL APPROACH TUNING

## Packet Status

- Status: in_progress
- Owner: agent
- Agent/session: Codex 2026-05-11
- Created: 2026-05-11
- Last updated: 2026-05-11

## Task

Extend the portal stair/platform impostor so the same portal prop can be approached from the north side as well as the south side, while keeping the 2.5D fake-elevation read, top-only teleport gate, and prop occlusion consistent.

## Outcome

Portal-ring props should feel like a raised platform from either approach direction. The south-facing authored art/collision remains the visible reference, and the north-facing approach is mirrored in runtime as an invisible companion lane.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md`
- Active runtime/docs files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`, `custodian/content/props/ruins/scenes/portal_ring_collision.tscn`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: earlier south-only portal ramp behavior

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/procgen/portal_teleporter.gd`
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/content/props/ruins/scripts/PropDefinition.gd`
  - `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/content/props/ruins/scenes/portal_ring_collision.tscn`
  - portal FX runtime sheets
- Out-of-scope areas:
  - new portal art
  - true 3D stair geometry
  - full world streaming/nav rewrite

## Constraints

- Determinism concerns: ramp state and teleport eligibility remain physics-frame driven.
- Simulation/UI boundary concerns: the physics body stays flat; only the visual and fake-elevation layers move.
- Asset requirements: reuse the current portal ring art and the existing authored south-side collision scene.
- Compatibility or migration concerns: the south-facing approach must continue to work exactly as before.
- Clarifying questions or assumptions: the north approach is implemented as a mirrored invisible runtime companion lane rather than a second authored portal sprite.

## Implementation Plan

1. Mirror the portal platform ramp logic for the north side in the runtime teleporter.
2. Expose a prop-definition flag so portal definitions can opt into dual approach.
3. Pass the dual-approach flag through procgen wiring for `portal_ring_01`.
4. Update active docs and validate the portal scripts in headless Godot.

## Acceptance

- Runtime behavior: the portal can be approached from the south without regression.
- Runtime behavior: the portal can also be approached from the north via the mirrored invisible lane.
- Runtime behavior: teleport still only fires from the top trigger once the player reaches the required elevation.
- Documentation: the active state pack and file index mention the north-side dual approach behavior.
- Automated/headless validation: targeted Godot script checks pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? Yes

## Completion Notes

- Pending implementation and validation.

## Next Steps

- Next action: validate the mirrored north ramp and tune the side-block y offsets in play if the approach feels too shallow or too deep.
- Best starting files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
- Required context: current portal stair/platform impostor and south-side collision scene.
- Validation to run: targeted headless Godot script checks plus an in-editor walk-through.
- Blockers or open questions: none
