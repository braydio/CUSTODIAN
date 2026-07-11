# PARRY / CRITICAL BRANCHING AND VFX IMPLEMENTATION PACKET

Target project: `custodian/`  
Recommended project file path:

```text
custodian/docs/ai_context/task_packets/PARRY_CRITICAL_BRANCHING_AND_VFX.md
```

Status: implementation packet / combat-feel refinement  
Runtime owner: `custodian/game/actors/operator/operator.gd` and `custodian/game/actors/enemies/enemy.gd`  
Design owner: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`

---

## 1. Purpose

Implement and document the finalized parry branch behavior:

```text
block_enter / block_hold
  -> parry_01
      -> parry_recovery_01 + parry_miss_01 VFX if no attack is caught
          -> block_enter_01 if block is still held
          -> neutral/combat idle if block was released

      -> parry_success_01 if an attack is caught
          -> enemy-owned vulnerable / critical-open window
          -> player attack may resolve into critical_attack_01 if a valid vulnerable enemy exists
          -> block requires release/repress after success
```

Core rule:

```text
Every path into guard must go through block_enter.
No path snaps directly into block_hold.
```

---

## 2. Authority split

### Operator owns

```text
- block input interpretation
- block_enter / block_hold / block_exit presentation
- parry_01 attempt timing
- parry_recovery_01 after whiff
- parry_success_01 after success
- parry_miss_01 VFX spawn on whiff
- parry success contact spark spawn
- attack input buffering
- resolving whether an attack input can start critical_attack_01
- critical_attack_01 animation and hit-frame timing
```

### Enemy owns

```text
- whether it is vulnerable / critical-open
- vulnerability duration
- BREACH marker
- countdown ring
- vulnerability expiry
- critical validation
- critical consumption
- critical damage reaction
- crit_s / crit_fx_s presentation
```

Critical principle:

```text
Operator owns the attempt.
Enemy owns the opportunity.
Operator owns the critical animation.
Enemy owns critical validation and consumption.
```

The Operator may query for a valid critical target, but the enemy remains the source of truth.

---

## 3. Input and animation branch contract

### 3.1 Guard start

When the player holds offhand secondary in a valid parry/guard context:

```text
input: hold offhand secondary
state: block_enter_01
block_active: false or weak until guard-ready threshold
then: block_hold
block_active: true
```

Do not allow any state to enter `block_hold` directly.

---

### 3.2 Parry attempt

When the player presses primary while guard is active/available:

```text
input: primary while holding offhand secondary
state: parry_01
phase: windup -> active -> recovery/success
```

During `parry_01`:

```text
windup: no parry active
active: parry can catch incoming enemy hit
recovery: player committed and missed
success: player caught incoming hit
```

---

### 3.3 Failed parry / whiff

If the active parry window expires without catching an incoming hit:

```text
parry_01
  -> parry_recovery_01
  -> spawn parry_miss_01 VFX
```

After `parry_recovery_01` finishes:

```text
if offhand secondary is still held:
    play block_enter_01
    block_active = false until normal guard-ready point
    then enter block_hold

else:
    return to neutral / combat idle
```

Important:

```text
A missed parry may automatically re-enter guard if block is still held,
but it must re-enter through block_enter_01. It must not snap into block_hold.
```

This gives the failed parry a readable recovery cost without forcing unnecessary re-input after every miss.

---

### 3.4 Successful parry

If an enemy hit is caught during the active parry window:

```text
parry_01
  -> parry_success_01
  -> spawn parry success contact spark
  -> enemy.apply_parry_stagger(...)
  -> enemy opens vulnerable / critical-open window
```

After a successful parry:

```text
holding block must not automatically resume guard
block requires release/repress before any new guard entry
repressing block must still play block_enter_01 before block_hold
```

Reason:

```text
A successful parry is a reward branch and should create a deliberate choice:
critical attack, reposition, normal attack, or release/repress to guard.
It should not become an automatic turtle reset.
```

---

## 4. Enemy vulnerability and critical attack contract

### 4.1 On successful parry

The Operator should call the attacker:

```gdscript
attacker.apply_parry_stagger(away_from_operator, parry_enemy_stagger_sec, parry_enemy_knockback)
```

The enemy should then decide whether it supports parry-critical vulnerability.

For `enemy_grunt`, the enemy opens:

```text
_parry_critical_window_timer
BREACH marker
countdown ring
stagger/open pose
```

The Operator should not own this timer.

---

### 4.2 Attack input after parry success

When the player presses attack after parry success, the Operator should first attempt to resolve a valid critical target.

Recommended logic:

```gdscript
func _try_start_contextual_attack() -> void:
    var critical_target := _find_valid_parry_critical_target()
    if critical_target != null:
        _start_critical_attack(critical_target)
        return

    _try_melee_attack()
```

Critical animation should only play when a valid vulnerable enemy has been confirmed.

Do not always play the critical animation and let the enemy merely decide whether the damage becomes critical. That would make readability bad: the player would see an execution-style move even when nothing was actually executable.

Preferred rule:

```text
critical_attack_01 only plays when the Operator has found a valid vulnerable target
normal attack plays otherwise
```

---

### 4.3 Enemy validation

Add or standardize enemy query methods:

```gdscript
func can_receive_parry_critical_from(attacker: Node2D) -> bool:
    return _is_grunt_parry_critical_window_active()
```

And a consumption method:

```gdscript
func receive_parry_critical(attacker: Node2D, damage: float, hit_data: Dictionary = {}) -> Dictionary:
    if not can_receive_parry_critical_from(attacker):
        return {
            "critical": false,
            "consumed": false,
            "damage_applied": 0.0,
        }

    _parry_critical_window_timer = 0.0
    _clear_grunt_critical_open_vfx(false)
    take_damage(damage)
    _start_crit_reaction()

    return {
        "critical": true,
        "consumed": true,
        "damage_applied": damage,
    }
```

Implementation may adapt this to existing `take_damage()` behavior, but the final model should separate:

```text
normal damage
counter-boosted damage
explicit critical/riposte damage
```

---

## 5. VFX contract

### 5.1 Successful parry VFX

On success:

```text
- world-space contact spark at impact point
- optional Operator success sweep/flash
- enemy BREACH marker
- enemy countdown ring
```

Existing required VFX assets:

```text
custodian/content/sprites/effects/combat/critical/combat_fx__parry_success_hit_spark_01__6f__128.png
custodian/content/sprites/effects/combat/critical/combat_fx__breach_alert__8f__96-48.png
custodian/content/sprites/effects/combat/critical/combat_fx__breach_timer_reticle__12f__128.png
```

Existing SpriteFrames resources:

```text
custodian/content/spriteframes/effects/combat/parry_contact_spark_01.tres
custodian/content/spriteframes/effects/combat/critical_breach_marker_01.tres
custodian/content/spriteframes/effects/combat/critical_window_ring_01.tres
```

Existing scenes:

```text
custodian/game/vfx/combat/parry_contact_spark_vfx.tscn
custodian/game/vfx/combat/critical_breach_marker_vfx.tscn
custodian/game/vfx/combat/critical_window_ring_vfx.tscn
```

Recommended fix:

```text
Keep parry success burst VFX independent from ModularUpperFxSprite.
Do not rely on modular upper FX for the one-shot success burst,
because recovery/success transitions can hide ModularUpperFxSprite.
```

---

### 5.2 Failed parry VFX

Asset name:

```text
parry_miss_01
```

Recommended runtime texture:

```text
custodian/content/sprites/effects/combat/parry/combat_fx__parry_miss_01__8f__128.png
```

Recommended SpriteFrames:

```text
custodian/content/spriteframes/effects/combat/parry_miss_01.tres
```

Recommended scene/script:

```text
custodian/game/vfx/combat/parry_miss_vfx.tscn
custodian/game/vfx/combat/parry_miss_vfx.gd
```

SpriteFrames animation name:

```text
miss
```

Playback:

```text
8 frames
128x128
18–22 fps
non-looping
world-space one-shot
auto-free on animation_finished
```

VFX meaning:

```text
The player attempted a parry, the active window expired, and no hit was caught.
The VFX should look like an empty-air sweep, not a successful impact.
```

Do not spawn it on:

```text
- successful parry
- normal guard block
- critical hit
- enemy stagger
- BREACH window
```

Spawn only when:

```text
_parry_phase == "active" expires into recovery without success
```

---

## 6. Parry miss VFX art prompt

Use this prompt when regenerating or refining the VFX:

```text
Create a transparent-background pixel-art VFX spritesheet for CUSTODIAN.

Use the attached failed-parry / parry-whiff operator animation as the timing and style reference. The character is a dark hooded operator with gold accents, performing a failed parry or missed parry recovery. Generate only the VFX layer, not the body. The VFX should communicate “parry attempt missed / no contact” — a fast defensive sweep through empty air, with no hit spark, no enemy impact, and no successful BREACH energy.

Asset: parry_miss_01
Frame count: 8
Frame size: 128x128
Sheet layout: 4 columns by 2 rows
Background: fully transparent
Anchor: operator hand / parry contact zone, centered around the failed guard sweep
Playback: 18–22 fps, non-looping

Visual style:
- CUSTODIAN gothic sci-fi pixel art
- tight, readable, not noisy
- dark smoke-gray motion wisps
- dull amber/gold afterimage trails
- a few broken rust-orange particles
- no bright white impact core
- no starburst
- no damage-number look
- no circular critical indicator
- no BREACH marker

Frame-by-frame:
Frame 1: tiny guard-read shimmer near the forward hand, barely visible.
Frame 2: thin crescent arc starts sweeping outward, dull gold and smoke-gray.
Frame 3: wider empty-air slash arc, clearly no contact.
Frame 4: peak whiff frame: longest broken crescent with slight offset and a few trailing flecks.
Frame 5: arc begins collapsing into thinner fragments, smoke trailing behind.
Frame 6: weak afterimage and dust curl, energy fading.
Frame 7: only a few dim gold motes and gray wisps remain.
Frame 8: nearly gone, faint residual afterimage/dust only.

Important:
This is a VFX-only overlay for a failed parry recovery. No body sprites, no hit spark, no impact target, and no background. Maintain consistent placement so the sheet can be used as an overlay on the failed parry animation.
```

---

## 7. Animation asset naming

### Modular parry body/FX stack

If authored as modular layers:

```text
operator__modular_lower_body__unarmed__parry_01__e__6f__96.png
operator__modular_upper_body__unarmed__parry_01__e__6f__96.png
operator__modular_upper_fx__unarmed__parry_01__e__6f__96.png

operator__modular_lower_body__unarmed__parry_recovery_01__e__6f__96.png
operator__modular_upper_body__unarmed__parry_recovery_01__e__6f__96.png
operator__modular_upper_fx__unarmed__parry_recovery_01__e__6f__96.png

operator__modular_lower_body__unarmed__parry_success_01__e__6f__96.png
operator__modular_upper_body__unarmed__parry_success_01__e__6f__96.png
operator__modular_upper_fx__unarmed__parry_success_01__e__6f__96.png
```

### Baked full-body variants

If authored as baked full-body sheets instead:

```text
operator__body__unarmed__parry_01__e__6f__96.png
operator__body__unarmed__parry_recovery_01__e__6f__96.png
operator__body__unarmed__parry_success_01__e__6f__96.png
```

### Critical attack

For the generated 1H critical attack sheet with rectangular frames:

```text
operator__body__melee__critical_1h_01__e__8f__156x96.png
```

Runtime output:

```text
custodian/content/sprites/operator/runtime/actions/critical/body/operator__body__melee__critical_1h_01__e__8f__156x96.png
```

Animation name:

```text
operator_critical_1h_right
```

Behavior:

```text
baked full-body
non-looping
8 frames
156x96
14–16 fps
visual authority over modular upper/lower layers while playing
```

---

## 8. Suggested code changes

### 8.1 Add preload

In `operator.gd`:

```gdscript
const PARRY_MISS_VFX_SCENE := preload("res://game/vfx/combat/parry_miss_vfx.tscn")
```

---

### 8.2 Spawn parry miss only on active-window expiry

In `_update_parry_guard_timers(delta)`, active branch should become conceptually:

```gdscript
&"active":
    if _parry_timer <= 0.0:
        _parry_active = false
        _parry_phase = &"recovery"
        _parry_timer = maxf(0.0, parry_recovery_sec)
        _block_phase = &"recovery"
        _block_active = false
        _play_parry_animation(&"unarmed_parry_recovery")
        _spawn_parry_miss_fx()
```

If the current animation convention still uses `unarmed_block_exit` as fallback, keep the fallback, but prefer a named `unarmed_parry_recovery` / `parry_recovery_01` animation where available.

---

### 8.3 Spawn helper

```gdscript
func _spawn_parry_miss_fx() -> void:
    var direction := _get_attack_aim_direction()
    if direction.length_squared() <= 0.001:
        direction = visual_idle_direction
    if direction.length_squared() <= 0.001:
        direction = Vector2.DOWN

    var fx := PARRY_MISS_VFX_SCENE.instantiate() as Node2D
    if fx == null:
        push_error("[CombatVfx] Required parry miss scene could not instantiate.")
        return

    var parent := get_tree().current_scene
    if parent == null:
        parent = get_parent()

    parent.add_child(fx)
    fx.global_position = global_position + direction.normalized() * 24.0
    fx.rotation = direction.angle()
```

---

### 8.4 Guard re-entry after failed parry

After parry recovery:

```gdscript
if completed_phase == &"recovery":
    if _is_attack_secondary_pressed() and _get_offhand_secondary_mode() == &"parry_guard":
        _guard_requested_from_secondary = true
        _block_phase = &"enter"
        _block_active = false
        _guard_held_timer = 0.0
        _play_block_animation(&"melee_2h_block_enter")
        _request_block_state()
    else:
        _block_phase = &""
        _block_active = false
```

Important:

```text
Do not set _block_phase = "hold" directly here.
Do not set _block_active = true directly here.
```

---

### 8.5 Guard re-input after successful parry

After success:

```gdscript
func _enter_post_parry_neutral_lock() -> void:
    _guard_requested_from_secondary = false
    _guard_repress_required_after_parry_success = _is_attack_secondary_pressed()
    _block_phase = &""
    _block_active = false
    _play_parry_animation(&"unarmed_parry_success_01")
```

Guard input update should require release/repress before starting guard again if `_guard_repress_required_after_parry_success` is true.

Conceptual rule:

```gdscript
if _guard_repress_required_after_parry_success:
    if not _is_attack_secondary_pressed():
        _guard_repress_required_after_parry_success = false
    else:
        return
```

---

## 9. Validation requirements

Add or update validation to cover these cases:

### Failed parry held block

```text
start block
start parry
do not deliver enemy hit
let active window expire
assert parry_miss_01 spawned
assert parry_recovery_01 or fallback recovery played
keep block held
after recovery, assert block_enter starts
assert block_active is false during block_enter
after guard-ready threshold / enter finish, assert block_hold and block_active true
```

### Failed parry released block

```text
start block
start parry
release block before recovery ends
let active window expire
assert parry_miss_01 spawned
after recovery, assert neutral/combat idle
assert block_active false
```

### Successful parry held block

```text
start block
start parry
deliver enemy hit during active parry
assert parry_success_01 played
assert parry_miss_01 did not spawn
assert contact spark spawned
assert enemy opened critical window
continue holding block
after success finishes, assert guard does not auto-enter
assert block requires release/repress
```

### Successful parry critical input

```text
start block
start parry
deliver enemy hit during active parry
enemy opens critical window
press attack while in range/angle
assert Operator starts critical_attack_01
assert enemy receives/consumes parry critical
assert BREACH/ring cleared
```

### Attack without vulnerable target

```text
press attack after parry success but no valid vulnerable target
assert critical_attack_01 does not play
assert normal attack or no-op behavior follows current combat rules
```

---

## 10. Documentation updates

Update:

```text
design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md
custodian/docs/ai_context/CURRENT_STATE.md
```

Document:

```text
- parry_01 branches into parry_recovery_01 or parry_success_01
- failed parry can re-enter guard only through block_enter
- successful parry requires guard re-input
- enemy owns critical-open vulnerability
- Operator only starts critical animation after finding a valid vulnerable enemy
- parry_miss_01 is world-space one-shot VFX spawned only on active parry expiry
```

Do not update stale `design/20_features/in_progress/...` paths.

---

## 11. Acceptance criteria

```text
- Holding block starts block_enter before block_hold.
- Parry attempt plays parry_01.
- Missed parry plays parry_recovery_01 and spawns parry_miss_01.
- Missed parry with block still held re-enters block_enter, not block_hold.
- Missed parry with block released returns neutral.
- Successful parry plays parry_success_01 and never spawns parry_miss_01.
- Successful parry opens enemy-owned vulnerability where supported.
- Successful parry requires block release/repress before guard can re-enter.
- Re-entering guard after success still plays block_enter before block_hold.
- Attack input only starts critical_attack_01 when a valid vulnerable enemy target exists.
- Enemy validates and consumes vulnerability on critical hit.
- BREACH/ring are cleared on critical consumption or expiry.
- Operator success/miss one-shot VFX are not hidden by ModularUpperFxSprite transitions.
```
