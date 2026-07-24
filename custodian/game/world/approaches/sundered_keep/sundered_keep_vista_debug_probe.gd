extends CanvasLayer
class_name SunderedKeepVistaDebugProbe

const REFRESH_INTERVAL_SEC := 0.10
const FIRST_TRIGGER_PATH := "SequenceTriggers/FirstVistaRevealTrigger"
const RETURN_TRIGGER_PATH := "SequenceTriggers/ReturnToGameplayTrigger"
const SECOND_TRIGGER_PATH := "SequenceTriggers/SecondVistaRevealTrigger"
const FIRST_ANCHOR_PATH := "Markers/FirstRevealCameraAnchor"
const CONTROL_START_PATH := "Markers/RevealControlStart"
const CONTROL_END_PATH := "Markers/RevealControlEnd"
const SECOND_ANCHOR_PATH := "Markers/SecondVistaCameraAnchor"
const FIRST_COLOR := Color(0.20, 0.92, 1.0, 1.0)
const CONTROL_COLOR := Color(0.98, 0.78, 0.26, 1.0)
const RETURN_COLOR := Color(0.36, 1.0, 0.48, 1.0)
const SECOND_COLOR := Color(1.0, 0.34, 0.82, 1.0)

var _approach: Node2D
var _camera: Camera2D
var _operator: Node2D
var _controller: Node
var _director: Node
var _route_manager: Node
var _label: Label
var _phase_banner: Label
var _target_line: Line2D
var _world_indicators: Dictionary = {}
var _last_phase := ""
var _refresh_accum := 0.0


func _ready() -> void:
	layer = 118
	_approach = get_parent() as Node2D
	_label = Label.new()
	_label.name = "ProbeReadout"
	_label.position = Vector2(18.0, 82.0)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override(
		"font_color",
		Color(0.76, 0.94, 1.0, 1.0)
	)
	_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.96)
	)
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_label)
	_build_transition_indicators()
	_resolve_nodes()
	_refresh_readout()
	call_deferred("_print_route_identity")


func _process(delta: float) -> void:
	_refresh_accum += maxf(delta, 0.0)
	if _refresh_accum < REFRESH_INTERVAL_SEC:
		return
	_refresh_accum = 0.0
	_resolve_nodes()
	_refresh_readout()
	_update_transition_indicators()


func _build_transition_indicators() -> void:
	_phase_banner = Label.new()
	_phase_banner.name = "TransitionPhaseBanner"
	_phase_banner.position = Vector2(520.0, 18.0)
	_phase_banner.size = Vector2(880.0, 44.0)
	_phase_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_banner.add_theme_font_size_override("font_size", 24)
	_phase_banner.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 1.0)
	)
	_phase_banner.add_theme_constant_override("shadow_offset_x", 3)
	_phase_banner.add_theme_constant_override("shadow_offset_y", 3)
	add_child(_phase_banner)

	_target_line = Line2D.new()
	_target_line.name = "ActiveTransitionGuide"
	_target_line.width = 3.0
	_target_line.default_color = FIRST_COLOR
	_target_line.z_index = -1
	add_child(_target_line)

	_add_world_indicator(
		FIRST_TRIGGER_PATH,
		"FIRST REVEAL TRIGGER",
		FIRST_COLOR,
		true
	)
	_add_world_indicator(
		FIRST_ANCHOR_PATH,
		"FIRST CAMERA ANCHOR",
		FIRST_COLOR,
		false
	)
	_add_world_indicator(
		CONTROL_START_PATH,
		"REVEAL CONTROL START",
		CONTROL_COLOR,
		false
	)
	_add_world_indicator(
		CONTROL_END_PATH,
		"REVEAL CONTROL END",
		CONTROL_COLOR,
		false
	)
	_add_world_indicator(
		RETURN_TRIGGER_PATH,
		"RETURN TO GAMEPLAY",
		RETURN_COLOR,
		true
	)
	_add_world_indicator(
		SECOND_TRIGGER_PATH,
		"SECOND REVEAL TRIGGER",
		SECOND_COLOR,
		true
	)
	_add_world_indicator(
		SECOND_ANCHOR_PATH,
		"SECOND CAMERA ANCHOR",
		SECOND_COLOR,
		false
	)


func _add_world_indicator(
	path: String,
	text: String,
	color: Color,
	is_trigger: bool
) -> void:
	var box := ColorRect.new()
	box.name = text.to_pascal_case()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.color = Color(color.r, color.g, color.b, 0.16)
	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.position = Vector2(4.0, -24.0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 1.0)
	)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	box.add_child(label)
	add_child(box)
	_world_indicators[path] = {
		"control": box,
		"color": color,
		"is_trigger": is_trigger,
	}


func _resolve_nodes() -> void:
	_camera = get_node_or_null(
		"/root/GameRoot/World/Camera2D"
	) as Camera2D
	_operator = get_node_or_null(
		"/root/GameRoot/World/Operator"
	) as Node2D
	_route_manager = get_node_or_null(
		"/root/GameRoot/World/RouteTraversalManager"
	)
	if _approach != null:
		_controller = _approach.get_node_or_null("VistaController")
		_director = _approach.get_node_or_null("RevealDirector")


func _refresh_readout() -> void:
	if _label == null:
		return
	var route_id := _call_string(
		_route_manager,
		"get_current_route_id"
	)
	var profile_id := _call_string(
		_route_manager,
		"get_current_profile_id"
	)
	var current_node := _call_string(
		_route_manager,
		"get_current_node_id"
	)
	var choreography := _call_dictionary(
		_controller,
		"get_reveal_choreography_state"
	)
	var reveal := _call_dictionary(
		_director,
		"get_reveal_state"
	)
	var follow_target := _camera.get(
		"follow_target"
	) as Node if _camera != null else null
	var camera_position := (
		_camera.global_position
		if _camera != null else Vector2.ZERO
	)
	var operator_position := (
		_operator.global_position
		if _operator != null else Vector2.ZERO
	)
	var camera_distance := camera_position.distance_to(
		operator_position
	)
	var runtime_map: Variant = (
		_camera.call("get_runtime_map")
		if _camera != null
		and _camera.has_method("get_runtime_map")
		else null
	)
	var presentation_active := (
		bool(_camera.call("has_presentation_framing"))
		if _camera != null
		and _camera.has_method("has_presentation_framing")
		else false
	)
	var rows: Array[String] = [
		"VISTA LIVE PROBE",
		"route=%s profile=%s node=%s"
		% [route_id, profile_id, current_node],
		"phase=%s presentation=%s follow=%s map=%s"
		% [
			String(choreography.get("phase", "unknown")),
			str(presentation_active),
			follow_target.name if follow_target != null else "none",
			(runtime_map as Node).name if runtime_map is Node else "none",
		],
		"camera=%s operator=%s distance=%.1f zoom=%s"
		% [
			str(camera_position.round()),
			str(operator_position.round()),
			camera_distance,
			str(_camera.zoom if _camera != null else Vector2.ZERO),
		],
		"handoff_contract=%s"
		% _get_handoff_contract_state(
			follow_target,
			runtime_map,
			presentation_active,
			camera_distance,
			operator_position
		),
		"alpha vista=%.2f grand=%.2f reveal=%.2f foreground=%.2f"
		% [
			_alpha_at("VistaRoot"),
			_alpha_at("GrandVistaRoot"),
			_alpha_at("ParallaxRoot/RevealDepth"),
			_alpha_at("ParallaxRoot/ForegroundDepth"),
		],
		"first played=%s running=%s complete=%s"
		% [
			str(reveal.get("played", false)),
			str(reveal.get("running", false)),
			str(reveal.get("complete", false)),
		],
		"first progress=%.2f ready_return=%s return_running=%s"
		% [
			float(choreography.get("first_progress_weight", 0.0)),
			str(reveal.get("ready_for_return", false)),
			str(reveal.get("return_running", false)),
		],
		"second played=%s running=%s complete=%s"
		% [
			str(reveal.get("second_played", false)),
			str(reveal.get("second_running", false)),
			str(reveal.get("second_complete", false)),
		],
	]
	_label.text = "\n".join(rows)
	_label.modulate = (
		Color(1.0, 0.62, 0.54, 1.0)
		if not profile_id.is_empty()
		and profile_id != "production"
		else Color.WHITE
	)
	_update_phase_banner(choreography, reveal)


func _update_phase_banner(
	choreography: Dictionary,
	reveal: Dictionary
) -> void:
	if _phase_banner == null:
		return
	_phase_banner.position.x = maxf(
		0.0,
		(
			get_viewport().get_visible_rect().size.x
			- _phase_banner.size.x
		) * 0.5
	)
	var phase := String(choreography.get("phase", "UNKNOWN"))
	var banner_text := phase
	var banner_color := Color(0.82, 0.90, 1.0, 1.0)
	match phase:
		"INTRO_TIGHT":
			banner_text = "FIRST REVEAL ARMED — ENTER CYAN TRIGGER"
			banner_color = FIRST_COLOR
		"FIRST_REVEAL":
			banner_text = "FIRST REVEAL — BLEND %d%%" % roundi(
				float(choreography.get("weight", 0.0)) * 100.0
			)
			banner_color = FIRST_COLOR
		"FIRST_REVEAL_HOLD":
			banner_text = "FIRST REVEAL — HOLD"
			banner_color = FIRST_COLOR
		"FIRST_PROGRESS_CONTROL":
			banner_text = (
				"FIRST REVEAL — ROUTE CONTROL %d%%"
				% roundi(
					float(
						choreography.get(
							"first_progress_weight",
							0.0
						)
					) * 100.0
				)
			)
			banner_color = CONTROL_COLOR
		"RETURNING_TO_PLAY":
			banner_text = "FIRST REVEAL — RETURN %d%%" % roundi(
				float(choreography.get("return_weight", 0.0))
				* 100.0
			)
			banner_color = FIRST_COLOR
		"GAMEPLAY":
			if bool(reveal.get("second_complete", false)):
				banner_text = "VISTA REVEALS COMPLETE"
			else:
				banner_text = (
					"SECOND REVEAL ARMED — ENTER MAGENTA TRIGGER"
				)
				banner_color = SECOND_COLOR
		"SECOND_REVEAL":
			banner_text = "SECOND REVEAL — BLEND %d%%" % roundi(
				float(
					choreography.get(
						"second_reveal_weight",
						0.0
					)
				) * 100.0
			)
			banner_color = SECOND_COLOR
		"SECOND_REVEAL_HOLD":
			banner_text = "SECOND REVEAL — HOLD"
			banner_color = SECOND_COLOR
		"SECOND_RETURNING_TO_PLAY":
			banner_text = "SECOND REVEAL — RETURN %d%%" % roundi(
				float(
					choreography.get(
						"second_return_weight",
						0.0
					)
				) * 100.0
			)
			banner_color = SECOND_COLOR
	_phase_banner.text = banner_text
	_phase_banner.add_theme_color_override(
		"font_color",
		banner_color
	)
	if phase != _last_phase:
		print(
			"[SunderedKeepVistaProbe] phase=%s first=%s second=%s"
			% [
				phase,
				str(reveal.get("complete", false)),
				str(reveal.get("second_complete", false)),
			]
		)
		_last_phase = phase


func _update_transition_indicators() -> void:
	if _approach == null:
		return
	var canvas_transform := get_viewport().get_canvas_transform()
	for path: String in _world_indicators:
		var entry := _world_indicators[path] as Dictionary
		var control := entry.get("control") as ColorRect
		var target := _approach.get_node_or_null(path) as Node2D
		if control == null or target == null:
			if control != null:
				control.visible = false
			continue
		control.visible = true
		var screen_position := canvas_transform * target.global_position
		var is_trigger := bool(entry.get("is_trigger", false))
		var size := Vector2(16.0, 16.0)
		var occupied := false
		if is_trigger and target is Area2D:
			var trigger := target as Area2D
			occupied = trigger.has_overlapping_bodies()
			var shape_node := trigger.get_node_or_null(
				"CollisionShape2D"
			) as CollisionShape2D
			if shape_node != null \
					and shape_node.shape is RectangleShape2D:
				var world_size := (
					shape_node.shape as RectangleShape2D
				).size
				size = Vector2(
					canvas_transform.x.length() * world_size.x,
					canvas_transform.y.length() * world_size.y
				)
		control.size = size
		control.position = screen_position - size * 0.5
		var color := entry.get("color", Color.WHITE) as Color
		control.color = Color(
			color.r,
			color.g,
			color.b,
			0.42 if occupied else 0.16
		)
		var label := control.get_node_or_null("Label") as Label
		if label != null:
			label.text = _indicator_label(path, occupied)
	_update_target_line(canvas_transform)


func _indicator_label(path: String, occupied: bool) -> String:
	var prefix := ""
	if path == FIRST_TRIGGER_PATH:
		prefix = "FIRST REVEAL TRIGGER"
	elif path == RETURN_TRIGGER_PATH:
		prefix = "RETURN TO GAMEPLAY"
	elif path == SECOND_TRIGGER_PATH:
		prefix = "SECOND REVEAL TRIGGER"
	elif path == FIRST_ANCHOR_PATH:
		prefix = "FIRST CAMERA ANCHOR"
	elif path == CONTROL_START_PATH:
		prefix = "REVEAL CONTROL START"
	elif path == CONTROL_END_PATH:
		prefix = "REVEAL CONTROL END"
	else:
		prefix = "SECOND CAMERA ANCHOR"
	return prefix + (" [OCCUPIED]" if occupied else "")


func _update_target_line(canvas_transform: Transform2D) -> void:
	if _target_line == null or _operator == null:
		return
	var reveal := _call_dictionary(_director, "get_reveal_state")
	var target_path := ""
	var color := FIRST_COLOR
	if not bool(reveal.get("played", false)):
		target_path = FIRST_TRIGGER_PATH
	elif not bool(reveal.get("complete", false)):
		target_path = RETURN_TRIGGER_PATH
		color = RETURN_COLOR
	elif not bool(reveal.get("second_played", false)):
		target_path = SECOND_TRIGGER_PATH
		color = SECOND_COLOR
	var target := _approach.get_node_or_null(target_path) as Node2D
	if target == null:
		_target_line.clear_points()
		return
	_target_line.default_color = color
	_target_line.points = PackedVector2Array([
		canvas_transform * _operator.global_position,
		canvas_transform * target.global_position,
	])


func _get_handoff_contract_state(
	follow_target: Node,
	runtime_map: Variant,
	presentation_active: bool,
	camera_distance: float,
	operator_position: Vector2
) -> String:
	if presentation_active:
		return "PRESENTATION_ACTIVE"
	var failures: Array[String] = []
	if runtime_map != _approach:
		failures.append("runtime_map")
	if follow_target != _operator:
		failures.append("follow_target")
	if camera_distance >= 96.0:
		failures.append("camera_distance")
	if _approach != null \
			and _approach.has_method("get_camera_bounds"):
		var bounds: Variant = _approach.call("get_camera_bounds")
		if bounds is Rect2 \
				and not (bounds as Rect2).has_point(
					operator_position
				):
			failures.append("operator_out_of_bounds")
	return "PASS" if failures.is_empty() else "FAIL " + ",".join(failures)


func _print_route_identity() -> void:
	print(
		"[SunderedKeepVistaProbe] route_id=%s profile_id=%s current_node=%s"
		% [
			_call_string(_route_manager, "get_current_route_id"),
			_call_string(_route_manager, "get_current_profile_id"),
			_call_string(_route_manager, "get_current_node_id"),
		]
	)


func _alpha_at(path: String) -> float:
	if _approach == null:
		return -1.0
	var item := _approach.get_node_or_null(path) as CanvasItem
	return item.modulate.a if item != null else -1.0


func _call_string(target: Node, method_name: String) -> String:
	if target == null or not target.has_method(method_name):
		return ""
	return String(target.call(method_name))


func _call_dictionary(
	target: Node,
	method_name: String
) -> Dictionary:
	if target == null or not target.has_method(method_name):
		return {}
	var result: Variant = target.call(method_name)
	return result as Dictionary if result is Dictionary else {}
