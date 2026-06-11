Use this as the next Codex prompt. It assumes the current repo may already contain the earlier i-frame commit and the later range-check commit, but tells Codex to **clean up the questionable parts first**: the log shows a likely duplicate `receive_projectile_hit()` call and a possibly malformed double `if distance > ...` edit.

You are working in `~/Projects/CUSTODIAN`.

Operate in **low-code-ability mode**:

- Make surgical edits only.
- Do not refactor the whole combat system.
- Do not rename existing public functions unless explicitly instructed.
- Do not move scenes/resources.
- Do not touch art/import files.
- Keep existing movement, animation, dodge, sidearm, block, enemy AI, and marine dash structure intact.
- Add a clean damage-resolution layer with the smallest number of changes.
- After edits, inspect the exact changed functions and run syntax checks.

Goal:

Implement the best low-risk damage application model:

```text
Enemy attack begins:
  - Enemy checks that target is close enough to start windup.

Enemy active hit resolves:
  - Re-check target still exists.
  - Re-check target is still in range.
  - Re-check target is still inside the attack cone/arc.
  - Ask the target to resolve the hit through a high-level damage receiver.

Target resolves hit:
  - Dodge i-frame -> dodged, no damage, no knockback.
  - Block -> blocked, no damage, optional block stamina cost.
  - Otherwise -> damaged.

Enemy responds:
  - Dodged -> do not apply hitstop, knockback, or camera impact.
  - Blocked/damaged -> apply normal hit feedback.
  - Whiffed because target moved away -> no damage.
```

This should fix both problems:

1. **Tight dodge timing**: player should avoid damage during active i-frames.
2. **Early spacing dodge**: player should avoid delayed windup damage if they moved out of range before the hit resolves.

Current known problem to clean up:

- In `enemy.gd`, the previous Codex patch may have accidentally called `receive_projectile_hit()` twice inside `_apply_marine_dash_hit()`. Remove that.
- In `enemy.gd`, the previous range check may have accidentally left a malformed double condition like:

```gdscript
if distance > attack_range * 1.15:
if distance > attack_range * 1.25:
```

Fix this if present.

Change only:

```text
custodian/game/actors/operator/operator.gd
custodian/game/actors/enemies/enemy.gd
```

Do not change:

```text
custodian/game/actors/base/controllable_actor.gd
custodian/game/actors/operator/animations/**/*.gd
custodian/game/systems/combat/**/*.gd
custodian/project.godot
*.tscn
*.tres
*.png
*.import
```

---

# Part 1 — Operator damage receiver

## 1A. Verify existing dodge iframe fields exist

In `custodian/game/actors/operator/operator.gd`, confirm these exports exist near the dodge exports:

```gdscript
@export var dodge_iframe_duration: float = 0.16
@export var dodge_iframe_debug_enabled: bool = false
```

Confirm this runtime var exists near the other dodge vars:

```gdscript
var _dodge_iframe_timer: float = 0.0
```

Confirm `_process(delta)` ticks it:

```gdscript
_dodge_iframe_timer = maxf(0.0, _dodge_iframe_timer - delta)
```

Confirm `_try_start_dodge()` sets it:

```gdscript
_dodge_iframe_timer = minf(maxf(0.0, dodge_iframe_duration), _dodge_timer)
```

Confirm `_start_dodge_recovery()` clears it:

```gdscript
_dodge_iframe_timer = 0.0
```

Confirm `_cancel_dodge()` clears it:

```gdscript
_dodge_iframe_timer = 0.0
```

If any are missing, add them. If they are already present, do not duplicate them.

---

## 1B. Keep or add the dodge invulnerability helpers

In `operator.gd`, ensure these helpers exist near the dodge functions:

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

Do not make recovery invulnerable. `_is_dodge_invulnerable()` must require `_dodge_active`.

---

## 1C. Add a single high-level enemy-hit receiver

Add this function in `operator.gd` near `receive_projectile_hit()` and `take_damage()`:

```gdscript
func receive_enemy_hit(amount: float, hit_kind: StringName = &"melee", _attacker_team: String = "enemy") -> Dictionary:
	if _should_ignore_incoming_damage_for_dodge(String(hit_kind)):
		return {
			"result": &"dodged",
			"hit_kind": hit_kind,
			"dodged": true,
			"blocked": false,
			"applied_damage": 0.0,
		}

	if _is_blocking() and stamina >= block_stamina_cost_per_hit:
		stamina = max(0.0, stamina - block_stamina_cost_per_hit)
		return {
			"result": &"blocked",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": true,
			"applied_damage": 0.0,
		}

	if _is_block_state_active():
		_block_phase = &"exit"
		_block_active = false
		_play_block_animation(&"melee_2h_block_exit")

	take_damage(amount)
	return {
		"result": &"damaged",
		"hit_kind": hit_kind,
		"dodged": false,
		"blocked": false,
		"applied_damage": max(0.0, amount),
	}
```

Design notes:

- `receive_enemy_hit()` is now the preferred gameplay damage receiver for enemy melee and dash hits.
- `take_damage()` remains the low-level health subtraction function.
- Dodge is checked before block.
- Blocking behavior should stay as close as possible to the previous `receive_projectile_hit()` behavior.

---

## 1D. Replace `receive_projectile_hit()` with a wrapper

Find:

```gdscript
func receive_projectile_hit(amount: float, _attacker_team: String = "neutral") -> Dictionary:
```

Replace the whole function with:

```gdscript
func receive_projectile_hit(amount: float, _attacker_team: String = "neutral") -> Dictionary:
	return receive_enemy_hit(amount, &"projectile", _attacker_team)
```

Reason:

- This prevents duplicated dodge/block logic.
- Projectiles, melee, and dash all resolve through the same damage-result contract.

---

## 1E. Keep a safety guard in `take_damage()`

Find:

```gdscript
func take_damage(amount: float):
```

Make sure it starts like this:

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

Reason:

- `receive_enemy_hit()` should be the main path.
- But direct `take_damage()` calls should still be safe during dodge i-frames.

---

## 1F. Keep a safety guard in `apply_enemy_dash_impact()`

Find:

```gdscript
func apply_enemy_dash_impact(direction: Vector2, knockback_px: float, victim_hitstop_sec: float) -> void:
```

Make sure it starts like this:

```gdscript
func apply_enemy_dash_impact(direction: Vector2, knockback_px: float, victim_hitstop_sec: float) -> void:
	if _is_dead:
		return

	if _should_ignore_incoming_damage_for_dodge("apply_enemy_dash_impact"):
		return

	var impact_direction := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.DOWN
```

Leave the rest unchanged.

Reason:

- Marine dash should not apply knockback/hit-recoil if the player dodged.
- Enemy-side code will also skip this on dodged results, but this guard protects future callers.

---

# Part 2 — Enemy attack resolution

Edit `custodian/game/actors/enemies/enemy.gd`.

## 2A. Add melee hit tuning exports

Near the existing attack exports:

```gdscript
@export var attack_windup_duration: float = 0.10
@export var hit_recoil_duration: float = 0.12
```

Add:

```gdscript
@export var melee_hit_range_grace_multiplier: float = 1.15
@export var melee_hit_range_grace_px: float = 10.0
@export var melee_hit_arc_degrees: float = 95.0
```

Reasonable tuning:

```text
melee_hit_range_grace_multiplier = 1.10–1.20
melee_hit_range_grace_px = 6–12
melee_hit_arc_degrees = 85–105
```

Start with the values above.

---

## 2B. Add pending attack context vars

Near the existing pending attack vars:

```gdscript
var _attack_windup_timer: float = 0.0
var _pending_attack_damage: float = 0.0
var _stagger_timer: float = 0.0
```

Add:

```gdscript
var _pending_attack_forward: Vector2 = Vector2.DOWN
var _pending_attack_range_px: float = 0.0
var _pending_attack_arc_degrees: float = 95.0
```

---

## 2C. Capture attack context at windup start

Find:

```gdscript
func _start_attack_windup(queued_damage: float, is_strong: bool) -> void:
```

At the top of the function, after these existing lines:

```gdscript
_pending_attack_damage = queued_damage
_attack_windup_timer = max(0.01, attack_windup_duration)
_windup_attack_is_strong = is_strong
```

Add:

```gdscript
_capture_pending_attack_context()
```

Then add this helper near `_start_attack_windup()`:

```gdscript
func _capture_pending_attack_context() -> void:
	_pending_attack_range_px = 40.0
	_pending_attack_arc_degrees = melee_hit_arc_degrees

	if target is Node2D:
		var target_node := target as Node2D
		_pending_attack_range_px = _get_attack_range(target_node)

		var to_target := target_node.global_position - global_position
		if to_target.length_squared() > 0.0001:
			_pending_attack_forward = to_target.normalized()
			return

	if _last_move_direction.length_squared() > 0.0001:
		_pending_attack_forward = _last_move_direction.normalized()
	else:
		_pending_attack_forward = Vector2.DOWN
```

Reason:

- Enemy attacks should commit to the direction/range they had at windup.
- They should not magically re-aim or gain range at the hit frame.

---

## 2D. Add pending attack cleanup helper

Add this near the pending attack helpers:

```gdscript
func _clear_pending_attack_context() -> void:
	_pending_attack_damage = 0.0
	_windup_attack_is_strong = false
	_pending_attack_range_px = 0.0
	_pending_attack_arc_degrees = melee_hit_arc_degrees
```

Do not reset `used_strong_attack` here. If a strong attack whiffs, it should still count as used because the enemy committed to the strong swing.

---

## 2E. Add range + arc hit validation

Add this helper near `_execute_queued_attack()`:

```gdscript
func _can_pending_attack_connect(target_node: Node2D) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false

	var to_target := target_node.global_position - global_position
	var distance := to_target.length()
	if distance <= 0.001:
		return true

	var connect_range := (_pending_attack_range_px * melee_hit_range_grace_multiplier) + melee_hit_range_grace_px
	if distance > connect_range:
		return false

	var forward := _pending_attack_forward
	if forward.length_squared() <= 0.0001:
		forward = _last_move_direction
	if forward.length_squared() <= 0.0001:
		forward = to_target.normalized()

	var angle := abs(rad_to_deg(forward.normalized().angle_to(to_target.normalized())))
	return angle <= _pending_attack_arc_degrees * 0.5
```

This is the key spacing-dodge fix.

It means:

- If the enemy starts a swing and the player dodges out of range before impact, the hit whiffs.
- If the player dodges behind or far to the side, the hit whiffs.
- If the player dodges too late and is still in range/arc after i-frames end, the hit can land.

---

## 2F. Add a single enemy hit application helper

Add this helper near `_execute_queued_attack()`:

```gdscript
func _apply_enemy_hit_to_target(hit_node: Node, amount: float, hit_kind: StringName = &"melee") -> Dictionary:
	if hit_node == null or not is_instance_valid(hit_node):
		return {
			"result": &"no_target",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"applied_damage": 0.0,
		}

	if hit_node.has_method("receive_enemy_hit"):
		var result: Variant = hit_node.call("receive_enemy_hit", amount, hit_kind, team)
		if result is Dictionary:
			return result as Dictionary

	if hit_node.has_method("is_dodge_invulnerable") and bool(hit_node.call("is_dodge_invulnerable")):
		return {
			"result": &"dodged",
			"hit_kind": hit_kind,
			"dodged": true,
			"blocked": false,
			"applied_damage": 0.0,
		}

	if hit_node.has_method("take_damage"):
		hit_node.call("take_damage", amount)
		return {
			"result": &"damaged",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"applied_damage": max(0.0, amount),
		}

	return {
		"result": &"no_receiver",
		"hit_kind": hit_kind,
		"dodged": false,
		"blocked": false,
		"applied_damage": 0.0,
	}
```

Reason:

- Enemy code should not directly decide dodge/block/damage.
- The target should resolve how it handles the hit.
- This keeps damage application consistent for grunt melee and marine dash.

Do not call `receive_projectile_hit()` from this helper. Enemy melee/dash should use `receive_enemy_hit()`. `receive_projectile_hit()` remains only for actual projectile compatibility.

---

## 2G. Replace `_execute_queued_attack()`

Find:

```gdscript
func _execute_queued_attack() -> void:
```

Replace the whole function with this:

```gdscript
func _execute_queued_attack() -> void:
	if dead:
		_clear_pending_attack_context()
		return

	if target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		_clear_pending_attack_context()
		return

	var target_node := target as Node2D
	if target_node == null:
		_clear_pending_attack_context()
		return

	if not _can_pending_attack_connect(target_node):
		if _threat_highlight_enabled:
			print("Enemy attack whiffed: ", enemy_name, " target moved out of active hit area")
		_clear_pending_attack_context()
		return

	var hit_result := _apply_enemy_hit_to_target(target_node, _pending_attack_damage, &"melee")
	if bool(hit_result.get("dodged", false)):
		if _threat_highlight_enabled:
			print("Enemy attack dodged: ", enemy_name)
	elif bool(hit_result.get("blocked", false)):
		if _threat_highlight_enabled:
			print("Enemy attack blocked: ", enemy_name)
	elif float(hit_result.get("applied_damage", 0.0)) > 0.0:
		print("Enemy hit ", target.name, " for ", float(hit_result.get("applied_damage", 0.0)), " damage!")

	_clear_pending_attack_context()
```

Important:

- This replaces the old direct `target.take_damage(_pending_attack_damage)`.
- It also replaces any previous malformed range check.
- It should not contain two consecutive `if distance > ...` lines.
- It should not directly call `take_damage()`.

---

## 2H. Replace `_apply_marine_dash_hit()`

Find:

```gdscript
func _apply_marine_dash_hit(hit_node: Node2D) -> void:
```

Replace the whole function with this:

```gdscript
func _apply_marine_dash_hit(hit_node: Node2D) -> void:
	var hit_result := _apply_enemy_hit_to_target(hit_node, _marine_dash_current_damage, &"dash")

	if bool(hit_result.get("dodged", false)):
		_marine_dash_last_attack_hit = false
		return

	_marine_dash_last_attack_hit = true

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

- Dodged dash:
  - no damage
  - no knockback
  - no hit reaction
  - no camera impact
  - no hitstop
  - no dash impact lock
  - dash continues until travel/collision/end condition

- Blocked or damaged dash:
  - normal hit feedback still happens

- `_marine_dash_last_attack_hit = true` only happens after the dodge check.

Also ensure there is no duplicate call like this:

```gdscript
hit_node.call("receive_projectile_hit", _marine_dash_current_damage, team)
var result: Variant = hit_node.call("receive_projectile_hit", _marine_dash_current_damage, team)
```

That must not exist.

---

# Part 3 — Cleanup old accidental code

Run:

```bash
cd ~/Projects/CUSTODIAN

rg -n "receive_projectile_hit" custodian/game/actors/enemies/enemy.gd
```

Expected:

- Ideally zero results in `enemy.gd`.
- If any direct `receive_projectile_hit()` call remains in enemy melee/dash code, remove it unless it is genuinely for projectile-specific enemy logic.

Run:

```bash
rg -n "attack_range \\* 1\\.15|attack_range \\* 1\\.25|distance > attack_range" custodian/game/actors/enemies/enemy.gd
```

Expected:

- No leftover malformed or old range-check code inside `_execute_queued_attack()`.
- The new `_can_pending_attack_connect()` should be the only melee connection check.

Run:

```bash
rg -n "func receive_enemy_hit|func receive_projectile_hit|func _apply_enemy_hit_to_target|func _can_pending_attack_connect|func _apply_marine_dash_hit|func _execute_queued_attack" \
  custodian/game/actors/operator/operator.gd \
  custodian/game/actors/enemies/enemy.gd
```

Expected:

- `operator.gd` has:
  - `receive_enemy_hit`
  - `receive_projectile_hit`

- `enemy.gd` has:
  - `_apply_enemy_hit_to_target`
  - `_can_pending_attack_connect`
  - `_apply_marine_dash_hit`
  - `_execute_queued_attack`

---

# Part 4 — Syntax and diff checks

Run:

```bash
cd ~/Projects/CUSTODIAN

git diff -- custodian/game/actors/operator/operator.gd custodian/game/actors/enemies/enemy.gd
```

Manually inspect:

- `_apply_marine_dash_hit()` does not call damage twice.
- `_execute_queued_attack()` has no malformed nested `if`.
- `receive_projectile_hit()` is now a wrapper.
- `receive_enemy_hit()` is the main high-level receiver.
- `take_damage()` still contains the old health, damage popup, death, and reaction behavior.

Then run Godot syntax check:

```bash
if command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path custodian --quit
else
  godot --headless --path custodian --quit
fi
```

If Godot reports parser errors, fix them before committing.

---

# Part 5 — Manual gameplay test

Test these cases:

## Case 1 — Normal grunt melee, no dodge

Expected:

- Enemy starts windup.
- Player stays in range.
- Hit resolves.
- Player takes damage.
- Damage popup / reaction still works.

## Case 2 — Normal grunt melee, early dodge out of range

Expected:

- Enemy starts windup.
- Player dodges away before active hit resolves.
- `_can_pending_attack_connect()` returns false.
- No damage.
- No hit reaction.
- This is a whiff, not an i-frame dodge.

## Case 3 — Normal grunt melee, tight dodge through hit

Expected:

- Player is still in range/arc.
- Enemy active hit resolves during active dodge i-frames.
- `receive_enemy_hit()` returns dodged.
- No damage.
- No hit reaction.

## Case 4 — Mistimed dodge recovery

Expected:

- Player dodges too early or too late.
- I-frames expire.
- Player is still in range/arc during recovery.
- Hit lands.
- Recovery is punishable.

## Case 5 — Marine dash, no dodge

Expected:

- Dash hits.
- Player takes damage.
- Player gets knockback / impact reaction.
- Camera/hitstop feedback happens.

## Case 6 — Marine dash, dodge through active dash hit

Expected:

- Dash active overlap occurs during dodge i-frames.
- `receive_enemy_hit(..., &"dash", team)` returns dodged.
- `_apply_marine_dash_hit()` returns immediately.
- No damage.
- No knockback.
- No hit reaction.
- No camera impact feedback.
- No hitstop.
- Dash should continue/finish naturally.

## Case 7 — Marine dash, player simply outspaces

Expected:

- If dash active hit volume never reaches player, no hit occurs.
- No damage and no hit feedback.

---

# Part 6 — Commit

If all tests pass:

```bash
git add custodian/game/actors/operator/operator.gd custodian/game/actors/enemies/enemy.gd

git commit -m "fix(combat): Route enemy damage through hit results

Adds a high-level Operator receive_enemy_hit() damage receiver so
enemy melee, dash, dodge i-frames, and block responses resolve through
one consistent result contract.

Updates enemy melee windup execution to re-check range and arc at the
active hit moment, preventing delayed hits from landing after the player
dodges out of range.

Updates marine dash hit resolution to respect dodged results before
applying knockback, camera feedback, hitstop, or impact lock."
```

Do not commit if syntax check fails.

---

# Final design result

After this change, combat damage should feel like this:

```text
Dodge during active i-frames:
  clean avoid

Dodge early and leave the hit area:
  enemy whiffs

Dodge too early but remain in range during recovery:
  player gets punished

Block:
  block result, no damage

No defense:
  damage applies normally
```

This is the intended low-risk version of a real active-frame hitbox system without fully refactoring enemy attacks into Area2D hitboxes yet.
