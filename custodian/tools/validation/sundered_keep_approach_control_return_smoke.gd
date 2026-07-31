extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/"
	+ "sundered_keep_approach.tscn"
)


class TestCamera:
	extends Camera2D

	var follow_target: Node2D = null
	var runtime_map: Node = null
	var presentation_framing := true
	var target_zoom := Vector2.ONE

	func set_runtime_map(value: Node) -> void:
		runtime_map = value
		clear_presentation_framing(true)

	func get_runtime_map() -> Node:
		return runtime_map

	func set_follow_target(value: Node2D) -> void:
		follow_target = value

	func clear_presentation_framing(
		restore_operator_follow := true
	) -> void:
		presentation_framing = false
		if restore_operator_follow:
			follow_target = get_node_or_null(
				"/root/GameRoot/World/Operator"
			) as Node2D

	func set_presentation_framing(
		active: bool,
		_offset := Vector2.ZERO,
		zoom_value := Vector2.ONE
	) -> void:
		presentation_framing = active
		target_zoom = zoom_value

	func has_presentation_framing() -> bool:
		return presentation_framing

	func snap_to_player_spawn(world_position: Vector2) -> void:
		global_position = world_position


class TestUI:
	extends CanvasLayer

	var mode: StringName = &"gameplay"

	func set_world_presentation_mode(value: StringName) -> void:
		mode = value

	func get_world_presentation_mode() -> StringName:
		return mode


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var ui := TestUI.new()
	ui.name = "UI"
	game_root.add_child(ui)
	var actor := CharacterBody2D.new()
	actor.name = "Operator"
	actor.add_to_group("operator")
	world.add_child(actor)
	var camera := TestCamera.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var approach := APPROACH_SCENE.instantiate()
	approach.name = "SunderedKeepApproach"
	world.add_child(approach)
	await process_frame
	await process_frame

	actor.global_position = approach.call("get_entry_position")
	var completed := bool(approach.call(
		"complete_route_activation",
		{}
	))
	var camera_bound := bool(approach.call(
		"refresh_route_camera",
		actor
	))
	await process_frame
	var route_master := approach.get_node_or_null(
		"PlayableRoot/ApproachRouteMaster"
	) as Sprite2D
	var second_trigger := approach.get_node_or_null(
		"SequenceTriggers/SecondVistaRevealTrigger"
	)
	_check(completed, "approach rejected route activation", errors)
	_check(
		bool(approach.call("is_visual_ready")),
		"approach visual readiness never completed",
		errors
	)
	_check(camera_bound, "approach rejected camera binding", errors)
	_check(
		camera.get_runtime_map() == approach,
		"camera runtime map is not the approach",
		errors
	)
	_check(
		camera.follow_target == actor,
		"camera does not follow the Operator",
		errors
	)
	_check(
		not camera.has_presentation_framing(),
		"camera retained presentation framing at control return",
		errors
	)
	_check(
		route_master != null and route_master.visible,
		"route master is not visible",
		errors
	)
	_check(
		route_master != null and route_master.modulate.a > 0.8,
		"route master effective alpha is too low",
		errors
	)
	_check(
		route_master != null
		and _sample_sprite_alpha_at_world(
			route_master,
			actor.global_position
		) > 0.10,
		"Operator EntrySpawn is not over a visible route pixel",
		errors
	)
	_check(
		approach.get_node_or_null(
			"Collision/PathBoundaryCollision"
		) != null,
		"authored collision is unavailable",
		errors
	)
	_check(
		second_trigger != null,
		"near-vista trigger is unavailable from the authored route",
		errors
	)
	_check(
		ui.mode == &"vista_approach",
		"procgen gameplay HUD was not relinquished",
		errors
	)
	_finish(errors)


func _sample_sprite_alpha_at_world(
	sprite: Sprite2D,
	world_position: Vector2
) -> float:
	if sprite.texture == null:
		return 0.0
	var image := sprite.texture.get_image()
	if image == null or image.is_empty():
		return 0.0
	var local_position := sprite.to_local(world_position)
	var texture_size := Vector2(image.get_size())
	var pixel_position := local_position
	if sprite.centered:
		pixel_position += texture_size * 0.5
	var pixel := Vector2i(pixel_position.floor())
	if (
		pixel.x < 0
		or pixel.y < 0
		or pixel.x >= image.get_width()
		or pixel.y >= image.get_height()
	):
		return 0.0
	return image.get_pixelv(pixel).a


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[SunderedKeepApproachControlReturnSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepApproachControlReturnSmoke] %s" % error)
	quit(1)
