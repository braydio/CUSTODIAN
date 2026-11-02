extends Node2D
class_name NavigationDebug

## Debug visualization for navigation system paths

@export var enabled: bool = false
@export var show_paths: bool = true
@export var show_walkable: bool = false
@export var path_color: Color = Color(0.3, 0.7, 1.0, 0.8)
@export var walkable_color: Color = Color(0.2, 0.8, 0.3, 0.15)
@export var point_radius: float = 4.0

var navigation_system: Node = null

func _ready() -> void:
	# Find navigation system
	navigation_system = get_tree().get_first_node_in_group("navigation")
	if navigation_system == null:
		for node in get_tree().get_nodes_in_group("navigation"):
			navigation_system = node
			break
	
	set_process(enabled)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	
	if navigation_system == null:
		return
	
	# Draw walkable tiles if enabled
	if show_walkable and "floor_tilemap" in navigation_system:
		_draw_walkable_tiles()
	
	# Draw enemy paths if enabled
	if show_paths:
		_draw_enemy_paths()


func _draw_walkable_tiles() -> void:
	var floor_tilemap = navigation_system.get("floor_tilemap")
	if floor_tilemap == null:
		return
	
	var walkable = navigation_system.get("_walkable_tiles") as Dictionary
	if walkable == null or walkable.is_empty():
		return
	
	var tile_size = navigation_system.get("tile_size") if "tile_size" in navigation_system else Vector2i(32, 32)
	
	for cell in walkable.keys():
		var world_pos = floor_tilemap.to_global(floor_tilemap.map_to_local(cell))
		draw_circle(world_pos, point_radius, walkable_color)


func _draw_enemy_paths() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("get_current_path"):
			var path = enemy.get("current_path") as PackedVector2Array
			if path != null and not path.is_empty():
				var enemy_name = enemy.get("enemy_name") if "enemy_name" in enemy else "Enemy"
				_draw_path(path, path_color, enemy_name)
			
			# Draw target line
			var target = enemy.get("target") as Node
			if target != null:
				var start = enemy.global_position
				var end = target.global_position
				draw_line(start, end, Color(1.0, 0.3, 0.3, 0.5), 1.0)


func _draw_path(path: PackedVector2Array, color: Color, label: String) -> void:
	if path.size() < 2:
		return
	
	# Draw path line
	for i in range(path.size() - 1):
		draw_line(path[i], path[i + 1], color, 2.0)
	
	# Draw waypoint circles
	for point in path:
		draw_circle(point, 3.0, color)
	
	# Draw start and end
	if not path.is_empty():
		draw_circle(path[0], 6.0, Color(0.2, 1.0, 0.4, 1.0))  # Start - green
		draw_circle(path[path.size() - 1], 6.0, Color(1.0, 0.2, 0.4, 1.0))  # End - red


func toggle_paths() -> void:
	show_paths = not show_paths


func toggle_walkable() -> void:
	show_walkable = not show_walkable


func set_enabled(value: bool) -> void:
	enabled = value
	set_process(value)
	queue_redraw()
