# Enemy Grunt Runtime Wiring

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-17
- Created: 2026-05-17
- Last updated: 2026-05-17

## Task

Check whether the newly ingested `enemy_grunt` sprites are used by runtime, then wire them as a live enemy if they are only loose assets.

## Outcome

The grunt art should be reachable through a real enemy scene and wave/factory composition path, with docs updated to prevent asset/runtime drift.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/animation/ENEMY_GRUNT_RUNTIME_WIRING.md`, `design/02_features/wave_spawning/WAVE_SPAWNING_SYSTEM.md`, `design/02_features/enemy_director/implementation.md`
- Active runtime/docs files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/systems/core/systems/wave_manager.gd`, `custodian/game/systems/core/systems/enemy_factory.gd`, `custodian/scenes/game.tscn`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: legacy Python runtime

## Work Surface

- Files or folders expected to change: enemy actor scene/script, wave/factory/director wiring, AI context docs, this packet
- Files or folders expected to be read but not changed: sprite inbox/runtime outputs, validation recipes
- Out-of-scope areas: full enemy VFX layering, full directional grunt art, balance pass beyond first spawnability

## Constraints

- Determinism concerns: composition selection must remain deterministic and not depend on wall-clock state.
- Simulation/UI boundary concerns: sprite selection stays presentation-only; combat behavior remains in `Enemy`.
- Asset requirements: current grunt art is partial, so runtime must reuse/mirror available strips.
- Compatibility or migration concerns: existing drone/fast/heavy/wolf paths must continue to spawn.
- Clarifying questions or assumptions: Assumes the grunt is intended as a new active enemy type.

## Implementation Plan

1. Confirm whether `enemy_grunt` is referenced by runtime scenes or wave selection.
2. Add a grunt scene and animation library that consumes the generated runtime strips.
3. Add `grunt` to `WaveManager`, `EnemyFactory`, `EnemyDirector`, and `game.tscn`.
4. Update active docs and validate with Godot headless checks.

## Acceptance

- Runtime behavior: `grunt` has a scene and can be selected/spawned by waves.
- Documentation: design and AI context state/index mention the new wiring.
- Path/reference validation: `enemy_grunt` references resolve to generated runtime paths.
- Manual validation: recommended in-editor spawn/wave visual check remains next.
- Automated/headless validation: Godot check/import/headless boot where feasible.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: Added `EnemyGrunt`, `GruntAnimationLibrary`, `grunt` wave/factory/director wiring, `game.tscn` scene export wiring, `spawn_grunt` DevConsole command, a temporary startup debug spawn flag, melee FX overlay playback, clip-length-matched grunt attack windup, and active docs/index entries.
- Validated: Confirmed pre-change `enemy_grunt` assets were only loose runtime/inbox files; ran Godot check-only on touched scripts; ran a targeted temporary scene smoke that instantiated `EnemyGrunt` and verified `idle_s`, `run_w`, and `melee_e`; ran `godot --headless --path custodian --quit`; ran a temporary startup smoke that loaded `game.tscn`, observed `Debug spawned grunt`, and counted one startup `GRUNT`; ran a temporary melee FX smoke that forced attack playback and verified `CustomEnemyFxSprite` played `melee_fx_e`; ran a temporary gameplay-path windup smoke that verified `0.83s` windup with body `melee_e` and FX `melee_fx_e` active.
- Deferred: Full directional grunt sheets remain future art/runtime polish.

## Next Steps

- Next action: manually play-test startup and `spawn_grunt` in the DevConsole to inspect animation scale, collision, combat feel, and readability.
- Best starting files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/systems/core/systems/wave_manager.gd`
- Required context: current sprite runtime paths under `content/sprites/enemies/enemy_grunt/runtime`
- Validation to run: `godot --headless --check-only --script` checks and `godot --headless --quit`
- Blockers or open questions: full directional/FX art remains partial.
