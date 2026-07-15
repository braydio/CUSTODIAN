# PARRY CRITICAL BRANCHING AND PAIRED EXECUTION

Status: active implementation authority  
Owner: gameplay/combat feel  
Runtime owners: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/enemies/enemy.gd`  
Related task packet: `custodian/docs/ai_context/task_packets/PARRY_CRITICAL_BRANCHING_AND_VFX.md`

## Purpose

Parry remains a branch inside guard. A successful parry opens an enemy-owned opportunity with an authored presentation, and a deliberate primary input may atomically reserve that opportunity and start a paired Operator/enemy execution. Failed parries and guard re-entry retain the existing contract: every guard entry passes through `block_enter`, and success requires release/repress before guard can return.

## Ownership

Operator owns input, contextual target selection, reservation request, alignment, the shared eight-frame clock, Operator body/FX playback, the frame-3 damage request, camera impact/hitstop, input lock, and unified cleanup.

Enemy owns vulnerability duration, critical-open phases, BREACH/countdown presentation, validation, atomic reservation, the stable execution anchor, victim playback, exactly-once damage acceptance, death/nonlethal resolution, and release of execution ownership.

Principle: Operator owns the attempt and shared presentation clock. Enemy owns the opportunity, consumption, victim state, and damage authority.

## Enemy State Contract

```text
NONE
  -- successful parry --> CRITICAL_OPEN_ENTER
CRITICAL_OPEN_ENTER
  -- enter clip completes --> CRITICAL_OPEN_HOLD
  -- timer expires --> CRITICAL_OPEN_RECOVER
  -- reservation succeeds --> EXECUTING
CRITICAL_OPEN_HOLD
  -- timer expires --> CRITICAL_OPEN_RECOVER
  -- reservation succeeds --> EXECUTING
CRITICAL_OPEN_RECOVER
  -- recover clip completes --> NONE / normal behavior
EXECUTING
  -- lethal frame-3 damage --> death resolution
  -- nonlethal paired completion --> crit_recovery_s --> NONE
  -- cancellation --> crit_recovery_s when alive, death handling when dead
```

The runtime phase enum is `NONE`, `ENTER`, `HOLD`, `RECOVER`, and `EXECUTING`. `_parry_critical_window_timer` owns opportunity duration, while `_parry_critical_phase_timer` owns authored enter/recover duration. `_stagger_timer` is not critical-open state authority.

On `apply_parry_stagger()`, active attacks are cancelled, only the short requested physical knockback is applied, BREACH/countdown are spawned, and `critical_open_enter_s` starts. Enter advances to looping `critical_open_hold_s`. Expiry from enter or hold clears both indicators and starts non-looping `critical_open_recover_s`; normal AI, navigation, attacks, reactions, and direction selection remain suppressed until recover completes.

Ordinary hit reactions must not overwrite enter, hold, recover, or executing. Required asset failure emits `push_error` with the exact path and prevents the production branch from silently returning to the frozen stagger placeholder.

## Reservation And Execution API

`can_receive_parry_critical_from(attacker)` is true only for a live enemy in enter or hold with an active opportunity, a valid attacker, and no execution owner.

`reserve_parry_critical(attacker)` performs validation and consumption atomically. It switches to executing, stores the attacker, increments and returns an execution token, freezes the opportunity clock, clears BREACH/countdown, and returns anchor/facing/operator-offset data. It never applies damage.

The paired lifecycle is:

```gdscript
reserve_parry_critical(attacker) -> Dictionary
begin_parry_critical_execution(attacker, execution_data) -> bool
apply_parry_critical_execution_damage(attacker, damage_amount, hit_data) -> Dictionary
finish_parry_critical_execution(attacker, result) -> void
cancel_parry_critical_execution(attacker, reason) -> void
```

The token and attacker must match at begin, damage, finish, and cancellation. Damage is accepted once. A second reservation or repeated frame callback is rejected.

## Alignment Contract

`enemy_grunt.tscn` owns `CriticalExecutionAnchor`. The enemy exposes its global anchor, the authored Operator offset, and fixed south-facing presentation. The current authored offset is `Vector2(-24, 0)` from the enemy anchor. The Operator aligns directly to that pair root on reservation and both CharacterBody roots remain fixed until cleanup; no post-reservation range check may cancel due to animation displacement. South execution assets are not mirrored.

## Shared Timeline And Damage Frame

All paired strips are eight frames at 12 FPS, for a nominal duration of `8 / 12 = 0.6666667` seconds. Operator physics owns one elapsed clock and explicitly assigns the same frame index to Operator body and Operator FX. Enemy victim playback starts on the reservation physics tick and is held to the same shared index through the enemy callback contract.

```text
frame 0  aligned start; no damage
frame 1  control/contact
frame 2  windback
frame 3  exactly-once damage, camera impact, hitstop, primary impact FX/audio hook
frame 4  follow-through
frame 5  extraction
frame 6  separation
frame 7  resolve and unlock
```

Damage uses threshold crossing at `3 / 12` seconds plus a one-shot flag, so a low-FPS step cannot skip it. Broad melee-overlap polling is not authoritative for execution damage.

## Control, Interruption, And Cleanup

During execution, Operator movement, attacks, guard/parry, dodge, reload, weapon switching, ordinary melee hitbox, facing updates, and root motion are locked. Existing damageability is preserved; this contract does not add invulnerability. Enemy navigation, attacks, queues, hit reactions, knockback, facing updates, and root motion are locked.

One Operator cleanup path handles normal completion, Operator death, invalid/freed enemy, scene exit, forced reset, and animation failure. It clears references and late damage eligibility, disables/hides execution FX, restores normal input/movement state, and calls enemy finish or cancellation. Enemy cleanup never resurrects a dead victim and routes a surviving victim to `crit_recovery_s` only after paired playback resolves.

Before reservation, invalid/dead/out-of-capture-range/already-owned targets are rejected. After reservation, only ownership/invalidation/cancellation rules apply. If the Operator disappears, the enemy detects the invalid owner and exits executing through cancellation safety.

## Death And Nonlethal Resolution

Lethal frame-3 damage runs the existing enemy death bookkeeping and death presentation without replaying critical-open or generic crit hit reactions. Nonlethal completion starts `crit_recovery_s`; AI unlocks only after that recovery timer completes. Cancellation before damage leaves the enemy alive and enters the same recovery. Cancellation after lethal damage leaves death handling authoritative.

## Asset Contract

Enemy grunt art uses the repository's actual `melee__` naming (not `unarmed__`):

| Runtime animation | Asset | Cells / strip | FPS | Loop |
|---|---|---:|---:|---:|
| `critical_open_enter_s` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_open_enter_01__s__5f__96.png` | 5 × 96×96 / 480×96 | 12 | no |
| `critical_open_hold_s` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_open_hold_01__s__4f__96.png` | 4 × 96×96 / 384×96 | 6 | yes |
| `critical_open_recover_s` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_recover_01__s__5f__96.png` | 5 × 96×96 / 480×96 | 10 | no |
| `critical_execution_victim_s` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__s__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `operator_critical_execution_s` | `custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__critical_execution_01__s__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `operator_critical_execution_fx_s` | `custodian/content/sprites/operator/runtime/fx/unarmed/operator__fx__unarmed__critical_execution_01__s__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |

`crit_s`, `operator_critical_1h_right/left`, and `operator_critical_hitspark_right/left` remain compatibility aliases for unrelated callers; paired execution uses semantic names. The combined source-only master belongs at `custodian/content/sprites/operator/new_operator/source/critical/operator_enemy_grunt__paired__critical_execution_01__s__8f__128.aseprite` and is never bound to runtime `SpriteFrames`.

## Validation

```bash
cd custodian
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
```

The focused smoke proves enter → hold → recover, indicator lifetime/cleanup, atomic reservation, same-tick semantic paired playback, 8-frame/12-FPS contracts, zero damage before frame 3, one damage event across frame 3, nonlethal recovery, lethal death routing, duplicate rejection, and cleanup restoration.

## Debug Spawn Modes

The existing DevConsole `spawn_grunt` command supports deterministic presentation presets without creating a second enemy spawner:

```text
spawn_grunt normal [x_offset y_offset]
spawn_grunt critical_enter [x_offset y_offset]
spawn_grunt critical_hold [x_offset y_offset]
spawn_grunt critical_recover [x_offset y_offset]
spawn_grunt execution_ready [x_offset y_offset]
spawn_grunt execution_lethal [x_offset y_offset]
spawn_grunt modes
```

The legacy `spawn_grunt x_offset y_offset` form remains valid. Critical/execution modes default within capture range of the Operator. `execution_ready` is a semantic alias for an authored hold opportunity; `execution_lethal` uses the same opportunity but reduces the spawned grunt to one health for death-path testing. These modes call an enemy-owned debug setup method only after normal scene instantiation and difficulty setup. They do not add simulation authority to the console, bypass reservation, or create an orphaned `EXECUTING` state.

## Next Agent Slice

Goal: visually tune the authored south-facing pair in live play without changing ownership or the frame-3 damage contract.

Files: the six runtime strips above, `enemy_grunt.tscn`, and focused validation.

Constraints: preserve `Vector2(-24, 0)` as the documented baseline unless both roots are retuned together; do not mirror the pair or move damage off frame 3.
Acceptance: no root sliding, frame-perfect body/FX/victim synchronization, readable contact, clean lethal and nonlethal exits.
