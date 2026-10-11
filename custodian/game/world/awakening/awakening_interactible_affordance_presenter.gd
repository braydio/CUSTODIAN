extends Node
class_name AwakeningInteractibleAffordancePresenter

## Visual-only bindings between authored Layout markers and existing gameplay
## owners. Asset family/state contracts are descriptive until approved art is
## available; no gameplay owner or input/collision surface is created here.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")

const MOUNT_DESCRIPTORS: Array[Dictionary] = [
	{
		"id": &"creche_console",
		"zone_id": &"zone01_creche",
		"marker_id": &"creche_console",
		"owner_path": NodePath("World/AwakeningZones/Zone01_Creche/Interactables/CrecheConsole"),
		"families": [&"awakening_interact_support", &"awakening_interact_terminal", &"awakening_interact_shared_fx"],
		"world_offset": Vector2.ZERO,
		"art_parts": {"long": [], "mid": [], "near": []},
	},
	{
		"id": &"p9_locker",
		"zone_id": &"zone04_locker_reliquary",
		"marker_id": &"p9_locker",
		"owner_path": NodePath("World/AwakeningZones/Zone04_LockerReliquary/SidearmLocker"),
		"families": [&"awakening_interact_support", &"awakening_interact_locker", &"awakening_interact_shared_fx"],
		"world_offset": Vector2.ZERO,
		"art_parts": {"long": [], "mid": [], "near": []},
	},
	{
		"id": &"lift_lower",
		"zone_id": &"zone05_dust_lung",
		"marker_id": &"lift_lower",
		"owner_path": NodePath("World/AwakeningZones/Zone05_DustLung/Interactables/TransitLift"),
		"families": [&"awakening_interact_support", &"awakening_interact_lift", &"awakening_interact_shared_fx"],
		"world_offset": Vector2.ZERO,
		"art_parts": {"long": [], "mid": [], "near": []},
	},
	{
		"id": &"lift_upper",
		"zone_id": &"zone05_dust_lung",
		"marker_id": &"lift_upper",
		"owner_path": NodePath("World/AwakeningZones/Zone05_DustLung/Interactables/TransitLift"),
		"families": [&"awakening_interact_support", &"awakening_interact_lift", &"awakening_interact_shared_fx"],
		"world_offset": Vector2.ZERO,
		"art_parts": {"long": [], "mid": [], "near": []},
	},
	{
		"id": &"port_status_plaque",
		"zone_id": &"zone06_undergate",
		"marker_id": &"port_status_plaque",
		"owner_path": NodePath("World/AwakeningZones/Zone06_Undergate/Interactables/PortStatusPlaque"),
		"families": [&"awakening_interact_support", &"awakening_interact_terminal", &"awakening_interact_port", &"awakening_interact_shared_fx"],
		"world_offset": Vector2.ZERO,
		"art_parts": {"long": [], "mid": [], "near": []},
	},
]

const LAYERS := [&"long", &"mid", &"near"]
const LAYER_NODES := {
	&"long": "LongRangeSilhouette",
	&"mid": "MidRangeDressing",
	&"near": "NearRangeFocusStatus",
}

var _bound := false
var _awakening_root: Node = null
var _mounts_by_id: Dictionary = {}
var _mounts_by_marker: Dictionary = {}
var _mount_ids_by_owner: Dictionary = {}
var _owners_by_id: Dictionary = {}
var _focused_mount_id: StringName = &""


func bind(awakening_root: Node) -> bool:
	if _bound or awakening_root == null:
		return _bound
	_awakening_root = awakening_root
	var wired_owners: Dictionary = {}
	for descriptor in MOUNT_DESCRIPTORS:
		var zone: Dictionary = Layout.zone_by_id(StringName(descriptor["zone_id"]))
		var marker := _find_marker(StringName(descriptor["zone_id"]), StringName(descriptor["marker_id"]))
		if zone.is_empty() or marker.is_empty():
			return false
		var marker_position: Vector2 = marker.get("position", Vector2.ZERO)
		var set_pieces_path := NodePath("World/AwakeningZones/%s/SetPieces" % String(zone["node"]))
		var set_pieces := awakening_root.get_node_or_null(set_pieces_path) as Node2D
		var owner := awakening_root.get_node_or_null(descriptor["owner_path"])
		if set_pieces == null or owner == null or not owner.is_in_group("interactable"):
			return false
		var mount := Node2D.new()
		mount.name = "AffordanceMount_%s" % String(descriptor["id"])
		mount.position = marker_position + Vector2(descriptor["world_offset"])
		mount.set_meta("mount_id", descriptor["id"])
		mount.set_meta("zone_id", descriptor["zone_id"])
		mount.set_meta("marker_id", descriptor["marker_id"])
		mount.set_meta("gameplay_owner_path", descriptor["owner_path"])
		mount.set_meta("family_ids", descriptor["families"].duplicate())
		mount.set_meta("world_offset", descriptor["world_offset"])
		mount.set_meta("art_parts", descriptor["art_parts"].duplicate(true))
		mount.set_meta("presentation_status", _initial_status(owner))
		mount.set_meta("focused", false)
		mount.set_meta("near_indicator_active", false)
		for layer_id in LAYERS:
			var layer := Node2D.new()
			layer.name = LAYER_NODES[layer_id]
			layer.set_meta("layer_id", layer_id)
			mount.add_child(layer)
		set_pieces.add_child(mount)
		_mounts_by_id[descriptor["id"]] = mount
		_mounts_by_marker[_marker_key(StringName(descriptor["zone_id"]), StringName(descriptor["marker_id"]))] = mount
		var owner_id := owner.get_instance_id()
		if not _mount_ids_by_owner.has(owner_id):
			_mount_ids_by_owner[owner_id] = []
		_mount_ids_by_owner[owner_id].append(StringName(descriptor["id"]))
		_owners_by_id[owner_id] = owner
		if not wired_owners.has(owner_id):
			wired_owners[owner_id] = true
			_wire_owner_transitions(owner)
	_bound = true
	return true


func get_mount_for_marker(zone_id: StringName, marker_id: StringName) -> Node2D:
	return _mounts_by_marker.get(_marker_key(zone_id, marker_id)) as Node2D


func get_owner_for_mount(mount_id: StringName) -> Node:
	var mount := _mounts_by_id.get(mount_id) as Node2D
	if mount == null or _awakening_root == null:
		return null
	return _awakening_root.get_node_or_null(mount.get_meta("gameplay_owner_path"))


## Optional asset consumers resolve verified V2 resources and pass them here.
## A missing/null part is a normal source-pending state and emits no warning.
func attach_visual_part(
	mount_id: StringName,
	layer_id: StringName,
	part_id: StringName,
	family_id: StringName,
	state_id: StringName,
	texture: Texture2D,
	local_offset: Vector2 = Vector2.ZERO,
) -> bool:
	var mount := _mounts_by_id.get(mount_id) as Node2D
	var layer_name: String = LAYER_NODES.get(layer_id, "")
	var layer: Node2D = mount.get_node_or_null(NodePath(layer_name)) as Node2D if mount != null and not layer_name.is_empty() else null
	if mount == null or layer == null or texture == null:
		return false
	var sprite := Sprite2D.new()
	sprite.name = "Part_%s" % String(part_id)
	sprite.texture = texture
	sprite.position = local_offset
	sprite.z_index = 1 if layer_id == &"near" else 0
	sprite.set_meta("family_id", family_id)
	sprite.set_meta("state_id", state_id)
	layer.add_child(sprite)
	_sync_layer_visibility(mount)
	return true


## Called from the existing prompt refresh with its already-selected target. It
## checks only that owner and, for the shared lift owner, at most two stations.
func set_focus_target(target: Node) -> void:
	var next_mount_id: StringName = &""
	if target != null and is_instance_valid(target):
		var owner_mount_ids: Array = _mount_ids_by_owner.get(target.get_instance_id(), [])
		if owner_mount_ids.size() == 1:
			next_mount_id = StringName(owner_mount_ids[0])
		elif owner_mount_ids.size() > 1:
			var target_position := Vector2.ZERO
			if target.has_method("get_interaction_position"):
				target_position = target.call("get_interaction_position")
			var best_distance := INF
			for candidate_id in owner_mount_ids:
				var candidate := _mounts_by_id.get(candidate_id) as Node2D
				if candidate == null:
					continue
				var distance := candidate.global_position.distance_squared_to(target_position)
				if distance < best_distance:
					best_distance = distance
					next_mount_id = StringName(candidate_id)
	if next_mount_id == _focused_mount_id:
		return
	_set_mount_focused(_focused_mount_id, false)
	_focused_mount_id = next_mount_id
	_set_mount_focused(_focused_mount_id, true)


func set_owner_status(owner: Node, status: StringName) -> void:
	if owner == null or not is_instance_valid(owner) or not [&"available", &"disabled", &"used"].has(status):
		return
	var owner_id := owner.get_instance_id()
	for mount_id in _mount_ids_by_owner.get(owner_id, []):
		var mount := _mounts_by_id.get(mount_id) as Node2D
		if mount == null:
			continue
		mount.set_meta("presentation_status", status)
		_sync_layer_visibility(mount)


func diagnostic_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for descriptor in MOUNT_DESCRIPTORS:
		var mount_id := StringName(descriptor["id"])
		var mount := _mounts_by_id.get(mount_id) as Node2D
		var owner := get_owner_for_mount(mount_id)
		if mount == null:
			continue
		var part_count := 0
		var collision_count := _count_collision_nodes(mount)
		for layer_id in LAYERS:
			var layer := mount.get_node_or_null(NodePath(LAYER_NODES[layer_id]))
			if layer != null:
				part_count += layer.get_child_count()
		snapshot.append({
			"mount_id": mount_id,
			"zone_id": descriptor["zone_id"],
			"marker_id": descriptor["marker_id"],
			"owner_path": String(descriptor["owner_path"]),
			"owner_instance_id": owner.get_instance_id() if owner != null else 0,
			"family_ids": descriptor["families"].duplicate(),
			"world_offset": descriptor["world_offset"],
			"status": mount.get_meta("presentation_status", &"disabled"),
			"focused": bool(mount.get_meta("focused", false)),
			"near_indicator_active": bool(mount.get_meta("near_indicator_active", false)),
			"visual_part_count": part_count,
			"collision_node_count": collision_count,
		})
	return snapshot


func _wire_owner_transitions(owner: Node) -> void:
	if owner.has_signal("acknowledged"):
		var ack_callback := _on_owner_acknowledged.bind(owner)
		if not owner.is_connected("acknowledged", ack_callback):
			owner.connect("acknowledged", ack_callback)
	if owner.has_signal("sidearm_taken"):
		var taken_callback := _on_owner_used.bind(owner)
		if not owner.is_connected("sidearm_taken", taken_callback):
			owner.connect("sidearm_taken", taken_callback)
	if owner.has_signal("transit_started"):
		var started_callback := _on_transit_started.bind(owner)
		if not owner.is_connected("transit_started", started_callback):
			owner.connect("transit_started", started_callback)
	if owner.has_signal("transit_finished"):
		var finished_callback := _on_transit_finished.bind(owner)
		if not owner.is_connected("transit_finished", finished_callback):
			owner.connect("transit_finished", finished_callback)


func _on_owner_acknowledged(_actor: Node, owner: Node) -> void:
	set_owner_status(owner, &"used")


func _on_owner_used(_actor: Node, owner: Node) -> void:
	set_owner_status(owner, &"used")


func _on_transit_started(_from_station: int, owner: Node) -> void:
	set_owner_status(owner, &"disabled")


func _on_transit_finished(_to_station: int, owner: Node) -> void:
	set_owner_status(owner, &"available")


func _initial_status(owner: Node) -> StringName:
	if owner.has_method("is_busy") and bool(owner.call("is_busy")):
		return &"disabled"
	if not owner.is_in_group("interactable"):
		return &"used"
	if "is_acknowledged" in owner and bool(owner.get("is_acknowledged")):
		return &"used"
	if owner.has_method("get_interaction_prompt") and String(owner.call("get_interaction_prompt")).is_empty():
		return &"used"
	return &"available"


func _set_mount_focused(mount_id: StringName, focused: bool) -> void:
	if mount_id.is_empty():
		return
	var mount := _mounts_by_id.get(mount_id) as Node2D
	if mount == null:
		return
	mount.set_meta("focused", focused)
	mount.set_meta("near_indicator_active", focused)
	_sync_layer_visibility(mount)


func _sync_layer_visibility(mount: Node2D) -> void:
	for layer_id in LAYERS:
		var layer := mount.get_node_or_null(NodePath(LAYER_NODES[layer_id])) as Node2D
		if layer == null:
			continue
		layer.visible = layer.get_child_count() > 0
		if layer_id == &"near":
			layer.visible = layer.visible and bool(mount.get_meta("focused", false))


func _find_marker(zone_id: StringName, marker_id: StringName) -> Dictionary:
	for marker in Layout.markers_for(zone_id):
		if StringName(marker.get("id", &"")) == marker_id:
			return marker
	return {}


func _marker_key(zone_id: StringName, marker_id: StringName) -> StringName:
	return StringName("%s.%s" % [String(zone_id), String(marker_id)])


func _count_collision_nodes(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is CollisionObject2D:
			count += 1
		count += _count_collision_nodes(child)
	return count
