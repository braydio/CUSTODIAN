extends Damageable
class_name Sector

@export var sector_name: String = "SECTOR"
@export var sector_type: String = "GENERIC"
@export var size_tiles: Vector2i = Vector2i(16, 16)
@export var door_sides: PackedStringArray = PackedStringArray(["N"])
@export_range(1, 4, 1) var door_width_tiles: int = 2
@export var structure_projectile_armor: float = 8.0

var power: float = 100.0
var max_power: float = 100.0
var has_power: bool = true
var power_cost: float = 10.0  # Power consumed per second
var powered: bool = true  # Can be toggled on/off
var min_power_required: float = 4.0
var standard_power_required: float = 10.0
var power_priority: int = 50
var power_ratio: float = 1.0
var power_tier: String = "NORMAL"
var effective_output: float = 1.0

const TILE_PX := 24.0
const WALL_THICKNESS := 18.0
const INTEGRITY_MODIFIER_BY_STATE := {
	"operational": 1.0,
	"damaged": 0.75,
	"critical": 0.4,
	"destroyed": 0.0,
}

@onready var health_bar = get_node_or_null("HealthBar")
@onready var power_bar = get_node_or_null("PowerBar")
# Sector scene currently uses Floor as primary visible node.
@onready var visual = get_node_or_null("Visual") if has_node("Visual") else get_node_or_null("Floor")
@onready var floor_rect = get_node_or_null("Floor")
@onready var walls = get_node_or_null("Walls")
@onready var wall_collision = get_node_or_null("WallCollision")


func _ready() -> void:
	add_to_group("structure")
	projectile_armor = structure_projectile_armor
	match sector_type:
		"COMMAND":
			add_to_group("command_post")
		"POWER":
			add_to_group("power_node")
	_set_power_cost()
	_build_geometry()
	super._ready()
	update_visuals()
	_sync_world_state_graph()


func _set_power_cost() -> void:
	# Different sector types consume different amounts
	match sector_type:
		"COMMAND":
			power_cost = 20.0
			power_priority = 100
		"POWER":
			power_cost = 5.0  # Generates power, costs little
			power_priority = 95
		"DEFENSE":
			power_cost = 25.0
			power_priority = 85
		"ARCHIVE":
			power_cost = 15.0
			power_priority = 65
		"STORAGE":
			power_cost = 5.0
			power_priority = 35
		"FABRICATION":
			power_cost = 30.0
			power_priority = 75
		"COMMS":
			power_cost = 10.0
			power_priority = 70
		"HANGAR":
			power_cost = 15.0
			power_priority = 60
		"TRANSIT":
			power_cost = 8.0
			power_priority = 45
		_:
			power_cost = 10.0
			power_priority = 50
	min_power_required = max(1.0, power_cost * 0.4)
	standard_power_required = max(min_power_required, power_cost)
	max_power = max(max_power, standard_power_required)


func _build_geometry() -> void:
	if floor_rect == null:
		return
	var width_px = float(max(8, size_tiles.x)) * TILE_PX
	var height_px = float(max(8, size_tiles.y)) * TILE_PX
	var half_w = width_px * 0.5
	var half_h = height_px * 0.5

	floor_rect.offset_left = -half_w
	floor_rect.offset_top = -half_h
	floor_rect.offset_right = half_w
	floor_rect.offset_bottom = half_h

	if health_bar:
		health_bar.offset_left = -half_w + 14.0
		health_bar.offset_right = half_w - 14.0
		health_bar.offset_top = -half_h - 24.0
		health_bar.offset_bottom = -half_h - 8.0
	if power_bar:
		power_bar.offset_left = -half_w + 14.0
		power_bar.offset_right = half_w - 14.0
		power_bar.offset_top = -half_h - 8.0
		power_bar.offset_bottom = -half_h + 4.0

	if walls == null or wall_collision == null:
		return
	for child in walls.get_children():
		child.queue_free()
	for child in wall_collision.get_children():
		child.queue_free()

	var sides := _normalized_door_sides()
	var door_span = max(1.0, float(door_width_tiles) * TILE_PX)
	_build_side_wall("N", half_w, half_h, sides.has("N"), door_span)
	_build_side_wall("S", half_w, half_h, sides.has("S"), door_span)
	_build_side_wall("W", half_w, half_h, sides.has("W"), door_span)
	_build_side_wall("E", half_w, half_h, sides.has("E"), door_span)


func _normalized_door_sides() -> PackedStringArray:
	var normalized := PackedStringArray()
	for token in door_sides:
		var key = String(token).strip_edges().to_upper()
		if key in ["N", "S", "E", "W"] and not normalized.has(key):
			normalized.append(key)
	if normalized.is_empty():
		normalized.append("N")
	if normalized.size() > 2:
		var trimmed := PackedStringArray()
		trimmed.append(normalized[0])
		trimmed.append(normalized[1])
		return trimmed
	return normalized


func _build_side_wall(side: String, half_w: float, half_h: float, with_door: bool, door_span: float) -> void:
	if side in ["N", "S"]:
		var y = -half_h if side == "N" else half_h
		var left = -half_w
		var right = half_w
		if with_door:
			var gap_half = door_span * 0.5
			_add_wall_rect_h((left + (-gap_half)) * 0.5, y, (-gap_half) - left, WALL_THICKNESS)
			_add_wall_rect_h((gap_half + right) * 0.5, y, right - gap_half, WALL_THICKNESS)
		else:
			_add_wall_rect_h(0.0, y, right - left, WALL_THICKNESS)
	else:
		var x = -half_w if side == "W" else half_w
		var top = -half_h
		var bottom = half_h
		if with_door:
			var gap_half_v = door_span * 0.5
			_add_wall_rect_v(x, (top + (-gap_half_v)) * 0.5, WALL_THICKNESS, (-gap_half_v) - top)
			_add_wall_rect_v(x, (gap_half_v + bottom) * 0.5, WALL_THICKNESS, bottom - gap_half_v)
		else:
			_add_wall_rect_v(x, 0.0, WALL_THICKNESS, bottom - top)


func _add_wall_rect_h(center_x: float, y: float, width: float, height: float) -> void:
	if width <= 1.0:
		return
	_add_wall_visual(center_x, y, width, height)
	_add_wall_collision(center_x, y, width, height)


func _add_wall_rect_v(x: float, center_y: float, width: float, height: float) -> void:
	if height <= 1.0:
		return
	_add_wall_visual(x, center_y, width, height)
	_add_wall_collision(x, center_y, width, height)


func _add_wall_visual(x: float, y: float, width: float, height: float) -> void:
	var rect = ColorRect.new()
	rect.color = Color(0.4, 0.35, 0.3, 1)
	rect.offset_left = x - width * 0.5
	rect.offset_top = y - height * 0.5
	rect.offset_right = x + width * 0.5
	rect.offset_bottom = y + height * 0.5
	walls.add_child(rect)


func _add_wall_collision(x: float, y: float, width: float, height: float) -> void:
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, height)
	var collider = CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(x, y)
	wall_collision.add_child(collider)


func take_damage(amount: float) -> void:
	var previous_health := current_health
	super.take_damage(amount)
	update_visuals()
	if current_health < previous_health:
		_emit_sector_telemetry("sector_damage", previous_health - current_health)


func repair(amount: float) -> void:
	var previous_health := current_health
	super.repair(amount)
	update_visuals()
	if current_health > previous_health:
		_emit_sector_telemetry("sector_repair", current_health - previous_health)


func heal(amount: float) -> void:
	# Compatibility alias for existing pause UI repair action.
	repair(amount)


func set_power(amount: float) -> void:
	apply_power_allocation(amount)


func apply_power_allocation(amount: float) -> void:
	power = max(0.0, amount)
	var standard: float = max(standard_power_required, 0.001)
	power_ratio = clamp(power / standard, 0.0, 1.0)
	if not powered or is_dead():
		power_tier = "OFFLINE"
	elif power < min_power_required:
		power_tier = "OFFLINE"
	elif power < standard_power_required:
		power_tier = "DEGRADED"
	else:
		power_tier = "NORMAL"
	has_power = power_tier != "OFFLINE" and powered
	effective_output = get_power_efficiency() * get_integrity_modifier()
	update_visuals()


func toggle_power() -> void:
	powered = !powered
	apply_power_allocation(power)
	update_visuals()
	_sync_world_state_graph()


func get_integrity_modifier() -> float:
	return float(INTEGRITY_MODIFIER_BY_STATE.get(state, 0.0))


func get_power_efficiency() -> float:
	if not powered or is_dead():
		return 0.0
	if power < min_power_required:
		return 0.0
	return clamp(power / max(standard_power_required, 0.001), 0.0, 1.0)


func get_effective_output() -> float:
	return clamp(effective_output, 0.0, 1.0)


func _emit_sector_telemetry(kind: String, amount: float) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		observatory.call("log_event", kind, {
			"sector_id": _telemetry_sector_id(),
			"amount": amount,
			"state": state,
		})

	var world_history := get_node_or_null("/root/WorldHistory")
	if world_history != null:
		world_history.call("record", _telemetry_sector_id(), kind, global_position, {
			"amount": amount,
			"state": state,
		})

	_sync_world_state_graph()


func _sync_world_state_graph() -> void:
	var graph := get_node_or_null("/root/WorldStateGraph")
	if graph == null:
		return
	var sector_id := _telemetry_sector_id()
	graph.call("set_state", "sector/%s/state" % sector_id, state)
	graph.call("set_state", "sector/%s/health_ratio" % sector_id, get_efficiency())
	graph.call("set_state", "sector/%s/powered" % sector_id, has_power)


func _telemetry_sector_id() -> String:
	return String(sector_name).strip_edges().to_lower().replace(" ", "_")


func get_power_priority() -> int:
	return power_priority


func update_visuals() -> void:
	# Update health bar
	if health_bar:
		health_bar.value = get_efficiency() * 100.0
		var health_pct = get_efficiency()
		var health_style = health_bar.get_theme_stylebox("fill")
		if health_style:
			if health_pct > 0.7:
				health_style.bg_color = Color(0.2, 0.8, 0.2)
			elif health_pct > 0.3:
				health_style.bg_color = Color(0.8, 0.7, 0.2)
			else:
				health_style.bg_color = Color(0.8, 0.2, 0.2)

	# Update power bar
	if power_bar:
		power_bar.value = clamp((power / max(standard_power_required, 0.001)) * 100.0, 0.0, 100.0)
		var power_style = power_bar.get_theme_stylebox("fill")
		if power_style:
			if power_tier == "NORMAL":
				power_style.bg_color = Color(0.2, 0.5, 0.9)
			elif power_tier == "DEGRADED":
				power_style.bg_color = Color(0.8, 0.6, 0.2)
			else:
				power_style.bg_color = Color(0.45, 0.45, 0.45)

	# Visual damage indication + power status
	if visual:
		var health_pct = get_efficiency()
		if health_pct > 0.7:
			visual.modulate = Color(0.3, 0.8, 0.3)
		elif health_pct > 0.3:
			visual.modulate = Color(0.8, 0.6, 0.2)
		else:
			visual.modulate = Color(0.8, 0.2, 0.2)

		if power_tier == "OFFLINE":
			visual.modulate = Color(0.2, 0.2, 0.2)
		elif power_tier == "DEGRADED":
			visual.modulate = visual.modulate.lerp(Color(0.9, 0.75, 0.35), 0.45)


func _on_state_changed(_new_state: String) -> void:
	_sync_world_state_graph()
	apply_power_allocation(power)
	update_visuals()


func _on_destroyed() -> void:
	_sync_world_state_graph()
	super._on_destroyed()
	print("SECTOR DESTROYED: ", sector_name)
	power = 0.0
	powered = false
	has_power = false
	power_tier = "OFFLINE"
	effective_output = 0.0
	update_visuals()
