# PORTAL STAIR RAMP 2.5D

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-10
- Created: 2026-05-10
- Last updated: 2026-05-10

## Task

Turn the portal prop into a 2.5D physics impostor with a passable stair lane, elevation ramp, top-only teleport trigger, and player visual lift/speed modulation while keeping the runtime in Godot 2D.

## Outcome

The portal should feel like the player walks up onto a platform: lower rocks block the sides, the center lane is walkable, elevation rises across the ramp, shadow/visuals compress as the player climbs, and teleport only fires from the top trigger zone once the player reaches the required elevation.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md`
- Active runtime/docs files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/actors/operator/operator.gd`, `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: older flat portal trigger behavior

## Work Surface

- Files or folders expected to change: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/actors/operator/operator.gd`, active AI context docs, this packet
- Files or folders expected to be read but not changed: unrelated prop art, terminal/UI code, fabrication systems
- Out-of-scope areas: true 3D stairs, full scene migration, new portal art

## Constraints

- Determinism concerns: teleport timing and ramp state must remain physics-frame driven.
- Simulation/UI boundary concerns: only the player visual layer and runtime world prop should move, not the physics body upward in world space.
- Asset requirements: reuse the current portal ring art.
- Compatibility or migration concerns: existing portal placement and paired teleport behavior should continue to work.
- Clarifying questions or assumptions: keep the ramp as an impostor using collision zones, fake elevation, and top-only trigger logic.

## Implementation Plan

1. Add portal ramp and top-trigger zones to the runtime teleporter node.
2. Add player fake-elevation, surface multiplier, and shadow/visual response hooks.
3. Tune portal prop offsets and collision to feel like a raised platform approach.
4. Update active docs and validate the changed scripts in headless Godot.

## Acceptance

- Runtime behavior: the player walks up a center lane, slows slightly, and visually rises on the way to the portal.
- Runtime behavior: touching the front stones alone does not teleport the player.
- Runtime behavior: the teleport only triggers from the top mouth once the player reaches the required elevation.
- Documentation: current state, file index, and prop-system notes mention the new portal ramp impostor.
- Automated/headless validation: targeted Godot script checks pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? Yes

## Completion Notes

- Implemented: portal ring now uses a raised platform impostor with a passable center lane, side blockers, fake elevation, speed modulation, and a top-only teleport gate. The portal definition now points at a dedicated authored side-block collision scene.
- Validated: `portal_teleporter.gd`, `proc_gen_tilemap.gd`, and `operator.gd` compile in headless Godot.
- Deferred: exact art-authored collision polygons and a visual debug overlay for tuning the platform footprint.

## Next Steps

- Next action: tune the portal ramp widths/offsets in play if the platform read still feels off.
- Best starting files: `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
- Required context: current portal prop definition and operator sprite/shadow nodes.
- Validation to run: Godot headless script checks already passed; follow-up playtest tuning is visual/feel driven.
- Blockers or open questions: none
