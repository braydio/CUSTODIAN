# PORTAL DUAL APPROACH TUNING

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-11
- Created: 2026-05-11
- Last updated: 2026-05-13

## Task

Extend the portal stair/platform impostor so the same portal prop can be approached from the north side as well as the south side, while keeping the 2.5D fake-elevation read, top-only teleport gate, and prop occlusion consistent.

## Outcome

Portal-ring props should feel like a raised platform from either approach direction. The south-facing authored art/collision remains the visible reference, the north-facing approach is mirrored in runtime as an invisible companion lane, and portal animation uses one visible state sprite instead of stacking FX over a static portal base.

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
- Asset requirements: reuse the current portal ring art, the portal state animation strips, and the existing authored south-side collision scene.
- Compatibility or migration concerns: the south-facing approach must continue to work exactly as before.
- Clarifying questions or assumptions: the north approach is implemented as a mirrored invisible runtime companion lane rather than a second authored portal sprite.

## Implementation Plan

1. Mirror the portal platform ramp logic for the north side in the runtime teleporter.
2. Expose a prop-definition flag so portal definitions can opt into dual approach.
3. Pass the dual-approach flag through procgen wiring for `portal_ring_01`.
4. Collapse portal visual playback to one state sprite and hide the static portal base sprite when the prop definition opts into that state sprite.
5. Change portal occlusion to sort against the platform top/horizon while leaving normal prop occlusion bounds alone.
6. Update active docs and validate the portal scripts in headless Godot.

## Acceptance

- Runtime behavior: the portal can be approached from the south without regression.
- Runtime behavior: the portal can also be approached from the north via the mirrored invisible lane.
- Runtime behavior: teleport still only fires from the top trigger once the player reaches the required elevation.
- Runtime behavior: portal idle, activation, and arrival render through one state sprite without double-drawing the static portal base.
- Runtime behavior: the operator draws in front below the portal plateau and behind/on the portal once at or above the platform top.
- Documentation: the active state pack and file index mention the north-side dual approach behavior.
- Automated/headless validation: targeted Godot script checks pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? Yes

## Completion Notes

- Implemented: portal ramp logic supports mirrored north-side access, `portal_ring_01` opts into static-base hiding, `PortalTeleporter` uses one `PortalStateSprite` for idle/activate/arrival playback, portal depth sorting now uses the platform top as the horizon instead of the broad occlusion rectangle, the authored side-block collision scene is converted from source-image pixel coordinates into bottom-center prop-local coordinates, and the tuned trigger/horizon/landing point now uses visual-frame pixel `(80,60)` while the FX sprite remains centered on its own frame.
- Implemented: platform portal arrivals land on the linked portal's trigger/horizon point instead of adding a directional bottom-left arrival offset, destination arrival animation playback waits `1.10s` before starting, portal occlusion compares the operator feet point against the platform horizon, and the authored left-side collision blocker was nudged inward/up for the latest playtest read.
- Implemented this follow-up: portal side blockers now use the point-to-point source rectangles `0,80 > 54,54` and `100,80 > 160,54` as 54x26 and 60x26 blockers in bottom-center prop-local space; portal occlusion now compares the platform horizon against the operator's collision-foot y adjusted by fake visual elevation; the platform horizon data is set to source-image y=60 for the current 193x130 portal base frame.
- Validated: `godot --headless --check-only --script res://game/world/procgen/portal_teleporter.gd`; `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --check-only --script res://content/props/ruins/scripts/ProceduralProp.gd`; `godot --headless --check-only --script res://content/props/ruins/scripts/PropDefinition.gd`; `godot --headless --path custodian --quit`.
- Validated this tuning pass: `godot --headless --check-only --script res://game/world/procgen/portal_teleporter.gd`; `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`.
- Deferred: in-editor tuning if the visual-frame `(80,60)` anchor still needs a few pixels of adjustment after playtest.

## Next Steps

- Next action: playtest both portal approaches and tune the plateau line or animation offset if the read is a few pixels off.
- Best starting files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
- Required context: current portal stair/platform impostor and south-side collision scene.
- Validation to run: in-editor walk-through from north and south approaches.
- Blockers or open questions: none
