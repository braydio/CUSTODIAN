# PORTAL TRIGGER FRAME COVERAGE

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-14
- Created: 2026-05-14
- Last updated: 2026-05-14

## Task

Expand the portal-ring teleport trigger so the player cannot skip around the left side of the frame without activating teleport.

## Outcome

`portal_ring_01` should keep its top-only portal behavior, but the active trigger/elevation span should cover the full visible `161px` portal frame instead of only the narrow `46px` gap between authored side blockers. Platform portals should also land the operator just below the destination trigger so widened triggers do not create immediate re-teleport loops.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md`
- Active runtime/docs files: `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`, `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
  - `custodian/game/world/procgen/portal_teleporter.gd`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/content/props/ruins/scenes/portal_ring_collision.tscn`
- Out-of-scope areas:
  - Reworking portal art, side blocker collision, FX timing, or procgen portal placement.

## Constraints

- Determinism concerns: none; this is static resource tuning consumed by deterministic procgen portal attachment.
- Simulation/UI boundary concerns: teleport remains owned by `PortalTeleporter`; no visual-only system gains teleport authority.
- Asset requirements: none.
- Compatibility or migration concerns: existing portal definitions should continue using the same exported fields.
- Clarifying questions or assumptions: "full portal frame length" means the current visible portal FX/runtime frame width of `161px`, centered on the portal anchor.

## Implementation Plan

1. Expand `portal_platform_trigger_shape_size.x` from `46` to `161` and center the shape offset.
2. Expand `portal_platform_top_width` to `161` so the required top-elevation sample matches the trigger width.
3. Keep platform portal arrivals on the authored local `arrival_offset`, just below the trigger, instead of rotating the offset toward the source portal.
4. Update current-state/task-packet docs and run targeted Godot checks.

## Acceptance

- Runtime behavior: standing across the visible portal frame top, including the left side, remains inside the teleport trigger/elevation span; teleport arrival places the operator below the destination trigger to avoid immediate loops.
- Documentation: current state and task-packet index reflect the new trigger coverage.
- Path/reference validation: touched portal/resource/docs paths exist.
- Manual validation: in-editor walk test remains recommended.
- Automated/headless validation: targeted Godot script checks and `git diff --check`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No exact trigger dimensions are listed in the active design doc.

## Completion Notes

- Implemented: expanded `portal_ring_01` from the old `46x24` gap-only trigger to a centered `161x24` full-frame trigger, expanded the portal ramp top width to `161` so the elevation gate matches the trigger span, and changed platform portal arrivals to use their authored below-trigger local offset instead of source-direction placement.
- Validated: `godot --headless --path . --check-only --script res://game/world/procgen/portal_teleporter.gd`; `godot --headless --path . --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --path . --quit` exited 0 with existing shutdown leak warnings; `git diff --check`.
- Deferred: manual in-editor walk test across the left side and full portal frame.

## Next Steps

- Next action: playtest a procgen portal in Godot and walk across the left side of the frame to confirm teleport activation feels correct.
- Best starting files: `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`, `custodian/game/world/procgen/portal_teleporter.gd`
- Required context: current trigger anchor is prop-local `(0,-54)` against a `161px` portal frame.
- Validation to run: `cd custodian && godot --headless --path . --check-only --script res://game/world/procgen/portal_teleporter.gd`; then manual portal walk test in editor.
- Blockers or open questions: none.
