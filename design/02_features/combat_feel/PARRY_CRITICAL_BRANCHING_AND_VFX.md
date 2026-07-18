# PARRY CRITICAL BRANCHING AND PAIRED EXECUTION

Status: active implementation authority  
Owner: gameplay/combat feel  
Runtime owners: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/enemies/enemy.gd`  
Related task packet: `custodian/docs/ai_context/task_packets/PARRY_CRITICAL_BRANCHING_AND_VFX.md`

## Purpose

Parry remains a branch inside guard. A successful parry opens an enemy-owned opportunity with an authored presentation, and a deliberate primary input may atomically reserve that opportunity and start a paired Operator/enemy execution. Failed parries and guard re-entry retain the existing contract: every guard entry passes through `block_enter`, and success requires release/repress before guard can return.

## Ownership

Operator owns input, contextual target selection, reservation request, alignment, the shared eight-frame duration table, Operator body/FX playback, the contact-frame damage request, camera impact/hitstop, input lock, and unified cleanup.

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
  -- lethal frame-5 contact damage --> death resolution
  -- nonlethal paired completion --> crit_recovery_s --> NONE
  -- cancellation --> crit_recovery_s when alive, death handling when dead
```

The runtime phase enum is `NONE`, `ENTER`, `HOLD`, `RECOVER`, and `EXECUTING`. `_parry_critical_window_timer` owns opportunity duration, while `_parry_critical_phase_timer` owns authored enter/recover duration. `_stagger_timer` is not critical-open state authority.

On `apply_parry_stagger()`, active attacks are cancelled, only the short requested physical knockback is applied, BREACH/countdown are spawned, and `critical_open_enter_s` starts. Enter advances to looping `critical_open_hold_s`. Expiry from enter or hold clears both indicators and starts non-looping `critical_open_recover_s`; normal AI, navigation, attacks, reactions, and direction selection remain suppressed until recover completes.

Enter, hold, and recover are standalone enemy states, not paired compositions. After the one requested parry knockback step resolves, the enemy records its own world root and preserves that root through all three phases; the Operator keeps its independent root. Normal target-ring presentation stays suppressed through recover and returns only after the recover clip completes. The paired shared-root contract begins only when reservation succeeds.

All standalone critical-open strips retain the same uncropped 96×96 enemy root convention as `idle_s`. The final hold frame and first recover frame must use nearly identical planted-foot placement and silhouette. Runtime root locking cannot repair artwork that was independently cropped or recentered, so visible hold-to-recover popping is an export defect and must be corrected in the authored sheets.

Ordinary hit reactions must not overwrite enter, hold, recover, or executing. Required asset failure emits `push_error` with the exact path and prevents the production branch from silently returning to the frozen stagger placeholder.

## Reservation And Execution API

`can_receive_parry_critical_from(attacker)` is true only for a live enemy in enter or hold with an active opportunity, a valid attacker, and no execution owner.

`reserve_parry_critical(attacker)` performs validation and consumption atomically. It switches to executing, stores the attacker, increments and returns an execution token, freezes the opportunity clock, clears BREACH/countdown, and returns anchor/facing/direction/shared-root data. The dominant horizontal approach selects `e` or `w`; vertical approaches deliberately use the authored `s` composition because no north pair exists. It never applies damage.

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

`enemy_grunt.tscn` owns `CriticalExecutionAnchor` at local `Vector2.ZERO`. The Operator body, enemy victim body, and execution FX were exported as full uncropped 96×96 cells from one authored canvas per direction, so their transparent placement already contains character separation. They share one exact world root: the enemy execution anchor. `grunt_parry_critical_operator_offset` is `Vector2.ZERO`; a non-zero offset is invalid for this execution and must fail loudly in debug builds. Both CharacterBody roots are reassigned to the shared root on start and every execution physics tick, with no post-reservation range cancellation. The paired sprite layers retain the same local presentation transform so the FX cannot drift independently. S/E/W execution assets are selected as matched triplets and are never mirrored independently.

Independent cropping or recentering of the Operator, victim, or FX exports is forbidden. If contact is wrong, correct the exported canvas placement for all layers rather than adding runtime per-layer offsets.

## Shared Timeline And Damage Frame

All paired strips contain eight source frames registered at 12 FPS for asset preview, but runtime does not use uniform SpriteFrames playback. Operator physics advances a deterministic per-frame duration table and explicitly assigns the same index to Operator body, Operator FX, and the enemy victim. The authored frame holds total `1.20s`; an execution-local `0.11s` contact freeze produces a `1.31s` presentation before control restoration.

| Source frame | Runtime index | Action | Hold |
|---:|---:|---|---:|
| 1 | 0 | close in | 90 ms |
| 2 | 1 | establish control | 130 ms |
| 3 | 2 | pull upright | 160 ms |
| 4 | 3 | maximum anticipation | 220 ms |
| 5 | 4 | contact and exactly-once damage | 50 ms + 110 ms hit-stop |
| 6 | 5 | deep follow-through | 150 ms |
| 7 | 6 | withdrawal and collapse | 150 ms |
| 8 | 7 | final separation and settle | 250 ms |

Damage fires when playback enters source frame 5 (runtime index 4), after `0.60s` of authored holds. The frame-step loop processes every crossed boundary, so a low-FPS step cannot skip contact. Hit-stop pauses both paired characters on index 4 without changing global time scale. Broad melee-overlap polling is not authoritative for execution damage.

## Control, Interruption, And Cleanup

During execution, Operator movement, attacks, guard/parry, dodge, reload, weapon switching, ordinary melee hitbox, facing updates, and root motion are locked. Existing damageability is preserved; this contract does not add invulnerability. Enemy navigation, attacks, queues, hit reactions, knockback, facing updates, and root motion are locked.

One Operator cleanup path handles normal completion, Operator death, invalid/freed enemy, scene exit, forced reset, and animation failure. It clears references and late damage eligibility, disables/hides execution FX, restores normal input/movement state, and calls enemy finish or cancellation. Enemy cleanup never resurrects a dead victim and routes a surviving victim to `crit_recovery_s` only after paired playback resolves.

Before reservation, invalid/dead/out-of-capture-range/already-owned targets are rejected. After reservation, only ownership/invalidation/cancellation rules apply. If the Operator disappears, the enemy detects the invalid owner and exits executing through cancellation safety.

## Death And Nonlethal Resolution

Lethal contact-frame damage runs the existing enemy death bookkeeping and death presentation without replaying critical-open or generic crit hit reactions. Nonlethal completion starts `crit_recovery_s`; AI unlocks only after that recovery timer completes. Cancellation before damage leaves the enemy alive and enters the same recovery. Cancellation after lethal damage leaves death handling authoritative.

## Asset Contract

Enemy grunt art uses the repository's actual `melee__` naming (not `unarmed__`):

| Runtime animation | Asset | Cells / strip | FPS | Loop |
|---|---|---:|---:|---:|
| `critical_open_enter_s` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_open_enter_01__s__5f__96.png` | 5 × 96×96 / 480×96 | 12 | no |
| `critical_open_hold_s` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_open_hold_01__s__4f__96.png` | 4 × 96×96 / 384×96 | 6 | yes |
| `critical_open_recover_s` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_recover_01__s__5f__96.png` | 5 × 96×96 / 480×96 | 10 | no |
| `critical_execution_victim_s` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__s__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `critical_execution_victim_e` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__e__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `critical_execution_victim_w` | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__w__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `operator_critical_execution_s` | `custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__critical_execution_01__s__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `operator_critical_execution_e` | `custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__critical_execution_01__e__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `operator_critical_execution_w` | `custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__critical_execution_01__w__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `operator_critical_execution_fx_s` | `custodian/content/sprites/operator/runtime/overlays/unarmed/operator__fx__unarmed__critical_execution_01__s__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `operator_critical_execution_fx_e` | `custodian/content/sprites/operator/runtime/overlays/unarmed/operator__fx__unarmed__critical_execution_01__e__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |
| `operator_critical_execution_fx_w` | `custodian/content/sprites/operator/runtime/overlays/unarmed/operator__fx__unarmed__critical_execution_01__w__8f__96.png` | 8 × 96×96 / 768×96 | 12 | no |

`crit_s`, `operator_critical_1h_right/left`, and `operator_critical_hitspark_right/left` remain compatibility aliases for unrelated callers; paired execution uses semantic names. The combined source-only master belongs at `custodian/content/sprites/operator/new_operator/source/critical/operator_enemy_grunt__paired__critical_execution_01__s__8f__128.aseprite` and is never bound to runtime `SpriteFrames`.

## Validation

```bash
cd custodian
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/debug_grunt_spawn_modes_smoke.gd
godot --headless --path . --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
```

The focused reaction smoke proves enter → hold → recover, indicator lifetime/cleanup, atomic reservation, zero-offset shared CharacterBody roots, zero-local paired layers, transform restoration, same-tick semantic paired playback, the eight-frame nonuniform duration contract, zero damage before source frame 5, one damage event on contact, the 110ms paired freeze, the final settle hold, nonlethal recovery, lethal death routing, duplicate rejection, and cleanup restoration. The debug-spawn smoke drives every preset through `WaveManager`, verifies its phase/animation/reticle contract, and rejects unsupported modes without leaving an enemy behind.

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

Goal: visually tune the authored S/E/W pairs in live play without changing ownership, direction locking, or the source-frame-5 damage contract.

Files: the directional runtime strips above, `enemy_grunt.tscn`, and focused validation.

Constraints: preserve the shared zero-offset root, full-cell exports, nonuniform duration table, and 110ms contact freeze; do not independently offset layers, mirror the pair, or move damage off source frame 5 (runtime index 4).
Acceptance: no root sliding, frame-perfect body/FX/victim synchronization, readable contact, clean lethal and nonlethal exits.
