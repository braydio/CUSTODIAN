You are working in `~/Projects/CUSTODIAN`.

> Historical surgical instruction: this document remains authoritative for the iframe damage gate only. The later, approved tap/hold movement extension is owned by `design/02_features/operator/DODGE_CHARGED_LONG_ROLL.md`; it preserves this document's active-only iframe ceiling and vulnerable recovery rule.

Operate in **low-code-ability mode**:

- Make the smallest possible surgical edits.
- Do not refactor combat, movement, animation, or enemy AI architecture.
- Do not rename existing functions.
- Do not move code between files.
- Do not introduce new scenes, resources, autoloads, or signals.
- Preserve existing dodge movement, dodge recovery, animation selection, sidearm logic, block logic, and enemy marine dash behavior.
- Add only the minimum damage-gating needed for dodge i-frames.
- After each file edit, run a syntax check or at least inspect the changed function bodies for GDScript syntax errors.

Goal:

The Operator should have a short invulnerability window during the **active dodge only**. Dodge recovery should be vulnerable. If an enemy dash or normal enemy attack resolves during the i-frame window, the Operator should take no damage and should not receive marine dash knockback / hit reaction.

Change only these files:

1. `custodian/game/actors/operator/operator.gd`
2. `custodian/game/actors/enemies/enemy.gd`

Do not change:

- `custodian/game/actors/base/controllable_actor.gd`
- animation state files
- `.tscn` files
- `.tres` files
- `project.godot`
- art/import files

---

## 1. Edit `custodian/game/actors/operator/operator.gd`

### 1A. Add dodge i-frame exports

Find the existing dodge export block near:

```gdscript
@export var dodge_speed: float = 480.0
@export var dodge_duration: float = 0.20
@export var dodge_recovery_duration: float = 0.16
@export var dodge_cooldown: float = 0.42
@export var dodge_stamina_cost: float = 16.0
```

Add these two exports after `dodge_duration`:

```gdscript
@export var dodge_iframe_duration: float = 0.16
@export var dodge_iframe_debug_enabled: bool = false
```

Result should look like:

```gdscript
@export var dodge_speed: float = 480.0
@export var dodge_duration: float = 0.20
@export var dodge_iframe_duration: float = 0.16
@export var dodge_recovery_duration: float = 0.16
@export var dodge_cooldown: float = 0.42
@export var dodge_stamina_cost: float = 16.0
@export var dodge_iframe_debug_enabled: bool = false
```

If you prefer to keep debug exports grouped away from tuning vars, that is fine, but do not create a new export group.

---

### 1B. Add an iframe timer var

Find the existing dodge runtime vars:

```gdscript
var _dodge_active: bool = false
var _dodge_recovery_active: bool = false
var _dodge_timer: float = 0.0
var _dodge_recovery_timer: float = 0.0
var _dodge_cooldown_remaining: float = 0.0
var _dodge_direction: Vector2 = Vector2.DOWN
var _dodge_backstep_active: bool = false
```

Add `_dodge_iframe_timer` after `_dodge_timer`:

```gdscript
var _dodge_active: bool = false
var _dodge_recovery_active: bool = false
var _dodge_timer: float = 0.0
var _dodge_iframe_timer: float = 0.0
var _dodge_recovery_timer: float = 0.0
var _dodge_cooldown_remaining: float = 0.0
var _dodge_direction: Vector2 = Vector2.DOWN
var _dodge_backstep_active: bool = false
```

---

### 1C. Tick the iframe timer in `_process(delta)`

Find `_process(delta)` and this existing section near the top:

```gdscript
fire_cooldown_remaining = max(0.0, fire_cooldown_remaining - delta)
melee_cooldown_remaining = max(0.0, melee_cooldown_remaining - delta)
_dodge_cooldown_remaining = max(0.0, _dodge_cooldown_remaining - delta)
current_recoil = max(0.0, current_recoil - recoil_decay * delta)
```

Add the iframe timer update directly after `_dodge_cooldown_remaining`:

```gdscript
fire_cooldown_remaining = max(0.0, fire_cooldown_remaining - delta)
melee_cooldown_remaining = max(0.0, melee_cooldown_remaining - delta)
_dodge_cooldown_remaining = max(0.0, _dodge_cooldown_remaining - delta)
_dodge_iframe_timer = maxf(0.0, _dodge_iframe_timer - delta)
current_recoil = max(0.0, current_recoil - recoil_decay * delta)
```

Do not put this inside `_physics_process`; keep it in `_process` with the other timers so it always ticks.

---

### 1D. Start i-frames when dodge starts

Find `_try_start_dodge()`.

Inside it, find:

```gdscript
_dodge_timer = maxf(0.05, dodge_duration)
_dodge_recovery_timer = 0.0
```

Change it to:

```gdscript
_dodge_timer = maxf(0.05, dodge_duration)
_dodge_iframe_timer = minf(maxf(0.0, dodge_iframe_duration), _dodge_timer)
_dodge_recovery_timer = 0.0
```

This makes the default 0.16s iframe window fit inside the default 0.20s active dodge.

---

### 1E. End i-frames when active dodge ends

Find `_start_dodge_recovery()`.

At the very top of the function body, add:

```gdscript
_dodge_iframe_timer = 0.0
```

The function should begin like this:

```gdscript
func _start_dodge_recovery() -> void:
	_dodge_iframe_timer = 0.0
	_dodge_recovery_timer = maxf(0.0, dodge_recovery_duration)
	if _dodge_recovery_timer <= 0.0 or not _has_dodge_recovery_animation():
		_dodge_recovery_active = false
		velocity = velocity.move_toward(Vector2.ZERO, move_deceleration * get_physics_process_delta_time())
		return
	_dodge_recovery_active = true
	_play_dodge_recovery_animation(true)
```

This is important: recovery should be punishable.

---

### 1F. Clear i-frames when dodge is cancelled

Find `_cancel_dodge()`.

Add `_dodge_iframe_timer = 0.0` with the other reset lines:

```gdscript
func _cancel_dodge() -> void:
	_dodge_active = false
	_dodge_recovery_active = false
	_dodge_timer = 0.0
	_dodge_iframe_timer = 0.0
	_dodge_recovery_timer = 0.0
	_dodge_backstep_active = false
	_hide_dodge_fx()
```

---

### 1G. Add helper methods near the dodge methods

Add these methods near the other dodge functions, preferably after `_cancel_dodge()` and before `_play_dodge_animation()`:

```gdscript
func _is_dodge_invulnerable() -> bool:
	return _dodge_active and _dodge_iframe_timer > 0.0 and not _is_dead


func is_dodge_invulnerable() -> bool:
	return _is_dodge_invulnerable()


func _should_ignore_incoming_damage_for_dodge(source: String = "") -> bool:
	if not _is_dodge_invulnerable():
		return false
	if dodge_iframe_debug_enabled:
		print("[Operator] Dodge i-frame avoided incoming damage: ", source)
	return true
```

Notes:

- `is_dodge_invulnerable()` is intentionally public so enemy code can query it without reaching into private vars.
- `_is_dodge_invulnerable()` requires `_dodge_active`, so recovery is not invulnerable even if a timer somehow remains.

---

### 1H. Gate `receive_projectile_hit()`

Find the existing function:

```gdscript
func receive_projectile_hit(amount: float, _attacker_team: String = "neutral") -> Dictionary:
```

Replace the whole function with this:

```gdscript
func receive_projectile_hit(amount: float, _attacker_team: String = "neutral") -> Dictionary:
	if _should_ignore_incoming_damage_for_dodge("receive_projectile_hit"):
		return {
			"blocked": false,
			"dodged": true,
			"applied_damage": 0.0,
		}

	if _is_blocking() and stamina >= block_stamina_cost_per_hit:
		stamina = max(0.0, stamina - block_stamina_cost_per_hit)
		return {
			"blocked": true,
			"dodged": false,
			"applied_damage": 0.0,
		}

	if _is_block_state_active():
		_block_phase = &"exit"
		_block_active = false
		_play_block_animation(&"melee_2h_block_exit")

	take_damage(amount)
	return {
		"blocked": false,
		"dodged": false,
		"applied_damage": max(0.0, amount),
	}
```

Do not remove existing block behavior. Dodge should take priority over block because this is an avoidance window, not a mitigation state.

---

### 1I. Gate direct `take_damage()`

Find the existing Operator `take_damage(amount: float)` function.

At the top, after the `_is_dead` guard, add the dodge guard.

The function should begin like this:

```gdscript
func take_damage(amount: float):
	if _is_dead:
		return

	if _should_ignore_incoming_damage_for_dodge("take_damage"):
		return

	health = max(0.0, health - amount)
	current_health = health
```

Leave the rest of `take_damage()` unchanged.

---

### 1J. Gate dash impact knockback / hit reaction

Find:

```gdscript
func apply_enemy_dash_impact(direction: Vector2, knockback_px: float, victim_hitstop_sec: float) -> void:
```

At the top, after the `_is_dead` guard, add the dodge guard:

```gdscript
func apply_enemy_dash_impact(direction: Vector2, knockback_px: float, victim_hitstop_sec: float) -> void:
	if _is_dead:
		return

	if _should_ignore_incoming_damage_for_dodge("apply_enemy_dash_impact"):
		return

	var impact_direction := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.DOWN
```

Leave the rest of the function unchanged.

This prevents marine dash from applying knockback or hit-recoil during i-frames even if some enemy path still calls `apply_enemy_dash_impact()`.

---

## 2. Edit `custodian/game/actors/enemies/enemy.gd`

### 2A. Update marine dash hit resolution to respect dodged results

Find this existing function:

```gdscript
func _apply_marine_dash_hit(hit_node: Node2D) -> void:
```

Replace the whole function with this:

```gdscript
func _apply_marine_dash_hit(hit_node: Node2D) -> void:
	_marine_dash_last_attack_hit = true

	var hit_result: Dictionary = {}

	if hit_node.has_method("receive_projectile_hit"):
		var result: Variant = hit_node.call("receive_projectile_hit", _marine_dash_current_damage, team)
		if result is Dictionary:
			hit_result = result
	elif hit_node.has_method("take_damage"):
		if hit_node.has_method("is_dodge_invulnerable") and bool(hit_node.call("is_dodge_invulnerable")):
			return
		hit_node.call("take_damage", _marine_dash_current_damage)

	if bool(hit_result.get("dodged", false)):
		return

	var knockback_direction := _marine_dash_direction.normalized()
	if hit_node is CharacterBody2D:
		var body := hit_node as CharacterBody2D
		body.velocity = knockback_direction * (marine_dash_knockback_px / maxf(0.12, marine_dash_recovery_time))
		body.move_and_slide()
	if hit_node.has_method("apply_enemy_dash_impact"):
		hit_node.call("apply_enemy_dash_impact", knockback_direction, marine_dash_knockback_px, marine_dash_victim_hitstop)
	_trigger_marine_dash_camera_feedback()
	_apply_marine_dash_hitstop(maxf(marine_dash_victim_hitstop, marine_dash_attacker_hitstop))
	_marine_dash_attacker_hitstop_timer = maxf(_marine_dash_attacker_hitstop_timer, marine_dash_attacker_hitstop)
	_start_marine_dash_impact_lock()
```

Important behavior:

- If the Operator returns `{ "dodged": true }`, the marine dash does not apply knockback, camera hit feedback, hitstop, or victim impact lock.
- If the Operator blocks and returns `{ "blocked": true }`, current dash impact behavior remains mostly unchanged. Do not redesign blocking in this task.
- The target remains in `_marine_dash_hit_targets`, because `_try_apply_marine_dash_hit()` already appended it before calling this function. This is acceptable: a successful dodge should not be hit repeatedly by the same dash active window.

---

## 3. Do not change normal enemy windup logic

Do not edit `_execute_queued_attack()` unless absolutely necessary.

Reason:

Normal non-marine enemy attacks already call `target.take_damage(...)`. The Operator-side `take_damage()` dodge gate will now handle those hits. No enemy refactor is needed.

---

## 4. Acceptance checks

After edits, run these checks:

```bash
cd ~/Projects/CUSTODIAN

rg "dodge_iframe|dodged|is_dodge_invulnerable" custodian/game/actors/operator/operator.gd custodian/game/actors/enemies/enemy.gd
```

Expected:

- `operator.gd` contains:
  - `dodge_iframe_duration`
  - `dodge_iframe_debug_enabled`
  - `_dodge_iframe_timer`
  - `_is_dodge_invulnerable`
  - `is_dodge_invulnerable`
  - `_should_ignore_incoming_damage_for_dodge`
  - dodged return dictionary in `receive_projectile_hit`

- `enemy.gd` contains:
  - check for `hit_result.get("dodged", false)`
  - optional fallback query to `is_dodge_invulnerable`

Then run the game and test:

1. Marine dash hits while not dodging:
   - Operator takes damage.
   - Operator gets knockback / hit reaction.
   - Camera impact feedback still happens.

2. Dodge timed through marine dash active frames:
   - Operator takes no damage.
   - Operator does not get dash knockback.
   - Operator does not enter hit recoil.
   - Marine dash does not repeatedly re-hit during the same dash.

3. Dodge recovery mistimed:
   - Operator can be hit during recovery.
   - This confirms recovery is punishable.

4. Normal grunt melee while dodging:
   - During active i-frame window: no damage.
   - Outside i-frame window: damage applies normally.

5. Blocking:
   - Blocking still returns `blocked = true`.
   - Do not redesign block response in this task.

---

## 5. Expected design result

Dodge should now feel like:

- startup/active dodge: short invulnerable escape window
- recovery: vulnerable
- mistimed dodge: punishable
- correctly timed dodge through dash: avoids damage and knockback

Default tuning:

```gdscript
dodge_duration = 0.20
dodge_iframe_duration = 0.16
dodge_recovery_duration = 0.16
```

Do not increase i-frames beyond active dodge duration. If tuning later, prefer `0.14–0.18`.
