# AUTONOMOUS COMBAT DRONES TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-15
- Created: 2026-05-15
- Last updated: 2026-05-15

## Task

Implement the first Godot runtime slice for autonomous allied combat drones from `design/ALLY_COMBAT_DRONE_MK1.md`.

## Outcome

The live Godot scene has up to two fragile allied drones that follow the Custodian, acquire nearby enemies, fire deterministic support bursts, can be destroyed, and expose simple squad mode APIs.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/ALLY_COMBAT_DRONE_MK1.md`, `design/20_features/in_progress/AUTONOMOUS_COMBAT_DRONES.md`
- Active runtime/docs files: `custodian/scenes/game.tscn`, `custodian/game/actors/allies/`, `custodian/game/systems/drone/`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: legacy Python runtime and archived docs

## Work Surface

- Files or folders expected to change: drone actor, drone manager/profile/targeting state scripts, main scene wiring, design implementation docs, AI context docs.
- Files or folders expected to be read but not changed: enemy, projectile, turret, validation, and scene hierarchy files.
- Out-of-scope areas: production drone art, drone bay/fabricator reserve spawning, power routing, global sector AI, terminal command UI.

## Constraints

- Determinism concerns: no random target selection or randomized firing spread in V1.
- Simulation/UI boundary concerns: drones are scene runtime actors; no UI authority or Command Center replacement logic.
- Asset requirements: placeholder ColorRect visuals only.
- Compatibility or migration concerns: use existing enemy groups and defense bullet projectile behavior.
- Clarifying questions or assumptions: the source design file is truncated after the FOLLOW section, so V1 implements the named modes conservatively from the available doctrine constraints.

## Implementation Plan

1. Add drone profile, squad state, targeting helper, actor scene/script, and scene-mounted manager.
2. Wire `DroneManager` into `scenes/game.tscn` under `World`, spawning two drones near the operator.
3. Update active design and AI context docs, then run Godot headless validation.

## Acceptance

- Runtime behavior: two drones spawn near the Custodian, follow/orbit, target nearby non-passive enemies, fire defense bullets, and can be destroyed.
- Documentation: design doc, implementation note, CURRENT_STATE, FILE_INDEX, and this packet reflect the runtime slice.
- Path/reference validation: referenced drone paths exist and load.
- Manual validation: deferred unless headless validation exposes a play-only issue.
- Automated/headless validation: run `cd custodian && godot --headless --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: drone profile/state/targeting scripts, `CombatDrone` actor scene/script, scene-mounted `DroneManager`, main scene wiring, active design note, implementation note, CURRENT_STATE, and FILE_INDEX updates.
- Validated: `cd custodian && godot --headless --quit` exits 0 with no drone parse/runtime script errors.
- Deferred: production art, repair/redeploy, terminal command UI, drone bay/fabricator integration, debug overlay.
- Known validation noise: existing Ash-Bell invalid UID warning, occasional procgen fallback warning, and shutdown ObjectDB/resource leak warnings still appear during headless quit.

## Next Steps

- Next action: optional playtest pass for combat feel and tuning.
- Best starting files: `custodian/game/actors/allies/combat_drone.gd`, `custodian/game/systems/drone/drone_manager.gd`
- Required context: `design/ALLY_COMBAT_DRONE_MK1.md`
- Validation to run: `cd custodian && godot --headless --quit`; optional live playtest from `custodian/scenes/game.tscn`
- Blockers or open questions: source design doc truncation limits exact mode details beyond FOLLOW.
