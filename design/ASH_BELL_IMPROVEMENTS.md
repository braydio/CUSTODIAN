# NOTE FOR DEVELOPING AGENT: I HATE THE WORD CLAPPER. PLEASE SUBSTITUTE ANOTHER WORD THAT SERVES A SIMILAR PURPoS

IMPLEMENT THE FOLLOWING CHANGES TO REMOVE THE WORD CLAPPER

## Best replacement: **The Stilling Pin**

This is much better.

```text
Item: The Stilling Pin
Pickup prompt: TAKE STILLING PIN
Use prompt: SET THE STILLING PIN
```

Why it works:

```text
- Simple
- Game-readable
- Ties to silence without saying “silence artifact of the ancient bell god”
- Can visually be a small relic, not a goofy bell part
- Works with the white thread / fountain / ritual mechanics
- Sounds like a tool, not a fantasy noun generator
```

Lore feel:

```text
A black iron pin used to hold the rite in place.
Not a key. Not a weapon.
A thing driven into stone when the dead must stay counted.
```

It also fits your existing event structure: the code originally had `has_clapper`, `TAKE_CLAPPER`, `RING_CLAPPER`, `bronze_clapper_pickup`, and `clapper_swing`, so this can replace the clapper without redesigning the whole event.

Rename path:

```text
has_clapper
→ has_stilling_pin

TAKE_CLAPPER
→ TAKE_STILLING_PIN

RING_CLAPPER
→ SET_STILLING_PIN

bronze_clapper_pickup
→ stilling_pin_pickup

RING SILENCE
→ SET THE STILLING PIN
```

## Even better prompt flow

Instead of:

```text
TAKE BELL-CLAPPER
RING SILENCE
```

Use:

```text
TAKE STILLING PIN
SET PIN IN BASIN
```

That is way more grounded.

## Visual design

The Stilling Pin should be:

```text
- 32x32 or 32x48 pickup
- blackened iron spike
- dull brass collar
- tiny blue-white thread wrapped around it
- one cracked ceramic/bone tag hanging from it
- faint pale glow at the tip
```

It should look like something between a **ritual survey marker**, **rail spike**, and **reliquary tool**.
Use **Stilling Pin** for the item name, and use **Set Pin in Basin** as the action.

Final event language:

```text
TAKE STILLING PIN
SET PIN IN BASIN
```

Ritualant warning:

```text
“Do not set it.”
“The basin remembers pressure.”
“The dead were held there for a reason.”
```

Below are **drop-in code changes** for the existing Ash-Bell / Forlorn Ritualant scene. These target the scripts you pasted: `AshBellEventState`, `AshBellInteractable`, `ForlornRitualantSite`, and `WhiteThreadHazard`. Your current event already has pressure, thread tension, fountain states, hostile phase, ghost procession, ash FX, apparition, and stilling pin pickup wired; these changes make those systems more readable and staged.

## 1. Replace `ash_bell_interactable.gd`

**Filename:**

```text
custodian/game/world/events/ash_bell/ash_bell_interactable.gd
```

**Replace the whole file with this:**

```gdscript
class_name AshBellInteractable
extends Area2D

enum InteractionKind {
	RITUALANT,
	ASK_BELL,
	ASK_THREAD,
	ASK_ORRA,
	TOUCH_THREAD,
	CUT_THREAD,
	TAKE_STILLING_PIN,
	DRY_FOUNTAIN,
	SET_STILLING_PIN,
}

@export var interaction_kind: int = InteractionKind.RITUALANT
@export var site_path: NodePath
@export var interaction_distance: float = 84.0
@export var prompt_text: String = ""

## If true, child visuals under this Area2D are hidden while the interaction is locked.
@export var hide_when_locked: bool = true

## If true, the Area2D stops being detectable while locked.
@export var disable_monitorable_when_locked: bool = true

@onready var site: ForlornRitualantSite = get_node_or_null(site_path)

var _refresh_timer: float = 0.0
var _last_available: bool = true


func _ready() -> void:
	add_to_group("interactable")
	_refresh_availability(true)


func _process(delta: float) -> void:
	_refresh_timer = maxf(0.0, _refresh_timer - delta)
	if _refresh_timer > 0.0:
		return

	_refresh_timer = 0.12
	_refresh_availability(false)


func can_interact(_actor: Node = null) -> bool:
	if site == null or site.event_state == null:
		return false

	var state := site.event_state

	match interaction_kind:
		InteractionKind.RITUALANT:
			return not state.ritualant_hostile \
				and state.resolution < AshBellEventState.Resolution.PROVOKED_RITUALANT

		InteractionKind.ASK_BELL, InteractionKind.ASK_THREAD, InteractionKind.ASK_ORRA:
			return state.resolution >= AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
				and not state.ritualant_hostile

		InteractionKind.TOUCH_THREAD:
			return state.resolution >= AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
				and not state.has_thread_knot \
				and not state.ritualant_hostile

		InteractionKind.CUT_THREAD:
			return state.resolution >= AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
				and not state.ritualant_hostile \
				and state.resolution != AshBellEventState.Resolution.CUT_THREAD

		InteractionKind.TAKE_STILLING_PIN:
			return state.resolution >= AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
				and not state.has_stilling_pin

		InteractionKind.DRY_FOUNTAIN:
			return state.resolution >= AshBellEventState.Resolution.SEEN \
				and state.fountain_state != AshBellEventState.FountainState.BLACK_WATER

		InteractionKind.SET_STILLING_PIN:
			return state.has_stilling_pin \
				and state.resolution >= AshBellEventState.Resolution.TOOK_STILLING_PIN \
				and state.resolution != AshBellEventState.Resolution.SET_STILLING_PIN

		_:
			return true


func get_interaction_prompt() -> String:
	if not can_interact():
		return ""

	if not prompt_text.strip_edges().is_empty():
		return prompt_text

	match interaction_kind:
		InteractionKind.RITUALANT:
			return "LISTEN TO FORLORN-RITUALANT"
		InteractionKind.ASK_BELL:
			return "ASK: BELL?"
		InteractionKind.ASK_THREAD:
			return "ASK: THREAD?"
		InteractionKind.ASK_ORRA:
			return "ASK: ORRA?"
		InteractionKind.TOUCH_THREAD:
			return "TOUCH WHITE THREAD"
		InteractionKind.CUT_THREAD:
			return "CUT WHITE THREAD"
		InteractionKind.TAKE_STILLING_PIN:
			return "TAKE STILLING PIN"
		InteractionKind.DRY_FOUNTAIN:
			return "INSPECT DRY FOUNTAIN"
		InteractionKind.SET_STILLING_PIN:
			return "SET PIN IN BASIN"
		_:
			return "INTERACT"


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	if site == null:
		push_warning("AshBellInteractable has no site reference.")
		return

	if not can_interact(actor):
		return

	match interaction_kind:
		InteractionKind.RITUALANT:
			site.interact_with_ritualant()

		InteractionKind.ASK_BELL:
			site.ask_about_bell()

		InteractionKind.ASK_THREAD:
			site.ask_about_thread()

		InteractionKind.ASK_ORRA:
			site.ask_about_orra()

		InteractionKind.TOUCH_THREAD:
			site.touch_thread()

		InteractionKind.CUT_THREAD:
			site.cut_thread()

		InteractionKind.TAKE_STILLING_PIN:
			site.take_stilling_pin()

		InteractionKind.DRY_FOUNTAIN:
			site.inspect_dry_fountain()

		InteractionKind.SET_STILLING_PIN:
			site.set_stilling_pin()


func _refresh_availability(force: bool) -> void:
	var available := can_interact()
	if not force and available == _last_available:
		return

	_last_available = available

	if disable_monitorable_when_locked:
		monitorable = available
		monitoring = true

	if hide_when_locked:
		for child in get_children():
			if child is CanvasItem:
				(child as CanvasItem).visible = available
```

What this fixes: the player will no longer see all prompts at once. “Ask Bell / Thread / Orra” unlocks after speaking to the Ritualant. “Touch Thread,” “Cut Thread,” “Take Stilling Pin,” and “Set Pin in Basin” are gated by actual event state.

---

## 2. Patch `ash_bell_event_state.gd`

**Filename:**

```text
custodian/game/world/events/ash_bell/ash_bell_event_state.gd
```

Add these methods **after `calm_thread()`**:

```gdscript
func set_thread_tension(value: int, reason: StringName = &"unknown") -> void:
	var previous := thread_tension
	thread_tension = clampi(value, 0, 100)
	if thread_tension == previous:
		return

	pressure_changed.emit(silence_pressure, thread_tension)

	if thread_tension >= 100:
		set_resolution(Resolution.CUT_THREAD)


func set_silence_pressure(value: int, reason: StringName = &"unknown") -> void:
	var previous := silence_pressure
	silence_pressure = clampi(value, 0, 100)
	if silence_pressure == previous:
		return

	pressure_changed.emit(silence_pressure, thread_tension)
	_apply_pressure_thresholds(reason)


func is_completed() -> bool:
	return resolution == Resolution.RITUALANT_DISSOLVED \
		or resolution == Resolution.SITE_STABILIZED \
		or resolution == Resolution.SITE_DEFILED
```

This gives you clean setters instead of mutating `thread_tension` directly from the site script. That matters because direct mutation skips the `pressure_changed` signal.

---

## 3. Patch `forlorn_ritualant_site.gd`

**Filename:**

```text
custodian/game/world/events/ash_bell/forlorn_ritualant_site.gd
```

### 3A. Add new exported paths and tuning vars

Add this block under the existing `@export var dialogue_label_path: NodePath`:

```gdscript
@export_group("Optional Stagecraft Paths")
@export var silence_veil_path: NodePath
@export var pressure_halo_path: NodePath
@export var thread_visual_path: NodePath
@export var fountain_ring_path: NodePath
@export var bell_shadow_path: NodePath

@export_group("Encounter Tuning")
@export var fountain_pressure_tick_seconds: float = 2.0
@export var fountain_pressure_per_tick: int = 1
@export var fountain_stabilize_seconds: float = 4.5
@export var peaceful_exit_requires_thread_touch: bool = false
```

Then add these `@onready` vars under the existing `@onready var dialogue_label` line:

```gdscript
@onready var silence_veil: CanvasItem = get_node_or_null(silence_veil_path)
@onready var pressure_halo: CanvasItem = get_node_or_null(pressure_halo_path)
@onready var thread_visual: CanvasItem = get_node_or_null(thread_visual_path)
@onready var fountain_ring: CanvasItem = get_node_or_null(fountain_ring_path)
@onready var bell_shadow: CanvasItem = get_node_or_null(bell_shadow_path)
```

Add this new var near your other private vars:

```gdscript
var _fountain_stabilize_time: float = 0.0
```

---

### 3B. Replace `_ready()`

Replace your current `_ready()` with this:

```gdscript
func _ready() -> void:
	add_to_group("ash_bell_site")
	if event_state == null:
		event_state = AshBellEventState.new()

	event_state.pressure_changed.connect(_on_pressure_changed)
	event_state.fountain_state_changed.connect(_on_fountain_state_changed)
	event_state.resolution_changed.connect(_on_resolution_changed)
	event_state.knowledge_unlocked.connect(_on_knowledge_unlocked)
	request_dialogue.connect(_on_request_dialogue)
	request_item_grant.connect(_on_request_item_grant)
	request_knowledge_unlock.connect(_on_request_knowledge_unlock)

	_set_initial_visibility()
	_update_event_atmosphere()
	_update_debug()
```

---

### 3C. Replace `_process(delta)`

Replace your current `_process()` with this:

```gdscript
func _process(delta: float) -> void:
	if _player_inside_fountain:
		_fountain_stand_time += delta

		if _fountain_stand_time >= fountain_pressure_tick_seconds:
			_fountain_stand_time = 0.0
			event_state.add_silence_pressure(fountain_pressure_per_tick, &"standing_in_dry_fountain")

		if event_state.has_thread_knot \
				and not event_state.ritualant_hostile \
				and event_state.fountain_state == AshBellEventState.FountainState.CRACKED_ANCHORED:
			_fountain_stabilize_time += delta
			if _fountain_stabilize_time >= fountain_stabilize_seconds:
				stabilize_site()
		else:
			_fountain_stabilize_time = 0.0
	else:
		_fountain_stabilize_time = 0.0

	_update_event_atmosphere()
	_update_debug()
```

This makes the fountain do something more meaningful: if the player touches the thread and stands in the cracked anchored fountain, the site can stabilize.

---

### 3D. Add these new public interaction methods

Add these after `take_stilling_pin()`:

```gdscript
func inspect_dry_fountain() -> void:
	if event_state.fountain_state == AshBellEventState.FountainState.ABSENT:
		event_state.set_fountain_state(AshBellEventState.FountainState.GHOST)

	event_state.add_silence_pressure(3, &"fountain_touched")
	event_state.unlock_knowledge(&"ash_bell_dry_fountain")


func set_stilling_pin() -> void:
	if not event_state.has_stilling_pin:
		return

	event_state.set_resolution(AshBellEventState.Resolution.SET_STILLING_PIN)
	event_state.add_silence_pressure(35, &"stilling_pin_set")
	_show_unarrived_apparition()
	_trigger_ghost_procession()
```

This moves the logic out of the interactable and into the site, where it belongs.

---

### 3E. Replace `cut_thread()`

Replace your current `cut_thread()` with this:

```gdscript
func cut_thread() -> void:
	if event_state.ritualant_hostile:
		return

	event_state.set_thread_tension(100, &"thread_cut")
	event_state.set_resolution(AshBellEventState.Resolution.CUT_THREAD)
	event_state.add_silence_pressure(25, &"thread_cut")
	request_dialogue.emit(dialogue_id, &"cut_thread_response")
	_show_unarrived_apparition()
	_start_hostile_phase()
```

---

### 3F. Replace `exit_site()`

Replace your current `exit_site()` with this:

```gdscript
func exit_site() -> void:
	if _completed:
		return

	if event_state.ritualant_hostile:
		return

	if event_state.resolution == AshBellEventState.Resolution.SPOKE_TO_RITUALANT \
			or event_state.resolution == AshBellEventState.Resolution.TOUCHED_THREAD \
			or event_state.resolution == AshBellEventState.Resolution.TOOK_STILLING_PIN:
		if peaceful_exit_requires_thread_touch and not event_state.has_thread_knot:
			return

		request_dialogue.emit(dialogue_id, &"peaceful_exit")
		_complete_if_ready()
```

This lets the event complete peacefully after a meaningful state, not only exactly `SPOKE_TO_RITUALANT`.

---

### 3G. Replace `_on_pressure_changed(...)`

Replace your current `_on_pressure_changed()` with this:

```gdscript
func _on_pressure_changed(_silence_pressure: int, _thread_tension: int) -> void:
	_update_event_atmosphere()

	if event_state.silence_pressure >= 25 and upward_ash != null:
		upward_ash.speed_scale = 0.55

	if event_state.silence_pressure >= 75:
		_trigger_ghost_procession()

	if event_state.silence_pressure >= 90 and not event_state.ritualant_hostile:
		_start_hostile_phase()
```

---

### 3H. Add `_update_event_atmosphere()`

Add this near `_set_downward_ash_enabled()`:

```gdscript
func _update_event_atmosphere() -> void:
	if event_state == null:
		return

	var pressure := clampf(float(event_state.silence_pressure) / 100.0, 0.0, 1.0)
	var tension := clampf(float(event_state.thread_tension) / 100.0, 0.0, 1.0)

	if silence_veil != null:
		silence_veil.visible = pressure > 0.02
		silence_veil.modulate.a = lerpf(0.0, 0.45, pressure)

	if pressure_halo != null:
		pressure_halo.visible = pressure > 0.02
		pressure_halo.modulate.a = lerpf(0.0, 0.85, pressure)

	if thread_visual != null:
		thread_visual.visible = event_state.resolution >= AshBellEventState.Resolution.SEEN
		thread_visual.modulate.a = lerpf(0.25, 1.0, tension)

	if fountain_ring != null:
		fountain_ring.visible = event_state.fountain_state != AshBellEventState.FountainState.ABSENT
		match event_state.fountain_state:
			AshBellEventState.FountainState.GHOST:
				fountain_ring.modulate = Color(0.55, 0.72, 1.0, lerpf(0.35, 0.75, pressure))
			AshBellEventState.FountainState.BLACK_WATER:
				fountain_ring.modulate = Color(0.05, 0.08, 0.12, lerpf(0.65, 1.0, pressure))
			AshBellEventState.FountainState.CRACKED_ANCHORED:
				fountain_ring.modulate = Color(0.95, 0.82, 0.42, 0.8)
			_:
				fountain_ring.modulate.a = 0.0

	if bell_shadow != null:
		bell_shadow.visible = true
		bell_shadow.modulate.a = lerpf(0.25, 0.75, pressure)

	if upward_ash != null:
		upward_ash.amount_ratio = lerpf(0.25, 1.0, pressure)
		upward_ash.speed_scale = lerpf(0.22, 0.62, pressure)

	if downward_ash != null and downward_ash.emitting:
		downward_ash.amount_ratio = lerpf(0.35, 1.0, pressure)

	if ghost_procession != null and ghost_procession.visible:
		ghost_procession.modulate.a = lerpf(0.25, 0.72, pressure)
```

---

## 4. Replace `white_thread_hazard.gd`

**Filename:**

```text
custodian/game/world/events/ash_bell/white_thread_hazard.gd
```

**Replace the whole file with this:**

```gdscript
class_name WhiteThreadHazard
extends Area2D

@export var site_path: NodePath
@export var slow_multiplier: float = 0.88
@export var tension_tick_interval: float = 0.75

## Optional child/node visual for the actual white thread line.
@export var thread_visual_path: NodePath

## Small immediate penalty when first entering the thread.
@export var entry_tension_amount: int = 1

@onready var site: ForlornRitualantSite = get_node_or_null(site_path)
@onready var thread_visual: CanvasItem = get_node_or_null(thread_visual_path)

var _bodies_inside: Dictionary = {}
var _tick_timer: float = 0.0
var _visual_pulse: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()


func _physics_process(delta: float) -> void:
	_tick_timer = maxf(0.0, _tick_timer - delta)
	_visual_pulse = maxf(0.0, _visual_pulse - delta)

	var player_inside := false

	for body_variant in _bodies_inside.keys():
		var body := body_variant as Node
		if body == null or not is_instance_valid(body):
			_bodies_inside.erase(body_variant)
			continue

		if not body.is_in_group("player"):
			continue

		player_inside = true

		if _tick_timer <= 0.0 and site != null:
			site.player_crossed_thread(_infer_move_kind(body))
			_visual_pulse = 0.18

		_apply_slow(body)

	if _tick_timer <= 0.0:
		_tick_timer = tension_tick_interval

	_update_visual(player_inside)


func _on_body_entered(body: Node) -> void:
	_bodies_inside[body] = true

	if body != null and body.is_in_group("player") and site != null:
		site.event_state.add_thread_tension(entry_tension_amount, &"thread_entry")
		_visual_pulse = 0.22


func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)


func _infer_move_kind(body: Node) -> StringName:
	if body.has_method("is_dodging") and bool(body.call("is_dodging")):
		return &"dodge"

	if "is_sprinting" in body and bool(body.get("is_sprinting")):
		return &"run"

	if body.has_method("is_sprinting") and bool(body.call("is_sprinting")):
		return &"run"

	return &"walk"


func _apply_slow(body: Node) -> void:
	if body.has_method("apply_external_speed_multiplier"):
		body.call("apply_external_speed_multiplier", slow_multiplier, 0.15)


func _update_visual(player_inside: bool = false) -> void:
	if thread_visual == null:
		return

	thread_visual.visible = true

	var base_alpha := 0.45
	if site != null and site.event_state != null:
		var tension := clampf(float(site.event_state.thread_tension) / 100.0, 0.0, 1.0)
		base_alpha = lerpf(0.35, 0.95, tension)

	if player_inside:
		base_alpha = maxf(base_alpha, 0.82)

	if _visual_pulse > 0.0:
		base_alpha = 1.0

	thread_visual.modulate = Color(0.78, 0.88, 1.0, base_alpha)
```

This makes the thread feel “alive” instead of being just an invisible slow/tension zone.

---

## 5. Add a new visual helper script: `ash_bell_stagecraft.gd`

**New filename:**

```text
custodian/game/world/events/ash_bell/ash_bell_stagecraft.gd
```

**Create this file:**

```gdscript
class_name AshBellStagecraft
extends Node2D

@export var site_path: NodePath = NodePath("..")

@export_group("Local Layout")
@export var room_rect: Rect2 = Rect2(Vector2(-240, -160), Vector2(480, 320))
@export var fountain_center: Vector2 = Vector2(0, -12)
@export var fountain_radius: float = 58.0
@export var thread_y: float = 42.0
@export var thread_half_width: float = 168.0
@export var bell_anchor: Vector2 = Vector2(0, -132.0)
@export var entry_y: float = 126.0

@export_group("Rendering")
@export var draw_room_veil: bool = true
@export var draw_bell_shadow: bool = true
@export var draw_thread: bool = true
@export var draw_fountain_ring: bool = true
@export var draw_entry_threshold: bool = true

@onready var site: ForlornRitualantSite = get_node_or_null(site_path)

var _time: float = 0.0


func _ready() -> void:
	z_index = 40
	y_sort_enabled = false


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pressure := 0.0
	var tension := 0.0
	var fountain_state := AshBellEventState.FountainState.ABSENT
	var resolution := AshBellEventState.Resolution.UNSEEN
	var hostile := false

	if site != null and site.event_state != null:
		pressure = clampf(float(site.event_state.silence_pressure) / 100.0, 0.0, 1.0)
		tension = clampf(float(site.event_state.thread_tension) / 100.0, 0.0, 1.0)
		fountain_state = site.event_state.fountain_state
		resolution = site.event_state.resolution
		hostile = site.event_state.ritualant_hostile

	if draw_room_veil:
		_draw_room_veil(pressure, hostile)

	if draw_bell_shadow:
		_draw_bell_shadow(pressure)

	if draw_fountain_ring:
		_draw_fountain(fountain_state, pressure)

	if draw_thread:
		_draw_white_thread(resolution, tension)

	if draw_entry_threshold:
		_draw_entry_threshold(pressure)


func _draw_room_veil(pressure: float, hostile: bool) -> void:
	var alpha := lerpf(0.08, 0.28, pressure)
	if hostile:
		alpha = maxf(alpha, 0.36)

	draw_rect(room_rect, Color(0.01, 0.015, 0.02, alpha), true)

	var top_shadow := Rect2(room_rect.position, Vector2(room_rect.size.x, 56.0))
	draw_rect(top_shadow, Color(0.0, 0.0, 0.0, lerpf(0.18, 0.48, pressure)), true)


func _draw_bell_shadow(pressure: float) -> void:
	var chain_color := Color(0.58, 0.50, 0.36, lerpf(0.22, 0.72, pressure))
	var shadow_color := Color(0.0, 0.0, 0.0, lerpf(0.25, 0.62, pressure))

	draw_line(bell_anchor, fountain_center + Vector2(0, -38), chain_color, 2.0)
	draw_circle(bell_anchor + Vector2(0, -8), 10.0, shadow_color)
	draw_arc(bell_anchor + Vector2(0, 10), 28.0, PI * 0.05, PI * 0.95, 18, shadow_color, 3.0)


func _draw_fountain(fountain_state: int, pressure: float) -> void:
	if fountain_state == AshBellEventState.FountainState.ABSENT:
		draw_arc(fountain_center, fountain_radius, 0.0, TAU, 48, Color(0.16, 0.15, 0.13, 0.28), 2.0)
		return

	var pulse := 0.5 + 0.5 * sin(_time * 2.4)

	var color := Color(0.40, 0.62, 1.0, lerpf(0.25, 0.72, pressure))
	match fountain_state:
		AshBellEventState.FountainState.GHOST:
			color = Color(0.42, 0.62, 1.0, lerpf(0.28, 0.72, maxf(pressure, pulse * 0.35)))
		AshBellEventState.FountainState.BLACK_WATER:
			color = Color(0.02, 0.035, 0.055, lerpf(0.70, 0.95, pressure))
			draw_circle(fountain_center, fountain_radius - 8.0, color)
			color = Color(0.10, 0.18, 0.28, 0.85)
		AshBellEventState.FountainState.CRACKED_ANCHORED:
			color = Color(0.95, 0.77, 0.38, 0.78)

	draw_arc(fountain_center, fountain_radius, 0.0, TAU, 64, color, 3.0)
	draw_arc(fountain_center, fountain_radius - 14.0, 0.0, TAU, 64, Color(color.r, color.g, color.b, color.a * 0.55), 2.0)

	## Cracks / broken basin lines.
	draw_line(fountain_center + Vector2(-28, -8), fountain_center + Vector2(-6, 15), color, 1.0)
	draw_line(fountain_center + Vector2(12, -22), fountain_center + Vector2(30, 10), color, 1.0)
	draw_line(fountain_center + Vector2(-8, 24), fountain_center + Vector2(18, 36), color, 1.0)


func _draw_white_thread(resolution: int, tension: float) -> void:
	if resolution < AshBellEventState.Resolution.SEEN:
		return

	var pulse := 0.5 + 0.5 * sin(_time * lerpf(2.0, 8.0, tension))
	var alpha := lerpf(0.35, 0.98, tension)
	alpha = maxf(alpha, pulse * 0.28)

	var y := thread_y + sin(_time * 1.7) * lerpf(0.5, 2.5, tension)
	var left := Vector2(-thread_half_width, y)
	var right := Vector2(thread_half_width, y)

	draw_line(left, right, Color(0.78, 0.90, 1.0, alpha), 2.0)
	draw_line(left + Vector2(0, 3), right + Vector2(0, 3), Color(0.35, 0.50, 0.70, alpha * 0.30), 1.0)

	## Thread anchor knots.
	draw_circle(left, 4.0, Color(0.78, 0.90, 1.0, alpha))
	draw_circle(right, 4.0, Color(0.78, 0.90, 1.0, alpha))


func _draw_entry_threshold(pressure: float) -> void:
	var y := entry_y
	var color := Color(0.62, 0.56, 0.42, lerpf(0.25, 0.55, pressure))
	draw_line(Vector2(-112, y), Vector2(112, y), color, 3.0)
	draw_line(Vector2(-72, y + 8), Vector2(72, y + 8), Color(0.0, 0.0, 0.0, 0.28), 2.0)
```

### Add it to the scene

In `forlorn_ritualant_site.tscn`, add a child:

```text
ForlornRitualantSite
└── Stagecraft
```

Set:

```text
Node type: Node2D
Script: custodian/game/world/events/ash_bell/ash_bell_stagecraft.gd
site_path: ..
z_index: 40
```

This gives you immediate visible staging without requiring new art assets yet: bell shadow, fountain ring, white thread, threshold, and pressure veil.

---

## 6. Optional scene node names to add

To make the exported paths in `ForlornRitualantSite` useful, add these optional child nodes when you have time:

```text
ForlornRitualantSite
├── FX
│   ├── SilenceVeil              CanvasItem / Polygon2D / Sprite2D
│   ├── PressureHalo             Sprite2D / Polygon2D
│   ├── ThreadVisual             Line2D / Sprite2D
│   ├── FountainRing             Sprite2D / Line2D
│   └── BellShadow               Sprite2D / Polygon2D
```

Then assign:

```text
silence_veil_path = FX/SilenceVeil
pressure_halo_path = FX/PressureHalo
thread_visual_path = FX/ThreadVisual
fountain_ring_path = FX/FountainRing
bell_shadow_path = FX/BellShadow
```

The new code is null-safe, so the event still runs even if you do not add these nodes yet.

---

## 7. Quick smoke test checklist

After applying:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN/custodian
```

Run Godot and verify:

```text
1. Entering room triggers proximity intro once.
2. Only “LISTEN TO FORLORN-RITUALANT” is available at first.
3. After listening, Ask Bell / Ask Thread / Ask Orra unlock.
4. White thread visibly pulses after the event is seen.
5. Crossing the thread increases thread tension.
6. Cutting the thread triggers apparition + hostile phase.
7. Touching the thread creates the calmer/stabilizing path.
8. Standing in the fountain after touching thread eventually stabilizes the site.
9. Taking stilling pin unlocks Set Stilling Pin.
10. Debug label still updates pressure/thread/fountain/resolution.
```

The most important changes are `ash_bell_interactable.gd` and `ash_bell_stagecraft.gd`. Those two alone should make the event feel much less like a debug box and much more like an authored ritual encounter.
