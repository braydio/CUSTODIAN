# PARRY CRITICAL BRANCHING AND VFX

Status: active implementation authority  
Owner: gameplay/combat feel  
Runtime owners: `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/enemies/enemy.gd`  
Related task packet: `custodian/docs/ai_context/task_packets/PARRY_CRITICAL_BRANCHING_AND_VFX.md`

## Purpose

Parry is a branch inside guard, not a replacement for guard. Failed parries finish the attempted parry animation, then may re-enter guard only through `block_enter`; successful parries open an enemy-owned critical opportunity and require deliberate follow-up or guard re-input.

Core branch:

```text
block_enter / block_hold
  -> parry_01
      -> finish parry_01 on active-window expiry
          -> block_enter_01 when block is still held
          -> neutral/combat idle when block was released

      -> parry_success_01 on caught attack
          -> enemy-owned vulnerable / critical-open window
          -> attack may start critical_attack_01 only when a valid vulnerable enemy exists
          -> guard requires release/repress after success
```

Hard rule: every path into guard must go through `block_enter`. No runtime path may snap directly into `block_hold`.

## Authority Split

Operator owns:

- block input interpretation
- `block_enter`, `block_hold`, `block_exit` presentation
- `parry_01` windup/active/recovery timing
- `parry_success_01` after success
- parry success contact spark and one-shot success burst
- attack input buffering
- critical-target search before starting a contextual critical attack
- critical attack animation and hit timing

Enemy owns:

- whether it is vulnerable / critical-open
- vulnerability duration
- BREACH marker and countdown ring
- vulnerability expiry
- critical validation
- critical consumption
- critical damage reaction and `crit_s` / `crit_fx_s` presentation

Principle: Operator owns the attempt. Enemy owns the opportunity. Operator owns the critical animation. Enemy owns critical validation and consumption.

## Input And Branch Contract

Holding offhand secondary in a valid defense context starts `block_enter_01`. `block_active` stays false or weak until the guard-ready threshold, then guard enters `block_hold` and `block_active = true`.

Primary while guard is active/available starts `parry_01`:

```text
windup: no parry active
active: parry can catch incoming enemy hit
recovery: committed miss
success: caught hit
```

When the active parry window expires without success:

```text
parry_01 finishes -> no miss VFX -> post-parry guard/neutral branch
```

If an enemy hit connects while a parry attempt is committed but does not validate as a successful parry, the Operator cancels the parry attempt, plays the existing blocking hit-react animation, and still receives the enemy damage. This is presentation feedback for a failed parry timing/validation branch, not a successful block or parry.

After the failed parry finishes:

- if offhand secondary is still held, play `block_enter_01`, keep `block_active = false`, then enter `block_hold` through the normal guard-ready path
- if offhand secondary was released, return to neutral/combat idle with `block_active = false`

When parry succeeds:

```text
parry_01
  -> parry_success_01
  -> parry contact spark / success burst
  -> enemy.apply_parry_stagger(...)
  -> supported enemy opens critical window
```

Holding block must not automatically resume guard after success. Guard requires release/repress, and repressing still plays `block_enter_01` before `block_hold`.

## Critical Attack Contract

On success the Operator calls:

```gdscript
attacker.apply_parry_stagger(away_from_operator, parry_enemy_stagger_sec, parry_enemy_knockback)
```

Supported enemies open their own vulnerability window. For `enemy_grunt`, this means `_parry_critical_window_timer`, BREACH marker, countdown ring, and stagger/open pose. The Operator does not own that timer.

Attack input after parry success must first query for a valid critical target:

```gdscript
func _try_start_contextual_attack() -> void:
    var critical_target := _find_valid_parry_critical_target()
    if critical_target != null:
        _start_critical_attack(critical_target)
        return
    _try_melee_attack()
```

`critical_attack_01` only starts when a vulnerable enemy validates through:

```gdscript
func can_receive_parry_critical_from(attacker: Node2D) -> bool
```

The enemy consumes through:

```gdscript
func receive_parry_critical(attacker: Node2D, damage: float, hit_data: Dictionary = {}) -> Dictionary
```

Normal damage, counter-boosted damage, and explicit parry-critical damage are separate concepts. Arbitrary `take_damage()` must not be the sole source of critical consumption.

## VFX Contract

Successful parry spawns:

- world-space contact spark at the impact point
- independent Operator success burst
- enemy BREACH marker
- enemy countdown ring

Required success assets:

```text
custodian/content/sprites/effects/combat/critical/combat_fx__parry_success_hit_spark_01__6f__128.png
custodian/content/sprites/effects/combat/critical/combat_fx__breach_alert__8f__96-48.png
custodian/content/sprites/effects/combat/critical/combat_fx__breach_timer_reticle__12f__128.png
```

Required success scenes:

```text
custodian/game/vfx/combat/parry_contact_spark_vfx.tscn
custodian/game/vfx/combat/parry_success_burst_vfx.tscn
custodian/game/vfx/combat/critical_breach_marker_vfx.tscn
custodian/game/vfx/combat/critical_window_ring_vfx.tscn
```

Failed parry does not spawn a miss VFX and does not use a `parry_miss_01` animation. It simply completes the parry attempt read and then returns to neutral or re-enters guard through `block_enter`.

## Animation Naming

Preferred parry names:

```text
unarmed_parry              = attempt / shield swing / whiff-capable action
unarmed_parry_success_01   = success branch
unarmed_block_exit         = guard exit only
```

Critical attack target:

```text
operator_critical_1h_right
operator_critical_1h_left
```

Current runtime maps the previously misnamed 8-frame 96px `parry_miss` body sheets as the fast critical attack body animation:

```text
custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__parry_miss_01__e__8f__96.png -> operator_critical_1h_right
custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__parry_miss_01__w__8f__96.png -> operator_critical_1h_left
```

These files should be renamed in a future asset cleanup, but runtime code must present them as `operator_critical_1h_*`, not as parry miss.

## Validation

Required focused validation:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
```

Acceptance:

- holding block starts `block_enter` before `block_hold`
- parry attempt plays `parry_01`
- missed parry finishes `parry_01` and spawns no miss VFX
- missed parry with block still held re-enters `block_enter`, not `block_hold`
- missed parry with block released returns neutral
- enemy hit during a committed but unsuccessful parry attempt plays block hit-react while still applying damage
- successful parry plays `parry_success_01`
- successful parry opens enemy-owned vulnerability where supported
- successful parry requires block release/repress before guard can re-enter
- attack input only starts the critical branch when a valid vulnerable enemy exists
- enemy validates and consumes vulnerability on critical hit
- BREACH/ring clear on critical consumption or expiry
- success/miss one-shot VFX are independent from `ModularUpperFxSprite`
