extends Node

@export var enabled: bool = true
@export var encounter_scene: PackedScene
@export var operator_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var spawn_parent_path: NodePath = NodePath("/root/GameRoot/World")
@export var contract_loader_path: NodePath = NodePath("/root/GameRoot/ContractWorldLoader")
@export var spawn_offset: Vector2 = Vector2(0.0, -720.0)
@export var spawn_delay_seconds: float = 0.0
@export var wait_for_runtime_map: bool = true
@export var max_wait_frames: int = 240
@export var reserve_procgen_authority: bool = true
@export var encounter_size_tiles: Vector2i = Vector2i(35, 27)
@export var encounter_reservation_margin_tiles: int = 1
@export var encounter_region_type: String = "ash_bell_forlorn_ritualant_room"
@export var encounter_region_zone: String = "special_room"

var _spawned: Node2D = null


func _ready() -> void:
	if not enabled:
		return
	call_deferred("_spawn_after_world_ready")


func _spawn_after_world_ready() -> void:
	if spawn_delay_seconds > 0.0:
		await get_tree().create_timer(spawn_delay_seconds).timeout
	await _wait_for_live_world()

	if _spawned != null and is_instance_valid(_spawned):
		return

	var parent := get_node_or_null(spawn_parent_path)
	var operator := get_node_or_null(operator_path) as Node2D
	if parent == null or operator == null or encounter_scene == null:
		push_warning("[AshBellDevSpawner] Missing parent, operator, or encounter_scene.")
		return

	var instance := encounter_scene.instantiate() as Node2D
	if instance == null:
		push_warning("[AshBellDevSpawner] Encounter scene did not instantiate as Node2D.")
		return

	var target_position := operator.global_position + spawn_offset
	if reserve_procgen_authority:
		_reserve_procgen_authority_for_encounter(target_position)

	parent.add_child(instance)
	instance.global_position = target_position
	_spawned = instance
	print("[AshBellDevSpawner] Spawned Ash-Bell encounter at ", instance.global_position)


func _wait_for_live_world() -> void:
	for _frame_index in range(max(1, max_wait_frames)):
		var operator := get_node_or_null(operator_path) as Node2D
		if operator == null:
			await get_tree().process_frame
			continue
		if not wait_for_runtime_map:
			return
		var loader := get_node_or_null(contract_loader_path)
		if loader != null and loader.has_method("get_active_map_instance"):
			var active_map = loader.call("get_active_map_instance")
			if active_map != null:
				return
		await get_tree().process_frame


func _reserve_procgen_authority_for_encounter(global_center: Vector2) -> void:
	var loader := get_node_or_null(contract_loader_path)
	if loader == null or not loader.has_method("get_active_map_instance"):
		push_warning("[AshBellDevSpawner] Cannot reserve procgen authority: active map loader unavailable.")
		return
	var active_map = loader.call("get_active_map_instance")
	if active_map == null:
		push_warning("[AshBellDevSpawner] Cannot reserve procgen authority: active map unavailable.")
		return
	if not active_map.has_method("claim_procgen_floor_rect_for_authored_scene_world"):
		push_warning("[AshBellDevSpawner] Active map does not support authored scene authority reservation.")
		return
	active_map.call(
		"claim_procgen_floor_rect_for_authored_scene_world",
		global_center,
		encounter_size_tiles,
		encounter_region_type,
		encounter_region_zone,
		encounter_reservation_margin_tiles
	)
