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

const TILE_PX := 24.0
const WALL_THICKNESS := 18.0

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


func _set_power_cost() -> void:
	# Different sector types consume different amounts
	match sector_type:
		"COMMAND":
			power_cost = 20.0
		"POWER":
			power_cost = 5.0  # Generates power, costs little
		"DEFENSE":
			power_cost = 25.0
		"ARCHIVE":
			power_cost = 15.0
		"STORAGE":
			power_cost = 5.0
		"FABRICATION":
			power_cost = 30.0
		"COMMS":
			power_cost = 10.0
		"HANGAR":
			power_cost = 15.0
		"TRANSIT":
			power_cost = 8.0
		_:
			power_cost = 10.0


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
	super.take_damage(amount)
	update_visuals()


func repair(amount: float) -> void:
	super.repair(amount)
	update_visuals()


func heal(amount: float) -> void:
	# Compatibility alias for existing pause UI repair action.
	repair(amount)


func set_power(amount: float) -> void:
	power = max(0.0, amount)
	has_power = power > 0.0 and powered
	update_visuals()


func toggle_power() -> void:
	powered = !powered
	has_power = power > 0.0 and powered
	update_visuals()


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
		power_bar.value = (power / max_power) * 100.0
		var power_pct = power / max_power
		var power_style = power_bar.get_theme_stylebox("fill")
		if power_style:
			if power_pct > 0.5:
				power_style.bg_color = Color(0.2, 0.5, 0.9)
			elif power_pct > 0.2:
				power_style.bg_color = Color(0.8, 0.6, 0.2)
			else:
				power_style.bg_color = Color(0.8, 0.2, 0.2)

	# Visual damage indication + power status
	if visual:
		var health_pct = get_efficiency()
		if health_pct > 0.7:
			visual.modulate = Color(0.3, 0.8, 0.3)
		elif health_pct > 0.3:
			visual.modulate = Color(0.8, 0.6, 0.2)
		else:
			visual.modulate = Color(0.8, 0.2, 0.2)

		if not has_power:
			visual.modulate = Color(0.2, 0.2, 0.2)
		elif not powered:
			visual.modulate = visual.modulate.darkened(0.5)


func _on_state_changed(_new_state: String) -> void:
	update_visuals()


func _on_destroyed() -> void:
	super._on_destroyed()
	print("SECTOR DESTROYED: ", sector_name)
	power = 0.0
	powered = false
	has_power = false
	update_visuals()
