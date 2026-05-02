extends Node

@export var cognitive_pickup_scene: PackedScene

const FAINT_RECOLLECTION := &"faint_recollection"
const RESIDUAL_INSTINCT := &"residual_instinct"
const ANCIENT_BEARING := &"ancient_bearing"

const BASE_FAINT_CHANCE := 0.65
const BASE_INSTINCT_CHANCE := 0.22
const BASE_BEARING_CHANCE := 0.05
const MAX_BEARING_CHANCE := 0.08


func spawn_drop(drop_position: Vector2, drop_parent: Node = null) -> Node:
	if cognitive_pickup_scene == null:
		return null
	var drop := _roll_drop()
	var item_id: StringName = drop.get("item_id", &"")
	var quantity: int = int(drop.get("quantity", 0))
	if item_id == &"" or quantity <= 0:
		return null

	var pickup := cognitive_pickup_scene.instantiate()
	if pickup == null:
		return null
	if pickup.has_method("set_item"):
		pickup.call("set_item", item_id, quantity)
	else:
		pickup.set("item_id", item_id)
		pickup.set("quantity", quantity)

	var parent := drop_parent
	if parent == null:
		parent = get_parent().get_parent() if get_parent() != null else get_tree().current_scene
	parent.add_child(pickup)
	if pickup is Node2D:
		(pickup as Node2D).global_position = drop_position
	return pickup


func _roll_drop() -> Dictionary:
	var drop_rate_multiplier := 1.0
	var rare_multiplier := 1.0
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null:
		if cognitive.has_method("get_drop_rate_multiplier"):
			drop_rate_multiplier = max(0.0, float(cognitive.call("get_drop_rate_multiplier")))
		if cognitive.has_method("get_rare_drop_multiplier"):
			rare_multiplier = max(0.0, float(cognitive.call("get_rare_drop_multiplier")))

	var bearing_chance: float = min(BASE_BEARING_CHANCE * rare_multiplier, MAX_BEARING_CHANCE)
	var faint_chance: float = BASE_FAINT_CHANCE * drop_rate_multiplier
	var instinct_chance: float = BASE_INSTINCT_CHANCE * drop_rate_multiplier
	var total_item_chance: float = min(1.0, faint_chance + instinct_chance + bearing_chance)
	if total_item_chance <= 0.0:
		return {}

	var scale: float = total_item_chance / max(0.001, faint_chance + instinct_chance + bearing_chance)
	faint_chance *= scale
	instinct_chance *= scale
	bearing_chance *= scale

	var roll := randf()
	if roll < faint_chance:
		return {"item_id": FAINT_RECOLLECTION, "quantity": 1}
	roll -= faint_chance
	if roll < instinct_chance:
		return {"item_id": RESIDUAL_INSTINCT, "quantity": 1}
	roll -= instinct_chance
	if roll < bearing_chance:
		return {"item_id": ANCIENT_BEARING, "quantity": 1}
	return {}
