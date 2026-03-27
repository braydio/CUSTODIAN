extends Node
class_name SupplyDropManager

signal supply_drop_spawned(position: Vector2, contents: Dictionary)
signal next_drop_countdown(seconds: float)

@export var drop_interval: float = 30.0
@export var initial_delay: float = 20.0
@export var ammo_cache_scene: PackedScene
@export var min_drops_per_wave: int = 1
@export var max_drops_per_wave: int = 3

@export var standard_ammo_per_drop: int = 28
@export var heavy_ammo_per_drop: int = 8

@export var container_path: NodePath = NodePath("/root/GameRoot/World/Items")

var _timer: Timer
var _countdown_timer: Timer
var _active: bool = true
var _drops_until_next_wave: int = 0

const MIN_DROP_DISTANCE_FROM_CENTER := 150.0

func _ready():
	if ammo_cache_scene == null:
		ammo_cache_scene = load("res://entities/items/ammo_cache.tscn")
	
	_setup_timers()
	_start_drop_cycle.call_deferred()

func _setup_timers() -> void:
	_timer = Timer.new()
	_timer.wait_time = max(1.0, drop_interval)
	_timer.autostart = false
	_timer.timeout.connect(_on_drop_timer_timeout)
	add_child(_timer)
	
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.autostart = false
	_countdown_timer.timeout.connect(_on_countdown_timeout)
	add_child(_countdown_timer)

func _start_drop_cycle() -> void:
	await get_tree().create_timer(initial_delay).timeout
	if _active:
		_start_next_drop_wave()

func _start_next_drop_wave() -> void:
	if not _active:
		return
	
	_drops_until_next_wave = randi_range(min_drops_per_wave, max_drops_per_wave)
	_spawn_supply_drop()
	
	_timer.start()
	_countdown_timer.start()

func _on_countdown_timeout() -> void:
	if _timer != null and not _timer.is_stopped():
		next_drop_countdown.emit(_timer.time_left)

func _on_drop_timer_timeout() -> void:
	_drops_until_next_wave -= 1
	
	if _drops_until_next_wave > 0:
		_spawn_supply_drop()
		_timer.start()
	else:
		_countdown_timer.stop()

func _spawn_supply_drop() -> void:
	var drop_position := _find_valid_drop_position()
	
	if drop_position == Vector2.ZERO:
		push_warning("[SupplyDropManager] No valid drop position found")
		return
	
	var ammo_cache = ammo_cache_scene.instantiate()
	if ammo_cache == null:
		push_warning("[SupplyDropManager] Failed to instantiate ammo cache")
		return
	
	ammo_cache.standard_ammo = standard_ammo_per_drop
	ammo_cache.heavy_ammo = heavy_ammo_per_drop
	
	var container = get_node_or_null(container_path)
	if container == null:
		push_warning("[SupplyDropManager] Container not found at %s" % String(container_path))
		ammo_cache.queue_free()
		return
	
	container.add_child(ammo_cache)
	ammo_cache.global_position = drop_position
	
	_spawn_drop_effect(drop_position)
	
	var contents := {
		"standard": standard_ammo_per_drop,
		"heavy": heavy_ammo_per_drop,
	}
	supply_drop_spawned.emit(drop_position, contents)
	print("[SupplyDropManager] Supply drop at %s | std:%d hv:%d" % [drop_position, standard_ammo_per_drop, heavy_ammo_per_drop])

func _find_valid_drop_position() -> Vector2:
	var world = get_tree().root.get_node("GameRoot/World")
	if world == null:
		return Vector2.ZERO
	
	var tile_map = world.find_child("TileMap", true, false)
	if tile_map == null:
		return _get_fallback_position()
	
	var valid_positions: Array[Vector2] = []
	var map_size = tile_map.get_used_rect()
	
	var center := Vector2.ZERO
	var operator = world.find_child("Operator", true, false)
	if operator != null:
		center = operator.global_position
	
	var min_dist := MIN_DROP_DISTANCE_FROM_CENTER
	
	for x in range(map_size.position.x, map_size.end.x + 1):
		for y in range(map_size.position.y, map_size.end.y + 1):
			var tile_pos := Vector2i(x, y)
			var tile_id: int = tile_map.get_cell_source_id(0, tile_pos)
			
			if tile_id < 0:
				continue
			
			var atlas_coord: Vector2i = tile_map.get_cell_atlas_coord(0, tile_pos)
			var tile_idx := atlas_coord.y * 4 + atlas_coord.x
			
			if tile_idx == 1:
				var world_pos := Vector2(x * 10 + 5, y * 10 + 5)
				var dist_to_center = world_pos.distance_to(center)
				
				if dist_to_center >= min_dist:
					var near_sector := _is_near_sector(world_pos, world)
					if not near_sector:
						valid_positions.append(world_pos)
	
	if valid_positions.is_empty():
		return _get_fallback_position()
	
	return valid_positions.pick_random()

func _is_near_sector(pos: Vector2, world: Node) -> bool:
	var sectors = world.find_child("Sectors", true, false)
	if sectors == null:
		return false
	
	for sector in sectors.get_children():
		if sector is Node2D:
			var dist = pos.distance_to(sector.global_position)
			if dist < 40:
				return true
	
	return false

func _get_fallback_position() -> Vector2:
	var world = get_tree().root.get_node("GameRoot/World")
	if world == null:
		return Vector2(200, 200)
	
	var center = Vector2(200, 200)
	var operator = world.find_child("Operator", true, false)
	if operator != null:
		center = operator.global_position
	
	var angle := randf() * TAU
	var dist := randf_range(180, 280)
	return center + Vector2(cos(angle), sin(angle)) * dist

func _spawn_drop_effect(pos: Vector2) -> void:
	var world = get_tree().root.get_node("GameRoot/World")
	if world == null:
		return
	
	var particles := GPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.5
	particles.position = pos
	
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 8.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 80.0
	material.gravity = Vector3(0, 200, 0)
	material.color = Color(0.3, 0.8, 0.4, 1.0)
	particles.process_material = material
	
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.8, 0.4, 1.0))
	var texture := ImageTexture.create_from_image(image)
	particles.texture = texture
	
	world.add_child(particles)
	particles.emitting = true
	
	var t := get_tree().create_timer(0.6)
	t.timeout.connect(particles.queue_free)

func set_active(value: bool) -> void:
	_active = value
	if _active and _timer != null and _timer.is_stopped() and _drops_until_next_wave == 0:
		_start_next_drop_wave()
	elif not _active:
		if _timer != null:
			_timer.stop()
		if _countdown_timer != null:
			_countdown_timer.stop()

func get_next_drop_time() -> float:
	if _timer != null and not _timer.is_stopped():
		return _timer.time_left
	return -1.0

func get_status() -> Dictionary:
	return {
		"active": _active,
		"interval": drop_interval,
		"next_drop_in": get_next_drop_time(),
		"drops_queued": _drops_until_next_wave,
	}
