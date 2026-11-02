# Enemy Marine Dash Attack Task Packet

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-05
- Created: 2026-06-05
- Last updated: 2026-06-05

## Task

Harden `enemy_marine` dash attack into design/runtime as a heavy commitment move, then track required assets around the new direction.

## Outcome

The marine dash now has exported runtime tuning for windup, dash, impact lock, recovery, damage, knockback, hitstop, camera shake, and engage range. The shared marine actor runs a phased dash attack with direction lock, telegraph, active dash-only hit window, one hit per target, wall-stop recovery, and player impact feedback.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec doc: `design/02_features/enemy_objective/ENEMY_MARINE_DASH_ATTACK.md`
- Active runtime/docs files: `custodian/game/actors/enemies/`, `custodian/game/world/sundered_keep/`, `custodian/docs/ai_context/*`
- Historical reference only: legacy Python runtime

## Work Surface

- Changed runtime files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/actors/enemies/enemy_marine.tscn`, `custodian/game/actors/enemies/enemy_behavior_state_machine.gd`, `custodian/game/actors/operator/operator.gd`, `custodian/game/world/sundered_keep/sundered_keep_marine_ambush.gd`
- Changed validation: `custodian/tools/validation/authored_vault_grunt_loot_marine_smoke.gd`
- Changed docs/assets: design doc, AI context pack, and root `REQUIRED_ASSETS.md`
- Out-of-scope areas: generating new production sprite/audio assets, full directional movement/death suite, final in-editor feel tuning

## Constraints

- Determinism concerns: dash direction locks at windup start; no random runtime feel changes.
- Simulation/UI boundary concerns: combat behavior remains in actor scripts; no HUD or debug UI authority.
- Asset requirements: current east body/FX strips are reused; missing directional dash, telegraph/impact FX, and audio are tracked.
- Compatibility concerns: Sundered Keep ambush keeps working; existing marine animation library still supports east-only body/FX fallback.

## Implementation Plan

1. Document the dash attack frame/timing/game-feel target.
2. Add exported marine dash tuning to the shared enemy actor and marine scene.
3. Let behavior state machine query enemy-specific attack range.
4. Implement marine dash windup, dash, impact lock, recovery, one-hit tracking, wall-stop recovery, hitstop, knockback, and camera feedback.
5. Add operator impact hook for forced slide/input suppression.
6. Update Sundered Keep ambush values to match the heavy dash spec.
7. Track missing assets and run focused validation.

## Acceptance

- Runtime behavior: marine dash is a phased committed move, not ordinary delayed contact damage.
- Documentation: design doc and AI context explain dash behavior and asset targets.
- Asset tracking: both required-asset trackers list directional dash body/FX and audio needs.
- Automated/headless validation: touched scripts check-only and marine smoke pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, new marine dash design doc added.

## Completion Notes

- Implemented: marine dash design doc, exported marine dash tuning, shared phased dash runtime, behavior attack-range query, operator impact receiver, Sundered Keep ambush tuning, smoke assertions, required asset tracking.
- Follow-up: tightened the live hit frames after playtest feedback so damage only resolves during the middle dash-travel window and within a close forward/lateral contact lane. The Sundered Keep ambush controller now uses the same contact gate instead of applying damage from elapsed time alone.
- Validated: script check-only for touched runtime files and authored marine smoke.
- Deferred: production directional dash body/FX/audio assets and in-editor combat feel tuning.

## Next Steps

- Next action: create/ingest directional dash body/FX/audio assets, then tune in-editor.
- Best starting files: `design/02_features/enemy_objective/ENEMY_MARINE_DASH_ATTACK.md`, `custodian/game/enemies/procgen/grunt_animation_library.gd`, `custodian/content/sprites/enemies/enemy_marine/runtime/`
- Required context: current fallback only has east dash body/FX; west can be flipped for now.
- Validation to run: `cd custodian && godot --headless --script res://tools/validation/authored_vault_grunt_loot_marine_smoke.gd`
- Blockers or open questions: none.
