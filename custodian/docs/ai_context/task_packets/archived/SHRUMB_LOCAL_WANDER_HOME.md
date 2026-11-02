# Shrumb Local Wander Home

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Stop passive ambient Shrumbs from drifting toward the map origin and make them wander aimlessly around the part of the world where they spawned.

## Outcome

Ambient Shrumbs record their actual placed world position as their local home anchor. Passive wander and flee destinations stay near that home anchor and prefer walkable positions when navigation is available.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/THE_TRAGEDY_OF_THE_FOREST_SHRUMB_GAMEPLAY_CORE.md`
- Active runtime/docs files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/systems/core/systems/ambient_critter_manager.gd`, `custodian/game/actors/enemies/ambient_shrumb.tscn`
- Historical reference only: legacy Python runtime docs

## Work Surface

- Files or folders expected to change: passive enemy movement, ambient critter spawn manager, current-state docs
- Files or folders expected to be read but not changed: Shrumb scene, navigation system
- Out-of-scope areas: flocking, habitat simulation, new Shrumb art, collision redesign

## Constraints

- Determinism concerns: local wander should remain bounded and avoid global drift.
- Simulation/UI boundary concerns: behavior-only runtime change.
- Asset requirements: none.
- Compatibility or migration concerns: active enemies still use existing objective/pathfinding behavior.
- Clarifying questions or assumptions: "their part of the world" means a local home radius around each generated spawn position.

## Implementation Plan

1. Add an explicit passive home setter to `Enemy`.
2. Have `AmbientCritterManager` call that setter after assigning the spawned position.
3. Keep wander/flee destinations bounded around home and prefer walkable positions.
4. Validate scripts and boot.

## Acceptance

- Runtime behavior: spawned Shrumbs no longer wander toward `(0, 0)` after placement.
- Documentation: current state notes local Shrumb wander anchoring.
- Path/reference validation: no scene path changes.
- Manual validation: code inspection verifies manager sets home after global position.
- Automated/headless validation: GDScript parse checks and headless game boot.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: added `set_passive_home_position()` on `Enemy`, call it after ambient critter placement, and route passive wander/flee target selection through bounded local samples that prefer navigation-walkable points when available.
- Validated: `enemy.gd` check-only, `ambient_critter_manager.gd` check-only, standalone Shrumb scene load, and full game scene headless boot.
- Deferred: no flocking or richer habitat behavior yet; Shrumbs still use simple independent local wander.

## Next Steps

- Next action: implement and validate.
- Best starting files: `enemy.gd`, `ambient_critter_manager.gd`
- Required context: passive Shrumbs are added before their final world position is assigned.
- Validation to run: parse checks and headless game boot.
- Blockers or open questions: none.
