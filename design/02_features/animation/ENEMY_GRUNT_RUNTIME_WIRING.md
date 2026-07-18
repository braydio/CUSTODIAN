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
- Debug spawn: DevConsole command `spawn_grunt [x_offset y_offset]` spawns one near the operator through `EnemyDirector` / `WaveManager`. `spawn_grunt falcon` places one at a useful test distance and immediately starts the special windup against the Operator.
- Startup test: `WaveManager.debug_spawn_grunt_on_start` can place one grunt near the initial operator spawn for live visual review, but it waits until the operator crosses `debug_start_grunt_trigger_distance` away from that spawn zone so AFK scene loads are safe.
- Attack timing: `EnemyGrunt.attack_windup_duration` is `0.42s`, so damage lands around the middle of the common 10-frame/12 FPS melee body and FX strips instead of waiting for the end of the clip. The west melee body source is currently 11 frames and may need a separate follow-up if west-facing attacks feel slightly early or late.
- Special attack: `EnemyGrunt.grunt_falcon_punch_enabled` is enabled on `enemy_grunt.tscn`. Falcon Punch is a deliberate commitment after normal melee pressure, not a range-only trigger: a deterministic cadence gate, independent cooldown, recent-parry lockout, and clear ally lane are required before launch. The `0.75s` windup tracks the target with minimal drift until leap commitment; the `0.28s` leap then direction-locks, stops `28px` short of the last tracked target point, and retains a forgiving `42px` forward by `30px` lateral contact envelope. The `0.70s` recovery has no forward velocity. Contact enforces `28px` body separation. The hit still resolves through `_apply_enemy_hit_to_target(...)`, so dodge, parry, guard, and damage analytics remain centralized; a parry hard-cancels every Falcon phase and opens the existing grunt critical window. The normal impact-lock phase is hit-confirmed: parry, out-of-range/arc, collision whiff, interruption, and death cancellation resolve with explicit telemetry and never masquerade as a successful impact lock.
- Falcon impact: a damaging, unblocked hit invokes the Operator's dedicated Falcon impact hook for hit recoil, `58px` knockback intent, brief hitstop, and smaller camera feedback than Marine dash. Block, parry, contact, and recovery all preserve body separation.

The current art set is partial but expanded:

- idle: south only
- run: east and west
- melee: east, southeast, and west
- stagger: improved 11-frame east/west strips plus the existing south strip, selected from tracked knockback/facing direction
- flinch: east/west 5-frame strips plus the existing south fallback
- special punch: dedicated east/west 6-frame `special_windup_01`, `special_inflight_01`, and `special_recovery_01` strips
- death: the newer east-facing 8-frame fall is the active death clip and mirrors for west-facing deaths
- paired execution victim: south retains the 8-frame fallback; east/west use matched 12-frame victim strips synchronized to the Operator body/FX triplets
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
- Grunt falcon punch uses directional `special_windup_e/w`, `special_inflight_e/w`, hit-kind `falcon_punch`, and `special_recovery_e/w`.
- Headless Godot validation loads the new scene and scripts without missing resource errors.
- `grunt_falcon_punch_smoke.gd` proves tracking windup/leap/recovery routing, natural stationary-target contact, stop-short travel, post-contact separation, zero recovery drift, dedicated victim impact, hard parry cancellation and lockout, enemy movement spacing, and ally-lane rejection.
