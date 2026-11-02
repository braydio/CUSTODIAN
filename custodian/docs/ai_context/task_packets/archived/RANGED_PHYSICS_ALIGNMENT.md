# RANGED PHYSICS ALIGNMENT TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Rework the first slice of ranged weapon physics so visual muzzle placement cannot bypass nearby walls, projectiles cannot tunnel through the first wall layer, and ranged weapon rotation is constrained to the active stance band.

## Outcome

Ranged shots validate line of fire from the operator to the muzzle before spawning, projectile motion uses swept ray checks between physics positions, and the weapon socket rotation is clamped by ranged aim state until matching authored assets are supplied.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: active combat feel and runtime implementation in `design/`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/projectiles/bullet.gd`, `custodian/game/actors/projectiles/tracer.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: operator ranged fire code, projectile scripts, AI context docs
- Files or folders expected to be read but not changed: operator weapon definition resources and scene structure
- Out-of-scope areas: new authored ranged stance sprite sheets and socket art

## Constraints

- Determinism concerns: physics checks use current runtime physics state; random spread remains as existing behavior.
- Simulation/UI boundary concerns: projectile authority remains in gameplay scripts, not HUD or rendering.
- Asset requirements: no new assets required for the code fix; new assets are listed for follow-up art work.
- Compatibility or migration concerns: existing projectile scenes keep their public exported fields and hit behavior.
- Clarifying questions or assumptions: implement conservative clamped rotation and obstruction checks now, leaving full per-frame authored sockets for the asset pass.

## Implementation Plan

1. Add muzzle obstruction checks in the operator before bullet spawn.
2. Add swept projectile raycasts in bullet/tracer movement.
3. Clamp ranged weapon socket rotation by aim state.
4. Update AI context docs and validate headless.

## Acceptance

- Runtime behavior: a muzzle blocked by a wall spawns an impact and does not create a bullet past the wall.
- Runtime behavior: fast projectiles sweep their movement segment and hit the first blocker.
- Documentation: current state records the ranged physics alignment slice.
- Automated/headless validation: `cd custodian && godot --headless --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: Added operator muzzle obstruction checks before ranged shot spawn, swept ray movement for bullets/tracers, and ranged socket rotation clamps by aim-state band.
- Validated: `cd custodian && godot --headless --quit` completed without ranged script parse/load errors. Existing procgen fallback and shutdown resource leak warnings still appear.
- Deferred: Full authored ranged stance/fire sheets, per-frame sockets, and any special blocked-muzzle art remain follow-up asset work.

## Next Steps

- Next action: Supply ranged stance/fire/socket assets, then replace the temporary socket rotation clamps with authored per-frame socket metadata where needed.
- Best starting files: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/projectiles/bullet.gd`, `custodian/game/actors/projectiles/tracer.gd`
- Required context: ranged socket definitions in `OperatorWeaponDefinition`.
- Validation to run: `cd custodian && godot --headless --quit`, followed by in-editor ranged firing tests near walls.
- Blockers or open questions: none for code; authored assets remain follow-up.
