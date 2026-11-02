# ENEMY WALL REROUTE RECOVERY

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-08
- Created: 2026-05-08
- Last updated: 2026-05-08

## Task

Make enemies recover when they realize they are walking into a wall by refreshing their path and rerouting around the obstacle.

## Outcome

Enemies using pathfinding detect blocked/stalled movement and request a fresh navigation path instead of continuing to push into wall collision.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/`
- Active runtime/docs files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/systems/core/systems/navigation_system.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/actors/enemies/enemy.gd`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/game/systems/core/systems/navigation_system.gd`
- Out-of-scope areas:
  - replacing the AStar navigation system
  - changing wall collision authority
  - adding steering-agent avoidance

## Constraints

- Determinism concerns: recovery uses existing deterministic navigation graph and local movement state.
- Simulation/UI boundary concerns: gameplay movement only, no UI logic.
- Asset requirements: none.
- Compatibility or migration concerns: passive ambient wander should keep its existing walkable-destination checks.
- Clarifying questions or assumptions: first pass should improve wall-stuck behavior without a larger navigation rewrite.

## Implementation Plan

1. Add tunable stuck/reroute parameters and movement progress tracking to `Enemy`.
2. Detect collision/stalled progress after `move_and_slide()`.
3. Clear stale paths and force a fresh path request when blocked long enough.
4. Update docs and validate.

## Acceptance

- Runtime behavior: pathfinding enemies refresh their route after repeated wall collision or near-zero movement progress.
- Runtime behavior: normal movement is unaffected when enemies are progressing.
- Documentation: current state and packet record the recovery behavior.
- Automated/headless validation: enemy script parse and game scene boot pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: added tunable enemy stuck detection, movement-progress tracking, forced path refresh on repeated blocked movement, and passive ambient critter local-destination recovery when stuck.
- Validated: `godot --headless --check-only --script res://game/actors/enemies/enemy.gd`; `godot --headless --quit --scene res://scenes/game.tscn`.
- Deferred: full steering avoidance, dynamic navigation obstacle carving, and per-enemy obstacle memory.

## Next Steps

- Next action: playtest stuck thresholds against dense compounds and forest edges.
- Best starting files: `custodian/game/actors/enemies/enemy.gd`
- Required context: `NavigationSystem.get_path_to_target()`.
- Validation to run: Godot enemy script parse and scene boot.
- Blockers or open questions: none.
