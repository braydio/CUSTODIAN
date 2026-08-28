extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const SOCKET_LIBRARY := preload(
	"res://game/actors/operator/animations/operator_weapon_socket_library.gd"
)
const CATALOG_FRAMES := preload(
	"res://game/actors/operator/operator_animation_catalog_frames.tres"
)

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var library := SOCKET_LIBRARY.new()
	_expect(library.load_generated(), "generated weapon socket data did not load")
	for suffix in ["e", "w"]:
		var track := StringName(
			"melee_1h/locomotion/run_01/%s/upper_body" % suffix
		)
		for layer in ["lower_body", "upper_body"]:
			var body_animation := StringName(
				"melee_1h/locomotion/run_01/%s/%s" % [suffix, layer]
			)
			_expect(
				CATALOG_FRAMES.get_frame_count(body_animation) == 6,
				"%s must remain the six-frame body clock" % body_animation
			)
		var errors := library.validate_track(track, 6, [&"grip"])
		_expect(errors.is_empty(), "%s coverage failed: %s" % [track, errors])
		var midpoint_a := library.get_interpolated_socket(track, 1, 0.5)
		var midpoint_b := library.get_interpolated_socket(track, 1, 0.5)
		_expect(midpoint_a == midpoint_b, "%s interpolation was not deterministic" % track)
		var loop_socket := library.get_interpolated_socket(track, 5, 0.5)
		_expect(int(loop_socket.get("next_frame", -1)) == 0, "%s did not wrap 5 -> 0" % track)

	var angle_source := """
{"tracks":{"angle_test":[
{"grip":[0,0],"weapon_angle_deg":350,"weapon_z":3},
{"grip":[0,0],"weapon_angle_deg":10,"weapon_z":3}
]}}
"""
	var angle_library := SOCKET_LIBRARY.new()
	var angle_path := "user://operator_melee_locomotion_angle_test.json"
	var angle_file := FileAccess.open(angle_path, FileAccess.WRITE)
	angle_file.store_string(angle_source)
	angle_file.close()
	_expect(angle_library.load_generated(angle_path), "angle fixture did not load")
	var angle_mid := angle_library.get_interpolated_socket(&"angle_test", 0, 0.5)
	var angle_deg := fposmod(float(angle_mid.weapon_angle_deg), 360.0)
	_expect(angle_deg < 0.01 or angle_deg > 359.99, "angle interpolation did not take shortest path")

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set("combat_loadout_mode", &"melee")
	operator.set("using_unarmed", false)
	operator.set("primary_weapon_equipped", true)
	var vigil_definition = operator.get("melee_weapon_definition")
	operator.call("_apply_melee_weapon_animation_resources", vigil_definition)
	var vigil_index := (operator.get("armed_weapons") as Array).find(vigil_definition)
	_expect(vigil_index >= 0, "Vigil definition missing from weapon selection")
	operator.call("_apply_armed_selection", vigil_index)

	var lower := operator.get_node("ModularLowerBodySprite") as AnimatedSprite2D
	var overlay := operator.get_node("MeleeWeaponOverlaySprite") as AnimatedSprite2D
	_expect(overlay.centered, "socketed weapon must rotate around centered 48,48 grip")
	_expect(overlay.offset == Vector2.ZERO, "weapon overlay has a second pivot offset")
	_expect(
		operator.call("_sync_modular_melee_locomotion", "unarmed_run", Vector2.RIGHT, 1.0),
		"Vigil east run did not resolve"
	)
	lower.set_frame_and_progress(1, 0.5)
	operator.call("_sync_modular_melee_locomotion", "unarmed_run", Vector2.RIGHT, 1.0)
	var snapshot := operator.call("get_melee_locomotion_socket_snapshot") as Dictionary
	_expect(bool(snapshot.active), "Vigil run did not activate socket presentation")
	_expect(not bool(snapshot.weapon_playing), "socketed weapon introduced an independent animation clock")
	_expect(overlay.visible, "socketed Vigil weapon is not visible")
	_expect(not overlay.is_playing(), "authored locomotion strip still plays during socket mode")
	var expected := library.get_interpolated_socket(
		&"melee_1h/locomotion/run_01/e/upper_body",
		1,
		0.5
	)
	_expect(
		(overlay.position - Vector2(0, -18)).distance_to(expected.grip as Vector2) < 0.01,
		"weapon position did not use interpolated hand grip"
	)

	operator.call("_sync_modular_melee_posture", Vector2.RIGHT)
	snapshot = operator.call("get_melee_locomotion_socket_snapshot") as Dictionary
	_expect(not bool(snapshot.active), "leaving run retained socket mode")
	_expect(overlay.rotation == 0.0 and overlay.z_index == 0, "posture retained stale socket transform")

	operator.call("_sync_modular_melee_locomotion", "unarmed_run", Vector2.LEFT, 1.0)
	_expect(
		bool((operator.call("get_melee_locomotion_socket_snapshot") as Dictionary).active),
		"Vigil west run did not resolve"
	)
	operator.set("_weapon_socket_library", SOCKET_LIBRARY.new())
	_expect(
		operator.call("_sync_modular_melee_locomotion", "unarmed_run", Vector2.LEFT, 1.0),
		"missing socket metadata did not retain authored-strip fallback"
	)
	snapshot = operator.call("get_melee_locomotion_socket_snapshot") as Dictionary
	_expect(not bool(snapshot.active), "weapon switch/missing metadata retained stale socket mode")
	_expect(overlay.is_playing(), "authored-strip fallback was not restored")

	var operator_source := FileAccess.get_file_as_string(
		"res://game/actors/operator/operator.gd"
	)
	_expect(
		not operator_source.contains("_melee_locomotion_socket_timer"),
		"independent melee weapon timer was introduced"
	)
	operator.free()
	if _failures.is_empty():
		print("operator_melee_locomotion_socket_smoke: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
