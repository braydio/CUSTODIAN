# Enemy Grunt Runtime Wiring

Status: complete
Last updated: 2026-07-13

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
- Startup test: `WaveManager.debug_spawn_grunt_on_start` can place one grunt near the initial operator spawn for live visual review, but it waits until the operator crosses `debug_start_grunt_trigger_distance` away from that spawn zone so AFK scene loads are safe.
- Attack timing: `EnemyGrunt.attack_windup_duration` is `0.42s`, so damage lands around the middle of the common 10-frame/12 FPS melee body and FX strips instead of waiting for the end of the clip. The west melee body source is currently 11 frames and may need a separate follow-up if west-facing attacks feel slightly early or late.
- Special attack: `EnemyGrunt.grunt_falcon_punch_enabled` is enabled on `enemy_grunt.tscn`. When a player target is inside the launch band, the grunt can enter a running windup, then a leaping punch, then momentum-carrying roll recovery. The hit still resolves through `_apply_enemy_hit_to_target(...)`, so dodge, parry, guard, and damage analytics remain centralized.

The current art set is partial but expanded:

- idle: south only
- run: east and west
- melee: east, southeast, and west
- stagger: east, south, and west, selected from the grunt's tracked knockback/facing direction
- special punch: east/west `special_inflight_01` strips, plus east/west 11-frame roll-recovery strips currently authored as `stagger_01`
- melee FX: east and west overlay strips, played through `CustomEnemyFxSprite` during grunt attack windup

Until directional coverage is complete, runtime reuses available body strips instead of blocking the enemy from spawning.

## Acceptance

- `enemy_grunt` art is referenced by a live scene.
- Wave composition can emit `grunt`.
- `scenes/game.tscn` exports the grunt scene into `WaveManager`.
- `spawn_grunt` can spawn a grunt near the operator for immediate review.
- Grunt melee windup plays the body melee strip plus the matching FX overlay strip.
- Grunt melee windup duration lands in the middle of the authored clip before damage resolves.
- Grunt stagger and parry critical-open hold use the authored directional `stagger_01` strips when available.
- Grunt falcon punch uses running windup, directional `special_inflight_e/w`, hit-kind `falcon_punch`, and directional `special_recovery_e/w`.
- Headless Godot validation loads the new scene and scripts without missing resource errors.
- `grunt_falcon_punch_smoke.gd` proves windup, leap-hit, and recovery phase routing.
