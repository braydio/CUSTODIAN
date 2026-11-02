# Enemy Grunt Runtime Wiring

Status: complete
Last updated: 2026-08-21

## Summary

The `enemy_grunt` sprite intake is a new active-enemy art set, not a replacement for the existing placeholder drone/wolf visuals. Runtime should treat it as its own wave enemy type once the inbox outputs exist under:

- `res://content/sprites/enemies/enemy_grunt/runtime/body/`
- `res://content/sprites/enemies/enemy_grunt/runtime/fx/`

## Runtime Model

- Enemy type key: `grunt`
- Scene: `res://game/actors/enemies/enemy_grunt.tscn`
- Animation source: `EnemyAnimationSet` plus `EnemyPresentationController`, which resolve semantic actions to canonical runtime strips. `GruntAnimationLibrary` remains a compatibility builder for legacy consumers and special paired-execution tables.
- Wave integration: `WaveManager` and `EnemyFactory` may select `grunt` when the scene is wired.
- Debug spawn: DevConsole command `spawn_grunt [x_offset y_offset]` spawns one near the operator through `EnemyDirector` / `WaveManager`. `spawn_grunt falcon` places one at a useful test distance and immediately starts the special windup against the Operator.
- Startup test: `WaveManager.debug_spawn_grunt_on_start` can place one grunt near the initial operator spawn for live visual review, but it waits until the operator crosses `debug_start_grunt_trigger_distance` away from that spawn zone so AFK scene loads are safe.
- Attack timing: `EnemyGrunt.attack_windup_duration` remains `0.42s`; gameplay timing is independent of strip frame count. The active ordinary `fast_01` E/W body and FX strips are nine frames.
- Special attack: `EnemyGrunt.grunt_falcon_punch_enabled` selects the typed `GruntFalconPunchConfig`, while `GruntFalconPunch` owns cadence, cooldown, captured target identity, explicit `TRACKING -> COMMITTED -> LEAP` plus hit, soft-collision, hard-collision/stand-up, and recovery phases, movement, contact, reversal interruption, and telemetry. Falcon remains a deliberate commitment after normal melee pressure: deterministic cadence, recent-parry lockout, and a clear ally lane are required. The first `0.50s` tracks the captured Operator; the engagement token is claimed before the final `0.25s` committed tell, so a displayed commitment guarantees launch unless genuinely interrupted. That transition emits one local 100ms presentation pulse and freezes direction/target point. The `0.28s` leap derives travel from the committed target projection (`distance - 28px stop-short + 10px cushion`) and caps it from the `184px` launch band, so launch eligibility and physical reach cannot drift apart. It never homes after commitment and retains the `42px` forward by `30px` lateral contact envelope. Operator contact resolves first; enemy-body and glancing/static contacts take the soft collision path, while an opposing static-world normal after at least `22px` travel enters the authored collision knockdown and stand-up sequence. Recovery has zero forward velocity and is result-specific: damaging hit `0.70s`, block `0.75s`, dodge/ordinary whiff `0.85s`, collision obstruction `0.95s`. Six-frame windup and body/FX inflight clips remain phase-matched at `8.0` and `21.428571` FPS; recovery playback is presentation-only and gameplay timers remain authoritative. Shared hit resolution remains in `Enemy.resolve_ability_hit(...)`, preserving dodge, parry, guard, damage analytics, body separation, camera feedback, and hitstop. A committed-leap parry still prefers automatic E/W Falcon Reversal.
- Falcon impact: a damaging, unblocked hit invokes the Operator's dedicated Falcon impact hook for hit recoil, `58px` knockback intent, brief hitstop, and smaller camera feedback than Marine dash. Block, parry, contact, and recovery all preserve body separation.

The current art set is partial but expanded:

- idle: south only
- run: east and west
- melee: east, southeast, and west
- stagger: current 8-frame east/west strips plus the existing south fallback, selected from tracked knockback/facing direction
- flinch: east/west 5-frame strips plus the existing south fallback
- special punch: dedicated east/west 6-frame `special_windup_01`, `special_inflight_01`, and `special_recovery_01` strips
- Falcon collision: east-authored/west-mirrored synchronized four-frame soft collision and eight-frame hard-collision knockdown body/FX; hard collision exits through the existing five-frame `reaction.stand_up`
- death: the current east-facing 5-frame fall is active and mirrors for west-facing deaths
- paired execution victim: south retains the 8-frame fallback; east/west use matched 12-frame victim strips synchronized to the Operator body/FX triplets
- Falcon Reversal victim: matched east/west eight-frame `156x156` strips share
  the Operator/FX authored canvas, frame clock, zero local offset, and execution
  root; the standard Grunt frame size remains `96x96`
- melee FX: east and west overlay strips, played through `CustomEnemyFxSprite` during grunt attack windup

Until directional coverage is complete, runtime reuses available body strips instead of blocking the enemy from spawning.

## Animation Usage Audit

| Semantic actions | Runtime status | Trigger/ownership |
| --- | --- | --- |
| relaxed/ready idle, relaxed/ready walk, relaxed/ready run | Runtime-triggered | relaxed patrol uses `unarmed_walk_01`; faster relaxed travel uses `unarmed_run_01`; ready movement uses `walk_01`/`run_01`; BSM/profile still owns movement speed |
| posture.draw / posture.alert | Runtime-triggered | first/later `NOTICE` transition; fixed 0.35s presentation window |
| fast_01/02/03 | Runtime-triggered | deterministic spawn-ordinal bag; simulation attack timing unchanged |
| flinch_01/02 | Runtime-triggered | damage/max-health severity below authoritative stagger/crit thresholds |
| flavor bark/taunts | Runtime-triggered | deterministic stationary idle/ambient/search windows; threat or movement cancels immediately |
| Falcon windup/inflight/recovery/collision/knockdown | Runtime-triggered | ability-owned phases; FX has no hit authority |
| reaction.stand_up | Runtime-triggered | hard Falcon world collision only |
| generic knockdown_01/02 | Registered, intentionally dormant | no general enemy knockdown gameplay authority exists |
| critical, execution victim, Falcon Reversal victim | Runtime-triggered | existing critical/paired-execution authorities |

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
- `grunt_falcon_punch_smoke.gd` proves the unmodified `88–184px` launch band without a test-only distance override, committed travel telemetry, modest straight-away coverage, fixed-direction counterplay, result-specific recovery, one-shot commitment cue, stop-short separation, hard parry cancellation/lockout, movement spacing, and ally-lane rejection.
