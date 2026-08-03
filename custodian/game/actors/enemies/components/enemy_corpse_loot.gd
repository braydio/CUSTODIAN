class_name EnemyCorpseLoot
extends Area2D

signal loot_collected(payload: Dictionary)

const MARKER_SCENE := preload("res://game/vfx/loot/loot_corpse_marker.tscn")
const CORPSE_HUE_SHADER := preload("res://game/vfx/loot/loot_corpse_hue.gdshader")
const PICKUP_SOUND := preload("res://content/audio/sfx/items/pickup_collect_01.wav")

@export var pickup_radius_px := 22.0
@export var marker_offset := Vector2(0.0, -8.0)

var _payload: Dictionary = {}
var _collected := false
var _marker: LootCorpseMarker = null
var _visual_materials: Dictionary = {}
var _visual_modulates: Dictionary = {}


func _ready() -> void:
	monitoring = false
	monitorable = false
	var shape := CollisionShape2D.new()
	shape.name = "CollectionShape"
	var circle := CircleShape2D.new()
	circle.radius = pickup_radius_px
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func activate(payload: Dictionary, visual_owner: CanvasItem) -> void:
	_payload = _clean_structured_payload(payload)
	_collected = false
	if _payload_is_empty(_payload):
		_payload.clear()
		monitoring = false
		return
	_apply_hue(visual_owner, _category_for_payload())
	_marker = MARKER_SCENE.instantiate() as LootCorpseMarker
	if _marker != null:
		_marker.position = marker_offset
		_marker.z_as_relative = true
		_marker.z_index = 0
		add_child(_marker)
		_marker.activate({"category": _category_for_payload()})
	monitorable = true
	monitoring = true


func collect(collector: Node) -> bool:
	if _collected or not has_loot() or not _is_valid_collector(collector):
		return false
	_collected = true
	# Collection commonly runs inside Area2D.body_entered. Godot blocks direct
	# monitoring/monitorable changes while flushing an in/out signal, so defer
	# only the physics-server flags. `_collected` closes the reward boundary
	# immediately and keeps same-frame overlaps from awarding twice.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var awarded := _payload.duplicate(true)
	_payload.clear()
	_award_payload(awarded)
	_restore_hue()
	_play_pickup_sound()
	loot_collected.emit(awarded.duplicate(true))
	if _marker != null and is_instance_valid(_marker):
		_marker.collect()
	return true


func has_loot() -> bool:
	return not _collected and not _payload_is_empty(_payload)


func get_payload_snapshot() -> Dictionary:
	return _payload.duplicate(true)


func get_debug_snapshot() -> Dictionary:
	return {
		"has_loot": has_loot(),
		"collected": _collected,
		"monitoring": monitoring,
		"payload": get_payload_snapshot(),
		"marker_active": _marker != null and is_instance_valid(_marker),
	}


func _on_body_entered(body: Node) -> void:
	collect(body)


func _is_valid_collector(collector: Node) -> bool:
	return collector != null and (
		collector.is_in_group("player")
		or collector.is_in_group("operator")
		or collector.name == &"Player"
		or collector.name == &"Operator"
	)


func _award_payload(payload: Dictionary) -> void:
	var root := get_tree().root
	var ledger := root.get_node_or_null("ResourceLedger")
	for resource_id in (payload.get("resource_ledger", {}) as Dictionary).keys():
		var amount := int((payload["resource_ledger"] as Dictionary)[resource_id])
		if amount > 0 and ledger != null and ledger.has_method("add"):
			ledger.call("add", String(resource_id), amount)
	var recovered := payload.get("vault_recovery", {}) as Dictionary
	var vault := root.get_node_or_null("VaultManager")
	if not recovered.is_empty() and vault != null and vault.has_method("recover_resources"):
		vault.call("recover_resources", recovered.duplicate(true))
	var materials := int(payload.get("legacy_materials", 0))
	var game_state := root.get_node_or_null("GameState")
	if materials > 0 and game_state != null and game_state.has_method("add_materials"):
		game_state.call("add_materials", materials)


func _clean_structured_payload(payload: Dictionary) -> Dictionary:
	return {
		"resource_ledger": _clean_amounts(payload.get("resource_ledger", {})),
		"vault_recovery": _clean_amounts(payload.get("vault_recovery", {})),
		"legacy_materials": max(0, int(payload.get("legacy_materials", 0))),
		"items": (payload.get("items", []) as Array).duplicate(true),
	}


func _clean_amounts(value: Variant) -> Dictionary:
	var cleaned := {}
	if not (value is Dictionary):
		return cleaned
	for key in (value as Dictionary).keys():
		var amount := int((value as Dictionary)[key])
		if amount > 0:
			cleaned[StringName(str(key))] = amount
	return cleaned


func _payload_is_empty(payload: Dictionary) -> bool:
	return (payload.get("resource_ledger", {}) as Dictionary).is_empty() \
		and (payload.get("vault_recovery", {}) as Dictionary).is_empty() \
		and int(payload.get("legacy_materials", 0)) <= 0 \
		and (payload.get("items", []) as Array).is_empty()


func _category_for_payload() -> StringName:
	var resources := _payload.get("resource_ledger", {}) as Dictionary
	if resources.has(&"memory_glass_fragment") or resources.has(&"white_thread_knot"):
		return &"anomaly"
	if resources.has(&"frayed_signal_filament"):
		return &"signal"
	if resources.has(&"power_components") or resources.has(&"spent_charge_cell"):
		return &"power"
	return &"common_salvage"


func _apply_hue(visual_owner: CanvasItem, category: StringName) -> void:
	if visual_owner == null:
		return
	var color := Color(1.0, 0.82, 0.46, 1.0)
	match category:
		&"power": color = Color(0.64, 0.92, 1.0, 1.0)
		&"signal": color = Color(0.78, 0.65, 1.0, 1.0)
		&"anomaly": color = Color(0.88, 0.96, 1.0, 1.0)
	for item in _collect_canvas_items(visual_owner):
		_visual_materials[item.get_instance_id()] = [item, item.material]
		_visual_modulates[item.get_instance_id()] = [item, item.modulate]
		var material := ShaderMaterial.new()
		material.shader = CORPSE_HUE_SHADER
		material.set_shader_parameter("hue_color", color)
		material.set_shader_parameter("mix_strength", 0.15)
		material.set_shader_parameter("pulse_strength", 0.08)
		item.material = material


func _collect_canvas_items(root_item: CanvasItem) -> Array[CanvasItem]:
	var result: Array[CanvasItem] = [root_item]
	for child in root_item.get_children():
		if child is CanvasItem:
			result.append_array(_collect_canvas_items(child as CanvasItem))
	return result


func _restore_hue() -> void:
	for record in _visual_materials.values():
		var item := record[0] as CanvasItem
		if is_instance_valid(item):
			item.material = record[1]
	for record in _visual_modulates.values():
		var item := record[0] as CanvasItem
		if is_instance_valid(item):
			item.modulate = record[1]
	_visual_materials.clear()
	_visual_modulates.clear()


func _play_pickup_sound() -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = PICKUP_SOUND
	player.max_distance = 420.0
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	if parent == null:
		player.free()
		return
	parent.add_child(player)
	player.global_position = global_position
	player.finished.connect(player.queue_free)
	player.play()
