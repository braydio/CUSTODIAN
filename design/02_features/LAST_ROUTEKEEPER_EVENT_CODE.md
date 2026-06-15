# The Last Routekeeper — Drop-In Code

**Status:** draft  
**Design doc:** `design/02_features/LAST_ROUTEKEEPER_EVENT.md`  
**Runtime target:** Godot 4.x / Sundered Keep  

---

## File 1: `world_event_memory.gd`

**Path:** `custodian/game/systems/core/state/world_event_memory.gd`

```gdscript
extends Node
class_name WorldEventMemory

var _completed_events: Dictionary = {}
var _spawned_events: Dictionary = {}
var _event_payloads: Dictionary = {}
var run_seed: int = 0


func reset_run_events(p_run_seed := 0) -> void:
	run_seed = int(p_run_seed)
	_completed_events.clear()
	_spawned_events.clear()
	_event_payloads.clear()


func has_spawned(event_id: StringName) -> bool:
	return bool(_spawned_events.get(String(event_id), false))


func mark_spawned(event_id: StringName, payload := {}) -> void:
	var key := String(event_id)
	_spawned_events[key] = true
	if payload is Dictionary:
		_event_payloads[key] = (payload as Dictionary).duplicate(true)


func is_completed(event_id: StringName) -> bool:
	return bool(_completed_events.get(String(event_id), false))


func mark_completed(event_id: StringName, payload := {}) -> void:
	var key := String(event_id)
	_completed_events[key] = true
	_spawned_events[key] = true
	if payload is Dictionary:
		_event_payloads[key] = (payload as Dictionary).duplicate(true)


func get_payload(event_id: StringName) -> Dictionary:
	return (_event_payloads.get(String(event_id), {}) as Dictionary).duplicate(true)


func get_event_seed(event_id: StringName, salt := "") -> int:
	var key := "%s:%s:%s" % [String(event_id), str(run_seed), salt]
	return abs(hash(key))
```

---

## File 2: `last_routekeeper_event_state.gd`

**Path:** `custodian/game/world/events/last_routekeeper/last_routekeeper_event_state.gd`

```gdscript
extends Resource
class_name LastRoutekeeperEventState

const EVENT_ID := &"last_routekeeper"

@export var signature := "B. CHAFFEE"
@export var assignment := "RETURN CORRIDOR SURVEY"
@export var status := "UNACKNOWLEDGED"

@export var discovered := false
@export var completed := false
@export var route_hint_tile := Vector2i.ZERO

var route_notes := [
	"ROUTE NOTE 003:\nBRIDGE VISIBLE. SHORE TRAVERSABLE. CENTER SPAN UNRELIABLE.",
	"ROUTE NOTE 009:\nMARKED THE LOWER STONES AGAIN. THE SEA KEEPS TAKING THE PAINT.",
	"ROUTE NOTE 014:\nIF THE GATE DOES NOT OPEN, THE ROAD BENEATH STILL REMEMBERS TRAFFIC.",
	"ROUTE NOTE 018:\nRETURNED TO MARK THE WAY BACK.\nRETURN NOT OBSERVED.",
]


func get_header_lines() -> Array[String]:
	return [
		"ROUTE AUTHORITY TRACE DETECTED",
		"SIGNATURE: %s" % signature,
		"ASSIGNMENT: %s" % assignment,
		"STATUS: %s" % status,
	]


func get_recovery_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append_array(get_header_lines())
	lines.append("")
	for note in route_notes:
		lines.append(note)
		lines.append("")
	lines.append("ROUTEKEEPER TRACE RECOVERED")
	lines.append("LOCAL TRAVERSAL HINT RECONSTRUCTED")
	return lines
```

---

## File 3: `last_routekeeper_event.gd`

**Path:** `custodian/game/world/events/last_routekeeper/last_routekeeper_event.gd`

```gdscript
extends Node2D
class_name LastRoutekeeperEvent

signal trace_recovered(route_hint_tile: Vector2i)

const INTERACTABLE_SCRIPT := preload("res://game/world/sundered_keep/sundered_keep_interactable.gd")
const STATE_SCRIPT := preload("res://game/world/events/last_routekeeper/last_routekeeper_event_state.gd")

const TILE_SIZE := 32.0
const EVENT_KIND := &"last_routekeeper_trace"

@export var interaction_distance := 78.0

var connected_map: Node = null
var state: LastRoutekeeperEventState = null
var route_hint_tile := Vector2i.ZERO

var _interactable: Node2D = null
var _projection: Node2D = null
var _beacon: Node2D = null
var _pulse_tween: Tween = null


func configure(p_map: Node, p_route_hint_tile: Vector2i) -> void:
	connected_map = p_map
	route_hint_tile = p_route_hint_tile
	state = STATE_SCRIPT.new()
	state.route_hint_tile = route_hint_tile


func _ready() -> void:
	if state == null:
		state = STATE_SCRIPT.new()
		state.route_hint_tile = route_hint_tile
	_build_placeholder_visuals()
	_build_interactable()


func recover_trace() -> void:
	if state.completed:
		return
	state.completed = true
	_play_recovery_feedback()
	trace_recovered.emit(route_hint_tile)


func get_recovery_lines() -> Array[String]:
	if state == null:
		return []
	return state.get_recovery_lines()


func _build_interactable() -> void:
	_interactable = INTERACTABLE_SCRIPT.new() as Node2D
	_interactable.name = "LastRoutekeeperTraceInteraction"
	_interactable.position = Vector2.ZERO
	add_child(_interactable)
	_interactable.call(
		"configure",
		connected_map,
		EVENT_KIND,
		"RECOVER ROUTEKEEPER TRACE",
		interaction_distance
	)


func _build_placeholder_visuals() -> void:
	# Placeholder beacon. Replace with routekeeper_survey_beacon_01.png later.
	_beacon = Node2D.new()
	_beacon.name = "RoutekeeperSurveyBeaconPlaceholder"
	add_child(_beacon)

	var base := Polygon2D.new()
	base.name = "BeaconBase"
	base.polygon = PackedVector2Array([
		Vector2(-8, 4),
		Vector2(8, 4),
		Vector2(6, 18),
		Vector2(-6, 18),
	])
	base.color = Color(0.18, 0.16, 0.13, 0.95)
	_beacon.add_child(base)

	var glow := Polygon2D.new()
	glow.name = "BeaconGlow"
	glow.polygon = PackedVector2Array([
		Vector2(-5, -18),
		Vector2(5, -18),
		Vector2(9, 2),
		Vector2(-9, 2),
	])
	glow.color = Color(0.25, 0.85, 0.95, 0.55)
	_beacon.add_child(glow)

	# Placeholder residual figure. Replace with animated sprite later.
	_projection = Node2D.new()
	_projection.name = "RoutekeeperResidualProjectionPlaceholder"
	_projection.position = Vector2(18, -8)
	add_child(_projection)

	var body := Polygon2D.new()
	body.name = "ResidualBody"
	body.polygon = PackedVector2Array([
		Vector2(-10, -42),
		Vector2(10, -42),
		Vector2(14, 8),
		Vector2(-14, 8),
	])
	body.color = Color(0.36, 0.83, 0.95, 0.22)
	_projection.add_child(body)

	var head := Polygon2D.new()
	head.name = "ResidualHead"
	head.polygon = PackedVector2Array([
		Vector2(-7, -58),
		Vector2(7, -58),
		Vector2(8, -43),
		Vector2(-8, -43),
	])
	head.color = Color(0.36, 0.83, 0.95, 0.28)
	_projection.add_child(head)

	var slate := Polygon2D.new()
	slate.name = "SurveySlate"
	slate.polygon = PackedVector2Array([
		Vector2(10, -28),
		Vector2(24, -24),
		Vector2(20, -10),
		Vector2(7, -14),
	])
	slate.color = Color(0.20, 0.95, 0.86, 0.38)
	_projection.add_child(slate)

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(_projection, "modulate:a", 0.35, 0.9)
	_pulse_tween.tween_property(_projection, "modulate:a", 0.82, 0.9)


func _play_recovery_feedback() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	var tween := create_tween()
	tween.tween_property(_projection, "modulate:a", 0.05, 0.55)
	tween.parallel().tween_property(_beacon, "modulate:a", 0.35, 0.55)
	if _interactable != null:
		_interactable.remove_from_group("interactable")
		_interactable.visible = false
```

---

## File 4: SunderedKeepMap — Constants

Add near existing preloads in `sundered_keep_map.gd`:

```gdscript
const LAST_ROUTEKEEPER_EVENT := preload("res://game/world/events/last_routekeeper/last_routekeeper_event.gd")
const LAST_ROUTEKEEPER_EVENT_ID := &"last_routekeeper"
const LAST_ROUTEKEEPER_TRACE_ITEM_ID := &"routekeeper_trace_note"
const LAST_ROUTEKEEPER_TRACE_ITEM_NAME := "Routekeeper Trace"
```

---

## File 5: SunderedKeepMap — Exports

Add near other exported tile vars:

```gdscript
@export var routekeeper_trace_tile: Vector2i = Vector2i(37, 53)
@export var routekeeper_hint_tile: Vector2i = Vector2i(25, 39)
@export_range(0, 100, 1) var routekeeper_base_spawn_chance_percent := 4
@export_range(0, 100, 1) var routekeeper_post_gate_spawn_chance_percent := 12
@export var force_routekeeper_event := false
```

---

## File 6: SunderedKeepMap — State Vars

Add near existing map state vars:

```gdscript
var _last_routekeeper_event: Node2D = null
var _last_routekeeper_interaction: Node2D = null
var _last_routekeeper_trace_recovered := false
var _routekeeper_hint_marker: Node2D = null
```

---

## File 7: SunderedKeepMap — Debug State

Add into `get_sundered_keep_debug_state()`:

```gdscript
"last_routekeeper_spawned": _last_routekeeper_event != null and is_instance_valid(_last_routekeeper_event),
"last_routekeeper_recovered": _last_routekeeper_trace_recovered,
"last_routekeeper_trace_tile": routekeeper_trace_tile,
"last_routekeeper_hint_tile": routekeeper_hint_tile,
```

---

## File 8: SunderedKeepMap — Spawn After Gate Opens

In `_set_main_gate_open(open: bool)`, after `_start_siege()`:

```gdscript
	if open:
		_clear_main_gate_blockers()
		if _main_gate_interaction != null:
			_main_gate_interaction.remove_from_group("interactable")
			_main_gate_interaction.visible = false
		_start_siege()
		_maybe_spawn_last_routekeeper_trace()
```

---

## File 9: SunderedKeepMap — Interaction Routing

Add match case in `_handle_sundered_interaction(...)`:

```gdscript
		&"last_routekeeper_trace":
			_recover_last_routekeeper_trace()
```

---

## File 10: SunderedKeepMap — HUD Prompt

Add case in `_update_hud_prompt()` after the sidearm locker case:

```gdscript
	elif target == _last_routekeeper_interaction and not _last_routekeeper_trace_recovered:
		_hud.show_interaction(
			"ROUTEKEEPER TRACE",
			"Recover route survey",
			input_hint,
			UI_CATALOG.ICON_OBJECTIVE
		)
```

---

## File 11: SunderedKeepMap — Event Methods

Add these methods to `sundered_keep_map.gd`:

```gdscript
func _maybe_spawn_last_routekeeper_trace() -> void:
	if _last_routekeeper_event != null and is_instance_valid(_last_routekeeper_event):
		return
	if _last_routekeeper_trace_recovered:
		return
	if _world_event_completed(LAST_ROUTEKEEPER_EVENT_ID):
		_last_routekeeper_trace_recovered = true
		return
	if _world_event_spawned(LAST_ROUTEKEEPER_EVENT_ID):
		return
	if not force_routekeeper_event and not _passes_last_routekeeper_roll():
		return
	_spawn_last_routekeeper_trace()


func _passes_last_routekeeper_roll() -> bool:
	if force_routekeeper_event:
		return true
	var chance := routekeeper_post_gate_spawn_chance_percent if _main_gate_open else routekeeper_base_spawn_chance_percent
	if chance <= 0:
		return false
	if chance >= 100:
		return true
	var seed := _world_event_seed(LAST_ROUTEKEEPER_EVENT_ID, "%s:%s:%s" % [_level_id, str(routekeeper_trace_tile), str(_main_gate_open)])
	return int(seed % 100) < chance


func _spawn_last_routekeeper_trace() -> void:
	var event := LAST_ROUTEKEEPER_EVENT.new() as Node2D
	if event == null:
		push_warning("[SunderedKeep] Could not instantiate Last Routekeeper event")
		return
	event.name = "LastRoutekeeperTrace"
	event.position = _tile_center(routekeeper_trace_tile)
	event.call("configure", self, routekeeper_hint_tile)
	add_child(event)
	_last_routekeeper_event = event
	_last_routekeeper_interaction = event.get_node_or_null("LastRoutekeeperTraceInteraction") as Node2D
	if event.has_signal("trace_recovered"):
		event.connect("trace_recovered", Callable(self, "_on_last_routekeeper_trace_recovered"))
	_mark_world_event_spawned(LAST_ROUTEKEEPER_EVENT_ID, {
		"level_id": _level_id,
		"trace_tile": routekeeper_trace_tile,
		"hint_tile": routekeeper_hint_tile,
	})
	print("[SunderedKeep] Last Routekeeper trace spawned at %s hint=%s" % [str(routekeeper_trace_tile), str(routekeeper_hint_tile)])


func _recover_last_routekeeper_trace() -> void:
	if _last_routekeeper_trace_recovered:
		return
	if _last_routekeeper_event == null or not is_instance_valid(_last_routekeeper_event):
		return

	var recovery_lines: Array[String] = []
	if _last_routekeeper_event.has_method("get_recovery_lines"):
		recovery_lines = _last_routekeeper_event.call("get_recovery_lines")

	for line in recovery_lines:
		if line.strip_edges() == "":
			continue
		print("[Routekeeper] %s" % line.replace("\n", " | "))

	if _last_routekeeper_event.has_method("recover_trace"):
		_last_routekeeper_event.call("recover_trace")
	else:
		_on_last_routekeeper_trace_recovered(routekeeper_hint_tile)


func _on_last_routekeeper_trace_recovered(hint_tile: Vector2i) -> void:
	if _last_routekeeper_trace_recovered:
		return
	_last_routekeeper_trace_recovered = true
	_reveal_routekeeper_hint(hint_tile)
	_grant_routekeeper_trace_note()
	_mark_world_event_completed(LAST_ROUTEKEEPER_EVENT_ID, {
		"level_id": _level_id,
		"trace_tile": routekeeper_trace_tile,
		"hint_tile": hint_tile,
	})
	if _last_routekeeper_interaction != null and is_instance_valid(_last_routekeeper_interaction):
		_last_routekeeper_interaction.remove_from_group("interactable")
		_last_routekeeper_interaction.visible = false
	if _hud != null and is_instance_valid(_hud):
		_hud.show_interaction(
			"ROUTEKEEPER TRACE RECOVERED",
			"Local traversal hint reconstructed",
			_get_interact_prompt_key(),
			UI_CATALOG.ICON_OBJECTIVE
		)
	_refresh_hud_state()
	print("[SunderedKeep] Routekeeper trace recovered. Revealed traversal hint at %s" % str(hint_tile))


func _reveal_routekeeper_hint(hint_tile: Vector2i) -> void:
	_minimap_floor_cells[hint_tile] = true

	if _routekeeper_hint_marker != null and is_instance_valid(_routekeeper_hint_marker):
		return

	var marker := _add_routekeeper_hint_marker(hint_tile)
	_routekeeper_hint_marker = marker


func _add_routekeeper_hint_marker(tile: Vector2i) -> Node2D:
	var layer := _layers.get("WorldUI", null) as Node2D
	if layer == null:
		return null

	# Prefer production asset later. Placeholder is a small cyan diamond.
	var marker := Polygon2D.new()
	marker.name = "RoutekeeperHintMarker"
	marker.position = _tile_center(tile)
	marker.polygon = PackedVector2Array([
		Vector2(0, -12),
		Vector2(8, 0),
		Vector2(0, 12),
		Vector2(-8, 0),
	])
	marker.color = Color(0.25, 0.85, 0.95, 0.72)
	layer.add_child(marker)
	return marker


func _grant_routekeeper_trace_note() -> void:
	var inventory := get_node_or_null("/root/InventoryManager")
	if inventory != null and inventory.has_method("add_item"):
		inventory.call("add_item", LAST_ROUTEKEEPER_TRACE_ITEM_ID, 1)

	var archive := get_node_or_null("/root/ArchiveManager")
	if archive != null and archive.has_method("add_entry"):
		archive.call("add_entry", LAST_ROUTEKEEPER_TRACE_ITEM_ID, {
			"title": LAST_ROUTEKEEPER_TRACE_ITEM_NAME,
			"source": "Sundered Keep / Return Causeway",
			"body": "An auxiliary routekeeper marked a return path beneath the broken causeway. Return was not observed.",
		})
```

---

## File 12: SunderedKeepMap — WorldEventMemory Bridge Methods

Add these helper methods:

```gdscript
func _world_event_memory() -> Node:
	return get_node_or_null("/root/WorldEventMemory")


func _world_event_spawned(event_id: StringName) -> bool:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("has_spawned"):
		return bool(memory.call("has_spawned", event_id))
	return false


func _world_event_completed(event_id: StringName) -> bool:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("is_completed"):
		return bool(memory.call("is_completed", event_id))
	return false


func _mark_world_event_spawned(event_id: StringName, payload := {}) -> void:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("mark_spawned"):
		memory.call("mark_spawned", event_id, payload)


func _mark_world_event_completed(event_id: StringName, payload := {}) -> void:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("mark_completed"):
		memory.call("mark_completed", event_id, payload)


func _world_event_seed(event_id: StringName, salt := "") -> int:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("get_event_seed"):
		return int(memory.call("get_event_seed", event_id, salt))
	return abs(hash("%s:%s" % [String(event_id), salt]))
```

---

## File 13: `project.godot` — Autoload

Add to `custodian/project.godot`:

```ini
[autoload]

WorldEventMemory="*res://game/systems/core/state/world_event_memory.gd"
```

If an `[autoload]` section already exists, add only this line. Do not duplicate the section header.

---

## File 14: `REQUIRED_ASSETS.md` — Update

Add under the Ash-Bell section:

```md
## Last Routekeeper Event

| needed | Last Routekeeper residual projection animations | `custodian/assets/sprites/events/last_routekeeper/{last_routekeeper_residual_idle_south_96x96_6f,last_routekeeper_residual_mark_south_96x96_6f,last_routekeeper_residual_fade_south_96x96_8f}.png` | Replace placeholder Polygon2D residual figure used by `LastRoutekeeperEvent`. | One-time Sundered Keep random event: route authority trace of B. Chaffee. |
| needed | Last Routekeeper route beacon and route-mark props | `custodian/content/tiles/sundered_keep/events/last_routekeeper/{routekeeper_survey_beacon_01,routekeeper_chalk_marks_01,routekeeper_route_hint_marker_01,routekeeper_hologram_pulse_01}.png` plus `.game32.json` sidecars | Replace placeholder beacon/marker visuals used by `LastRoutekeeperEvent` and Sundered Keep hint reveal. | Lower causeway / underpass traversal readability reward. |
```

---

## Validation Commands

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN/custodian
godot --headless --check-only --quit
git status --short
```
