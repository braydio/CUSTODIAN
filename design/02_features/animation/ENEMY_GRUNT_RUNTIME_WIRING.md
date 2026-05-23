# Enemy Grunt Runtime Wiring

Status: complete
Last updated: 2026-05-17

## Summary

The `enemy_grunt` sprite intake is a new active-enemy art set, not a replacement for the existing placeholder drone/wolf visuals. Runtime should treat it as its own wave enemy type once the inbox outputs exist under:

- `res://content/sprites/enemies/enemy_grunt/runtime/body/`
- `res://content/sprites/enemies/enemy_grunt/runtime/fx/`

## Runtime Model

- Enemy type key: `grunt`
- Scene: `res://game/actors/enemies/enemy_grunt.tscn`
- Animation source: `GruntAnimationLibrary`, which builds `SpriteFrames` from canonical runtime strips.
- Wave integration: `WaveManager` and `EnemyFactory` may select `grunt` when the scene is wired.
- Debug spawn: DevConsole command `spawn_grunt [x_offset y_offset]` spawns one near the operator through `EnemyDirector` / `WaveManager`.
- Startup test: `WaveManager.debug_spawn_grunt_on_start` can place one grunt near the operator at scene start for live visual review.
- Attack timing: `EnemyGrunt.attack_windup_duration` is `0.42s`, so damage lands around the middle of the common 10-frame/12 FPS melee body and FX strips instead of waiting for the end of the clip. The west melee body source is currently 11 frames and may need a separate follow-up if west-facing attacks feel slightly early or late.

The current art set is partial but expanded:

- idle: south only
- run: east and west
- melee: east, southeast, and west
- melee FX: east and west overlay strips, played through `CustomEnemyFxSprite` during grunt attack windup

Until directional coverage is complete, runtime reuses available body strips instead of blocking the enemy from spawning.

## Acceptance

- `enemy_grunt` art is referenced by a live scene.
- Wave composition can emit `grunt`.
- `scenes/game.tscn` exports the grunt scene into `WaveManager`.
- `spawn_grunt` can spawn a grunt near the operator for immediate review.
- Grunt melee windup plays the body melee strip plus the matching FX overlay strip.
- Grunt melee windup duration lands in the middle of the authored clip before damage resolves.
- Headless Godot validation loads the new scene and scripts without missing resource errors.
