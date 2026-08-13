extends WorldIngressSite
class_name AshBellLiftIngressSite

const PRESENTATION_SCENE := preload(
	"res://game/world/approaches/ash_bell/"
	+ "ash_bell_lift_ingress_presentation.tscn"
)
const THREADWAY_SCRIPT := preload(
	"res://game/world/approaches/ash_bell/ash_bell_threadway_causeway.gd"
)
const THREADWAY_EVENT_ID := &"ash_bell_threadway_unlocked"
const THREADWAY_RESOURCE_ID := "white_thread_knot"
const THREADWAY_FALLBACK_MAX_LENGTH := 30
const THREADWAY_FALLBACK_LATERAL_ALLOWANCE := 10

var _presentation: AshBellLiftIngressPresentation
var _threadway: AshBellThreadwayCauseway = null
var _threadway_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger != null and not ledger.resource_added.is_connected(
		_on_resource_added
	):
		ledger.resource_added.connect(_on_resource_added)
	call_deferred("_initialize_threadway_state")


func _init() -> void:
	requires_explicit_interaction = true


func _ensure_visual() -> void:
	_presentation = (
		PRESENTATION_SCENE.instantiate()
		as AshBellLiftIngressPresentation
	)
	if _presentation == null:
		push_error("[AshBellLiftIngressSite] Presentation scene failed to instantiate")
		return
	_presentation.name = "AshBellLiftIngressPresentation"
	add_child(_presentation)


func get_interaction_position() -> Vector2:
	if _presentation != null:
		return _presentation.get_boarding_position()
	return global_position


func _initialize_threadway_state() -> void:
	var memory := get_node_or_null("/root/WorldEventMemory")
	var ledger := get_node_or_null("/root/ResourceLedger")
	var completed := memory != null and bool(memory.call("is_completed", THREADWAY_EVENT_ID))
	var pre_acquired := ledger != null and int(ledger.call("get_amount", THREADWAY_RESOURCE_ID)) > 0
	if not completed and pre_acquired and memory != null:
		memory.call("mark_completed", THREADWAY_EVENT_ID, {
			"resource_id": THREADWAY_RESOURCE_ID,
			"source": "resource_acquisition",
		})
		completed = true
	if completed:
		_resolve_threadway(false)


func _on_resource_added(resource_id: String, _amount: int, new_total: int) -> void:
	if resource_id != THREADWAY_RESOURCE_ID or new_total <= 0:
		return
	var memory := get_node_or_null("/root/WorldEventMemory")
	var already_completed := memory != null and bool(memory.call("is_completed", THREADWAY_EVENT_ID))
	if not already_completed and memory != null:
		memory.call("mark_completed", THREADWAY_EVENT_ID, {
			"resource_id": THREADWAY_RESOURCE_ID,
			"source": "resource_acquisition",
		})
		_observe(&"ash_bell_threadway_unlocked", {
			"resource_id": THREADWAY_RESOURCE_ID,
			"source": "resource_acquisition",
		})
	if _threadway == null:
		_resolve_threadway(not already_completed)


func _resolve_threadway(play_reveal: bool) -> void:
	if _threadway != null or _presentation == null or _main_map == null:
		return
	if not _main_map.has_method("resolve_runtime_walkable_connector"):
		push_warning("[AshBellLiftIngressSite] Procgen map has no runtime connector authority")
		return
	_threadway_result = {}
	var config := (
		get_meta("world_ingress_unlock_causeway", {}) as Dictionary
	).duplicate(true)
	var outward := get_meta(
		"world_ingress_outward_direction",
		Vector2i.UP
	) as Vector2i
	_observe(&"ash_bell_threadway_resolution_started", {
		"play_reveal": play_reveal,
		"position": global_position,
	})
	var width := int(config.get("width_tiles", 3))
	var canonical_length := int(config.get("max_length_tiles", 18))
	var selected_length := canonical_length
	var selected_lateral := -1
	var canonical_plan: Dictionary = {}
	if _main_map.has_method("evaluate_runtime_walkable_connector"):
		canonical_plan = _main_map.call(
			"evaluate_runtime_walkable_connector",
			_presentation.get_interaction_approach_position(), -outward,
			width, canonical_length, "ash_bell_threadway", "white_thread", -1
		) as Dictionary
		if not bool(canonical_plan.get("ok", false)) and str(canonical_plan.get("reason", "")) == "no mainland endpoint within connector budget":
			selected_length = maxi(canonical_length, THREADWAY_FALLBACK_MAX_LENGTH)
			selected_lateral = THREADWAY_FALLBACK_LATERAL_ALLOWANCE
			var fallback_plan := _main_map.call(
				"evaluate_runtime_walkable_connector",
				_presentation.get_interaction_approach_position(), -outward,
				width, selected_length, "ash_bell_threadway", "white_thread",
				selected_lateral
			) as Dictionary
			if bool(fallback_plan.get("ok", false)):
				_observe(&"ash_bell_threadway_resolution_fallback", {
					"canonical_budget": canonical_length,
					"fallback_budget": selected_length,
					"fallback_lateral_allowance": selected_lateral,
					"island_anchor": fallback_plan.get("island_anchor_tile"),
					"endpoint": fallback_plan.get("endpoint_tile"),
					"cell_count": (fallback_plan.get("cells", []) as Array).size(),
				})
			else:
				_threadway_result = fallback_plan
		if not canonical_plan.is_empty() and bool(canonical_plan.get("ok", false)):
			selected_length = canonical_length
			selected_lateral = -1
	if not _threadway_result.is_empty() and not bool(_threadway_result.get("ok", false)):
		_report_resolution_failure(_threadway_result, canonical_plan)
		return
	_threadway_result = _main_map.call(
		"resolve_runtime_walkable_connector",
		_presentation.get_interaction_approach_position(),
		-outward,
		width,
		selected_length,
		"ash_bell_threadway",
		"white_thread",
		selected_lateral
	) as Dictionary
	if not bool(_threadway_result.get("ok", false)):
		_report_resolution_failure(_threadway_result, canonical_plan)
		return
	_threadway = THREADWAY_SCRIPT.new() as AshBellThreadwayCauseway
	_threadway.name = "AshBellThreadwayCauseway"
	add_child(_threadway)
	_threadway.resolution_finished.connect(_on_threadway_resolution_finished)
	_threadway.configure(_main_map, _threadway_result, play_reveal)


func _report_resolution_failure(result: Dictionary, canonical_plan: Dictionary = {}) -> void:
	var payload := result.duplicate(true)
	payload["canonical_budget"] = int((get_meta("world_ingress_unlock_causeway", {}) as Dictionary).get("max_length_tiles", 18))
	if not canonical_plan.is_empty():
		payload["canonical_diagnostic"] = canonical_plan.duplicate(true)
	push_warning("[AshBellLiftIngressSite] Threadway resolution failed: %s diagnostic=%s" % [str(result.get("reason", "unknown")), str(payload)])
	_observe(&"ash_bell_threadway_resolution_failed", payload)


func _on_threadway_resolution_finished() -> void:
	_observe(&"ash_bell_threadway_resolved", {
		"position": global_position,
		"cell_count": (_threadway_result.get("cells", []) as Array).size(),
		"new_cell_count": (_threadway_result.get("new_cells", []) as Array).size(),
		"already_connected": bool(_threadway_result.get("already_connected", false)),
	})


func _observe(kind: StringName, data: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", kind, data)


func debug_get_threadway_result() -> Dictionary:
	return _threadway_result.duplicate(true)


func debug_get_threadway() -> AshBellThreadwayCauseway:
	return _threadway


func get_procgen_dressing_clearance_world_rect() -> Rect2:
	if _presentation == null:
		return Rect2()
	return _presentation.get_procgen_dressing_clearance_world_rect()


func interact(actor: Node) -> void:
	if not (actor is Node2D):
		return
	if _presentation == null:
		return
	if not _presentation.is_actor_boarded(actor as Node2D):
		return
	super.interact(actor)


func _play_entry_presentation(actor: Node) -> void:
	if _presentation == null or not (actor is Node2D):
		return
	await _presentation.play_descent(actor as Node2D)


func reset_after_level_return() -> void:
	super.reset_after_level_return()
	if _presentation != null:
		call_deferred("_play_return_presentation")


func _play_return_presentation() -> void:
	if _presentation == null:
		return
	var actor := get_tree().get_first_node_in_group("player") as Node2D
	if actor == null:
		_presentation.reset_presentation()
		return
	await _presentation.play_ascent(actor)
