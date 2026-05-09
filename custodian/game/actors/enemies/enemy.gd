extends CharacterBody2D
class_name Enemy

const DAMAGE_POPUP_SCENE := preload("res://game/actors/ui/damage_popup.tscn")
const SCRAP_PICKUP_SCENE := preload("res://game/actors/items/scrap_pickup.tscn")
const WOLF_ANIMATION_LIBRARY := preload("res://game/enemies/procgen/wolf_animation_library.gd")
const ENEMY_PALETTE_SHADER := preload("res://game/enemies/procgen/enemy_palette_tint.gdshader")
const AXUL_DIRECTIONAL_SHEET_PATH := "res://content/sprites/additional-charsets/Small-8-Direction-Characters_by_AxulArt/Small-8-Direction-Characters_by_AxulArt.png"
const DIRECTIONAL_SUFFIXES := [&"n", &"ne", &"e", &"se", &"s", &"sw", &"w", &"nw"]
const DIRECTIONAL_ANIMATION_PREFIX := "red_walk"
const WOLF_IDLE_ANIMATION := &"idle_east"
const WOLF_MOVE_ANIMATION := &"run_east"
const WOLF_ATTACK_ANIMATION := &"bite_east"
const WOLF_DEATH_ANIMATION := &"death_east"
const WOLF_SPECIAL_ANIMATION := &"howl_east"
const CUSTOM_AMBIENT_EAST_ANIMATION := &"ambient_slink_east"
const CUSTOM_AMBIENT_NORTH_ANIMATION := &"ambient_slink_north"
const CUSTOM_AMBIENT_SOUTH_ANIMATION := &"ambient_slink_south"
const CUSTOM_AMBIENT_KO_ANIMATION := &"ambient_knockout"

enum AssaultState {
	STAGING,
	PROBING,
	COMMIT,
	REGROUP,
}

@export var enemy_name: String = "SCOUT"
@export var speed: float = 80.0
@export var health: float = 50.0
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var base_tint: Color = Color(0.8, 0.2, 0.2, 1.0)
@export var structure_attack_range: float = 58.0
@export var detection_range: float = 420.0
@export var retarget_interval: float = 0.25
@export var team: String = "enemy"
@export var strong_attack_multiplier: float = 3.0
@export var attack_objective: String = "breach_command"
@export var attack_windup_duration: float = 0.10
@export var hit_recoil_duration: float = 0.12
@export var stagger_duration: float = 0.35
@export var stagger_damage_threshold: float = 24.0
@export var assault_staging_duration_min: float = 1.25
@export var assault_staging_duration_max: float = 2.75
@export var assault_probe_duration_min: float = 2.5
@export var assault_probe_duration_max: float = 4.5
@export var assault_regroup_duration: float = 2.2
@export var assault_probe_speed_multiplier: float = 0.72
@export var assault_regroup_speed_multiplier: float = 0.82
@export var assault_damage_commit_threshold: float = 8.0
@export var assault_commit_detection_multiplier: float = 0.72
@export var passive: bool = false
@export var counts_as_wave_enemy: bool = true
@export var material_drop_min: int = 0
@export var material_drop_max: int = 0
@export var passive_wander_radius: float = 72.0
@export var passive_wander_interval_min: float = 0.8
@export var passive_wander_interval_max: float = 2.6
@export var passive_alert_radius: float = 96.0
@export var passive_flee_speed_multiplier: float = 1.9
@export var passive_flee_cooldown: float = 1.25
@export var passive_flee_retarget_interval: float = 0.35
@export var ambient_critter_target_range: float = 120.0
@export var stuck_reroute_enabled: bool = true
@export var stuck_reroute_delay: float = 0.28
@export var stuck_progress_ratio_threshold: float = 0.18
@export var stuck_repath_cooldown: float = 0.35
@export var uses_directional_charset: bool = false
@export_file("*.png") var directional_charset_sheet_path: String = AXUL_DIRECTIONAL_SHEET_PATH
@export var directional_charset_row_start: int = 2
@export var directional_charset_frame_size: int = 16
@export var directional_charset_fps: float = 8.0
@export var directional_charset_scale: Vector2 = Vector2(1.75, 1.75)
@export var directional_animation_prefix: String = DIRECTIONAL_ANIMATION_PREFIX
@export var custom_ambient_animation_enabled: bool = false
@export_file("*.png") var custom_ambient_east_sheet_path: String = ""
@export var custom_ambient_east_frame_size: Vector2i = Vector2i(64, 83)
@export var custom_ambient_east_fps: float = 10.0
@export var custom_ambient_east_scale: Vector2 = Vector2(0.42, 0.42)
@export_file("*.png") var custom_ambient_north_south_sheet_path: String = ""
@export_file("*.png") var custom_ambient_north_sheet_path: String = ""
@export_file("*.png") var custom_ambient_south_sheet_path: String = ""
@export var custom_ambient_north_south_frame_size: Vector2i = Vector2i(384, 512)
@export var custom_ambient_north_south_columns: int = 4
@export var custom_ambient_north_south_fps: float = 8.0
@export var custom_ambient_north_south_scale: Vector2 = Vector2(0.20, 0.20)
@export_file("*.png") var custom_ambient_knockout_sheet_path: String = ""
@export var custom_ambient_knockout_frame_size: Vector2i = Vector2i(384, 512)
@export var custom_ambient_knockout_columns: int = 4
@export var custom_ambient_knockout_rows: int = 2
@export var custom_ambient_knockout_fps: float = 12.0
@export var custom_ambient_knockout_scale: Vector2 = Vector2(0.20, 0.20)

var target: Node2D = null
var dead := false
var damage_timer := 0.0
var damage_interval := 1.0  # Damage every 1 second
var target_refresh_timer := 0.0
var used_strong_attack := false
var _attack_windup_timer: float = 0.0
var _pending_attack_damage: float = 0.0
var _stagger_timer: float = 0.0
var _recoil_timer: float = 0.0
var _windup_attack_is_strong: bool = false
var _threat_highlight_enabled: bool = false
var _threat_highlight_time: float = 0.0
var _base_sprite_scale: Vector2 = Vector2.ONE
var _last_move_direction: Vector2 = Vector2.DOWN
var _spawn_position: Vector2 = Vector2.ZERO
var _passive_home_initialized: bool = false
var _passive_target_position: Vector2 = Vector2.ZERO
var _passive_wander_timer: float = 0.0
var _passive_flee_timer: float = 0.0
var _passive_flee_retarget_timer: float = 0.0
var _assault_state: int = AssaultState.STAGING
var _assault_state_timer: float = 0.0
var _assault_probe_destination: Vector2 = Vector2.ZERO
var _custom_ambient_knockout_flip_h: bool = false
var _variant_profile: Resource = null
var _variant_behavior_id: String = ""
var _variant_attack_profile_id: String = ""
var _variant_special_profile_id: String = ""
var _uses_procedural_variant_visuals: bool = false
var _last_movement_probe_position: Vector2 = Vector2.ZERO
var _stuck_reroute_timer: float = 0.0
var _stuck_repath_cooldown_timer: float = 0.0

# Pathfinding
var navigation_system: Node = null
var current_path: PackedVector2Array = []
var path_follow_index: int = 0
var path_refresh_timer: float = 0.0
var path_refresh_interval: float = 0.5
var use_pathfinding: bool = true
var path_tolerance: float = 16.0

const TARGET_PRIORITY := {
	"command_post": 1,
	"power_node": 2,
	"turret": 3,
	"player": 4,
}

const OBJECTIVE_GROUPS := {
	"harass_player": ["player", "turret", "power_node", "command_post"],
	"destroy_power": ["power_node", "turret", "command_post", "player"],
	"destroy_turrets": ["turret", "power_node", "command_post", "player"],
	"breach_command": ["command_post", "turret", "power_node", "player"],
}

@onready var health_bar = $HealthBar
@onready var visual = $Visual
@onready var animated_sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

func _ready():
	add_to_group("enemies")
	add_to_group("enemy")
	if passive:
		add_to_group("ambient_critter")
	if _uses_directional_animation_set():
		_ensure_directional_animations()
		if visual:
			visual.visible = false
		if animated_sprite:
			animated_sprite.scale = _get_custom_ambient_scale_for_animation(CUSTOM_AMBIENT_SOUTH_ANIMATION) if _uses_custom_ambient_animation_set() else directional_charset_scale
			_base_sprite_scale = animated_sprite.scale
		_update_directional_animation(_last_move_direction, false)
	if animated_sprite:
		_base_sprite_scale = animated_sprite.scale
	set_passive_home_position(global_position)
	_assault_probe_destination = global_position
	_last_movement_probe_position = global_position
	_schedule_next_passive_wander()
	_enter_assault_state(AssaultState.STAGING)
	damage_timer = damage_interval
	_refresh_target()
	_initialize_navigation()
	_setup_health_bar_style()
	update_visuals()


func _setup_health_bar_style() -> void:
	if health_bar == null:
		return
	
	health_bar.custom_minimum_size = Vector2(48, 8)
	health_bar.offset_left = -24.0
	health_bar.offset_top = -28.0
	health_bar.offset_right = 24.0
	health_bar.offset_bottom = -20.0
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(0.3, 0.3, 0.3, 0.9)
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.3, 1.0)
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	health_bar.add_theme_stylebox_override("fill", fill_style)


func _initialize_navigation() -> void:
	# Find navigation system
	if navigation_system == null:
		navigation_system = get_tree().get_first_node_in_group("navigation")
	
	if navigation_system == null:
		for node in get_tree().get_nodes_in_group("navigation"):
			if node.has_method("get_path_to_target"):
				navigation_system = node
				break
	
	if navigation_system != null:
		print("[Enemy] ", enemy_name, " connected to navigation system")
	else:
		push_warning("[Enemy] ", enemy_name, " no navigation system found, using direct movement")

func _physics_process(delta):
	if dead:
		return
	_update_threat_highlight_visual(delta)
	if _update_reaction_timers(delta):
		return
	if _update_attack_windup(delta):
		return
	if passive:
		_update_passive_behavior(delta)
		return
	if _update_assault_state(delta):
		return

	target_refresh_timer -= delta
	if target_refresh_timer <= 0.0 or target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		target_refresh_timer = retarget_interval
		_refresh_target()

	if target:
		var target_pos = target.global_position
		var dist = global_position.distance_to(target_pos)
		var attack_range = _get_attack_range(target)
		
		if dist > attack_range:
			var direction: Vector2
			
			# Use pathfinding if available and target is far enough
			if use_pathfinding and navigation_system != null and navigation_system.has_method("get_path_to_target"):
				direction = _get_pathfinding_direction(target_pos, delta)
			else:
				# Direct movement (fallback)
				direction = (target_pos - global_position).normalized()
			
			velocity = direction * speed
			move_and_slide()
			_update_stuck_reroute(target_pos, delta)
			_last_move_direction = direction if direction.length_squared() > 0.0001 else _last_move_direction
			if _uses_directional_animation_set():
				_update_directional_animation(_last_move_direction, true)
		else:
			velocity = Vector2.ZERO
			var direction = (target_pos - global_position).normalized()
			if direction.length_squared() > 0.0001:
				_last_move_direction = direction
			if _uses_directional_animation_set():
				_update_directional_animation(_last_move_direction, false)
			_attack_target(delta)
		
func _attack_target(delta: float):
	if _attack_windup_timer > 0.0:
		return
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0
		if target and target.has_method("take_damage"):
			var dealt_damage := damage
			var is_strong := false
			if not used_strong_attack:
				used_strong_attack = true
				dealt_damage = damage * strong_attack_multiplier
				is_strong = true
			_start_attack_windup(dealt_damage, is_strong)

func _refresh_target():
	if passive:
		target = null
		return
	if _assault_state == AssaultState.STAGING or _assault_state == AssaultState.REGROUP:
		target = null
		return
	target = _find_best_target()

func _find_best_target() -> Node2D:
	var best: Node2D = null
	var best_priority := 999
	var best_distance := INF
	var groups: Array = OBJECTIVE_GROUPS.get(attack_objective, OBJECTIVE_GROUPS["breach_command"])
	for group_name in groups:
		var priority = int(TARGET_PRIORITY.get(group_name, 999))
		for candidate in get_tree().get_nodes_in_group(group_name):
			if not (candidate is Node2D):
				continue
			var node = candidate as Node2D
			if _is_target_destroyed(node):
				continue
			var dist = global_position.distance_to(node.global_position)
			if group_name != "player" and dist > detection_range:
				continue
			if priority < best_priority or (priority == best_priority and dist < best_distance):
				best = node
				best_priority = priority
				best_distance = dist
	if best == null:
		best = _find_nearest_ambient_critter_target()
	return best


func _find_nearest_ambient_critter_target() -> Node2D:
	if passive:
		return null
	var nearest: Node2D = null
	var nearest_dist := ambient_critter_target_range
	for candidate in get_tree().get_nodes_in_group("ambient_critter"):
		if not (candidate is Node2D):
			continue
		var node := candidate as Node2D
		if node == self or _is_target_destroyed(node):
			continue
		var dist := global_position.distance_to(node.global_position)
		if dist <= nearest_dist:
			nearest = node
			nearest_dist = dist
	return nearest

func _is_target_destroyed(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return true
	if node.has_method("is_dead"):
		return bool(node.is_dead())
	return false

func _get_attack_range(node: Node2D) -> float:
	if _variant_profile != null:
		return float(_variant_profile.get("attack_range"))
	if node.is_in_group("player"):
		return 40.0
	return structure_attack_range


func apply_variant(profile: Resource) -> void:
	if profile == null:
		return
	_variant_profile = profile
	_variant_behavior_id = String(profile.get("behavior_id"))
	_variant_attack_profile_id = String(profile.get("attack_profile_id"))
	_variant_special_profile_id = String(profile.get("special_profile_id"))
	enemy_name = String(profile.get("display_name"))
	max_health = float(profile.get("max_health"))
	health = max_health
	speed = float(profile.get("move_speed"))
	damage = float(profile.get("attack_damage"))
	damage_interval = float(profile.get("attack_cooldown"))
	structure_attack_range = float(profile.get("attack_range"))
	detection_range = float(profile.get("detection_radius"))
	base_tint = Color(profile.get("primary_tint"))
	if profile.get("archetype_id") == "wolf":
		_apply_wolf_variant_visuals(profile)
	_apply_variant_collision(profile)
	update_visuals()


func get_variant_summary() -> Dictionary:
	if _variant_profile == null:
		return {}
	if _variant_profile.has_method("get_debug_summary"):
		return _variant_profile.call("get_debug_summary")
	return {
		"display_name": enemy_name,
		"behavior_id": _variant_behavior_id,
		"attack_profile_id": _variant_attack_profile_id,
		"special_profile_id": _variant_special_profile_id,
	}


func _apply_wolf_variant_visuals(profile: Resource) -> void:
	_uses_procedural_variant_visuals = true
	uses_directional_charset = false
	custom_ambient_animation_enabled = false
	if visual == null and has_node("Visual"):
		visual = get_node("Visual")
	if visual:
		visual.visible = false
	if animated_sprite == null and has_node("AnimatedSprite2D"):
		animated_sprite = get_node("AnimatedSprite2D")
	if animated_sprite == null:
		return
	animated_sprite.visible = true
	animated_sprite.sprite_frames = WOLF_ANIMATION_LIBRARY.get_wolf_sprite_frames()
	animated_sprite.position = Vector2(0.0, -12.0)
	animated_sprite.scale = Vector2(profile.get("body_scale"))
	animated_sprite.speed_scale = float(profile.get("animation_speed_scale"))
	animated_sprite.flip_h = false
	_base_sprite_scale = animated_sprite.scale
	var material := ShaderMaterial.new()
	material.shader = ENEMY_PALETTE_SHADER
	material.set_shader_parameter("primary_tint", Color(profile.get("primary_tint")))
	material.set_shader_parameter("glow_tint", Color(profile.get("glow_color")))
	material.set_shader_parameter("glow_strength", float(profile.get("glow_strength")))
	material.set_shader_parameter("contrast_boost", float(profile.get("contrast_boost")))
	animated_sprite.material = material
	_play_animation(String(WOLF_IDLE_ANIMATION), false)


func _apply_variant_collision(profile: Resource) -> void:
	var collision_radius := float(profile.get("collision_radius"))
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = collision_radius
	collision_shape.shape = circle


func _get_pathfinding_direction(target_pos: Vector2, delta: float) -> Vector2:
	# Refresh path periodically
	path_refresh_timer -= delta
	_stuck_repath_cooldown_timer = maxf(0.0, _stuck_repath_cooldown_timer - delta)
	if path_refresh_timer <= 0.0 or current_path.is_empty():
		path_refresh_timer = path_refresh_interval
		_refresh_path(target_pos)
	
	# If no valid path, move directly toward target
	if current_path.is_empty():
		return (target_pos - global_position).normalized()
	
	# Follow path waypoints
	return _get_direction_along_path(target_pos)


func _update_stuck_reroute(target_pos: Vector2, delta: float) -> void:
	if not stuck_reroute_enabled or not use_pathfinding or navigation_system == null:
		_last_movement_probe_position = global_position
		_stuck_reroute_timer = 0.0
		return
	var attempted_distance := velocity.length() * delta
	if attempted_distance <= 0.01:
		_last_movement_probe_position = global_position
		_stuck_reroute_timer = 0.0
		return
	var moved_distance := global_position.distance_to(_last_movement_probe_position)
	_last_movement_probe_position = global_position
	var blocked_by_collision := get_slide_collision_count() > 0
	var stalled := moved_distance < attempted_distance * stuck_progress_ratio_threshold
	if blocked_by_collision or stalled:
		_stuck_reroute_timer += delta
	else:
		_stuck_reroute_timer = 0.0
	if _stuck_reroute_timer < stuck_reroute_delay:
		return
	if _stuck_repath_cooldown_timer > 0.0:
		return
	_stuck_reroute_timer = 0.0
	_stuck_repath_cooldown_timer = stuck_repath_cooldown
	current_path = PackedVector2Array()
	path_follow_index = 0
	path_refresh_timer = path_refresh_interval
	_refresh_path(target_pos)


func _update_passive_obstacle_recovery(delta: float) -> void:
	if not stuck_reroute_enabled:
		_last_movement_probe_position = global_position
		_stuck_reroute_timer = 0.0
		return
	var attempted_distance := velocity.length() * delta
	if attempted_distance <= 0.01:
		_last_movement_probe_position = global_position
		_stuck_reroute_timer = 0.0
		return
	var moved_distance := global_position.distance_to(_last_movement_probe_position)
	_last_movement_probe_position = global_position
	var blocked_by_collision := get_slide_collision_count() > 0
	var stalled := moved_distance < attempted_distance * stuck_progress_ratio_threshold
	if blocked_by_collision or stalled:
		_stuck_reroute_timer += delta
	else:
		_stuck_reroute_timer = 0.0
	if _stuck_reroute_timer >= stuck_reroute_delay:
		_stuck_reroute_timer = 0.0
		_choose_next_passive_destination()


func _refresh_path(target_pos: Vector2) -> void:
	if navigation_system == null:
		current_path = PackedVector2Array()
		return
	
	var path = navigation_system.get_path_to_target(global_position, target_pos)
	
	# Filter out points too close to current position
	if not path.is_empty():
		# Skip first point if it's behind us
		while path.size() > 1 and global_position.distance_squared_to(path[0]) < path_tolerance * path_tolerance:
			path.remove_at(0)
	
	current_path = path
	path_follow_index = 0


func _get_direction_along_path(target_pos: Vector2) -> Vector2:
	if current_path.is_empty():
		return (target_pos - global_position).normalized()
	
	# Find the next reachable waypoint
	while path_follow_index < current_path.size() - 1:
		var waypoint = current_path[path_follow_index]
		if global_position.distance_to(waypoint) <= path_tolerance:
			path_follow_index += 1
		else:
			break
	
	# Get target waypoint
	var target_waypoint: Vector2
	if path_follow_index < current_path.size():
		target_waypoint = current_path[path_follow_index]
	else:
		target_waypoint = target_pos
	
	var direction = (target_waypoint - global_position).normalized()
	
	# If close to final waypoint and has direct line to actual target, switch to direct
	if path_follow_index >= current_path.size() - 1:
		var dist_to_target = global_position.distance_to(target_pos)
		if dist_to_target < path_tolerance * 3.0:
			current_path = PackedVector2Array()  # Clear path, go direct
	
	return direction


func has_valid_path() -> bool:
	return not current_path.is_empty()


func get_path_remaining() -> int:
	return max(0, current_path.size() - path_follow_index)


func get_current_path() -> PackedVector2Array:
	return current_path


func get_navigation_target() -> Node:
	return target


func clear_path() -> void:
	current_path = PackedVector2Array()
	path_follow_index = 0

func apply_difficulty_modifiers(hp_scale: float, damage_scale: float):
	max_health = max(1.0, max_health * hp_scale)
	health = max(1.0, health * hp_scale)
	damage = max(1.0, damage * damage_scale)
	update_visuals()

func take_damage(amount: float):
	if dead:
		return
	
	health -= amount
	_on_assault_damage_taken(amount)
	_apply_reaction(amount)
	update_visuals()
	_spawn_damage_popup(amount)
	
	# Flash effect
	if visual:
		visual.modulate = Color(1, 1, 1)  # Flash white
		await get_tree().create_timer(0.1).timeout
		update_visuals()
	
	if health <= 0:
		die()

func update_visuals():
	if health_bar:
		health_bar.value = (health / max_health) * 100.0
		
		var health_pct = health / max_health
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style:
			if health_pct > 0.6:
				fill_style.bg_color = Color(0.2, 0.85, 0.3, 1.0)
			elif health_pct > 0.3:
				fill_style.bg_color = Color(0.85, 0.7, 0.2, 1.0)
			else:
				fill_style.bg_color = Color(0.9, 0.25, 0.2, 1.0)
	
	if visual:
		var health_pct = health / max_health
		if health_pct > 0.5:
			visual.modulate = base_tint
		elif health_pct > 0.2:
			visual.modulate = base_tint.lerp(Color(1.0, 0.65, 0.25, 1.0), 0.35)
		else:
			visual.modulate = base_tint.darkened(0.35)

func die():
	dead = true
	velocity = Vector2.ZERO
	set_threat_highlight(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true
	var camera = get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera and camera.has_method("on_enemy_killed"):
		camera.call("on_enemy_killed")
	_spawn_material_pickup()
	print("ENEMY DESTROYED: ", enemy_name)
	if _uses_procedural_variant_animation_set() and _has_animation(String(WOLF_DEATH_ANIMATION)):
		call_deferred("_play_procedural_variant_death")
		return
	if _uses_custom_ambient_animation_set() and _has_animation(String(CUSTOM_AMBIENT_KO_ANIMATION)):
		call_deferred("_play_custom_ambient_knockout")
		return
	queue_free()


func is_passive_enemy() -> bool:
	return passive


func counts_for_wave_cap() -> bool:
	return counts_as_wave_enemy and not passive


func set_passive_home_position(home_position: Vector2) -> void:
	_spawn_position = home_position
	_passive_home_initialized = true
	_passive_target_position = home_position
	clear_path()


func _update_passive_behavior(delta: float) -> void:
	target = null
	if not _passive_home_initialized:
		set_passive_home_position(global_position)
	_passive_wander_timer -= delta
	_passive_flee_timer = max(0.0, _passive_flee_timer - delta)
	_passive_flee_retarget_timer = max(0.0, _passive_flee_retarget_timer - delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		var away_from_player := global_position - player.global_position
		var player_distance := away_from_player.length()
		if player_distance <= passive_alert_radius and (_passive_flee_timer <= 0.0 or _passive_flee_retarget_timer <= 0.0):
			var flee_direction := away_from_player.normalized() if player_distance > 0.001 else Vector2.RIGHT.rotated(randf() * TAU)
			var flee_radius: float = max(passive_wander_radius, passive_alert_radius * 1.25)
			_passive_target_position = _pick_passive_destination_near_home(flee_direction, flee_radius)
			_passive_flee_timer = passive_flee_cooldown
			_passive_flee_retarget_timer = passive_flee_retarget_interval
	var to_target := _passive_target_position - global_position
	if to_target.length() > 6.0:
		var move_direction := to_target.normalized()
		var move_speed := speed * (passive_flee_speed_multiplier if _passive_flee_timer > 0.0 else 1.0)
		velocity = move_direction * move_speed
		move_and_slide()
		_update_passive_obstacle_recovery(delta)
		_last_move_direction = move_direction
		if _uses_directional_animation_set():
			_update_directional_animation(_last_move_direction, true)
		return

	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)
	if _passive_flee_timer > 0.0:
		return
	if _passive_wander_timer <= 0.0:
		_choose_next_passive_destination()


func _schedule_next_passive_wander() -> void:
	_passive_wander_timer = randf_range(
		min(passive_wander_interval_min, passive_wander_interval_max),
		max(passive_wander_interval_min, passive_wander_interval_max)
	)


func _choose_next_passive_destination() -> void:
	_schedule_next_passive_wander()
	if passive_wander_radius <= 1.0:
		_passive_target_position = _spawn_position
		return
	_passive_target_position = _pick_passive_destination_near_home()


func _pick_passive_destination_near_home(preferred_direction: Vector2 = Vector2.ZERO, preferred_distance: float = -1.0) -> Vector2:
	var fallback: Vector2 = _spawn_position
	var sample_count: int = 10
	for i in range(sample_count):
		var direction: Vector2 = preferred_direction
		if direction.length_squared() <= 0.0001 or i > 0:
			direction = Vector2.RIGHT.rotated(randf() * TAU)
		else:
			direction = direction.normalized().rotated(randf_range(-0.45, 0.45))
		var max_distance: float = maxf(12.0, passive_wander_radius)
		var distance: float = preferred_distance if preferred_distance > 0.0 and i == 0 else randf_range(12.0, max_distance)
		distance = clampf(distance, 12.0, max_distance)
		var candidate: Vector2 = _spawn_position + direction * distance
		if _is_passive_destination_valid(candidate):
			return candidate
		if i == 0:
			fallback = candidate
	return fallback


func _is_passive_destination_valid(destination: Vector2) -> bool:
	if navigation_system != null and navigation_system.has_method("is_in_walkable_area"):
		return bool(navigation_system.call("is_in_walkable_area", destination))
	return true


func _spawn_material_pickup() -> void:
	if SCRAP_PICKUP_SCENE == null:
		return
	var drop_min: int = max(0, material_drop_min)
	var drop_max: int = max(drop_min, material_drop_max)
	if drop_max <= 0:
		return
	var pickup := SCRAP_PICKUP_SCENE.instantiate()
	if pickup == null:
		return
	if pickup.has_method("set_material_amount"):
		pickup.call("set_material_amount", randi_range(drop_min, drop_max))
	else:
		pickup.set("material_amount", randi_range(drop_min, drop_max))
	var parent := get_parent()
	if parent != null:
		parent.add_child(pickup)
	else:
		get_tree().current_scene.add_child(pickup)
	if pickup is Node2D:
		(pickup as Node2D).global_position = global_position


func _start_attack_windup(queued_damage: float, is_strong: bool) -> void:
	_pending_attack_damage = queued_damage
	_attack_windup_timer = max(0.01, attack_windup_duration)
	_windup_attack_is_strong = is_strong
	velocity = Vector2.ZERO
	if _uses_procedural_variant_animation_set():
		_update_procedural_variant_animation(_last_move_direction, false, true)
	elif _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _update_attack_windup(delta: float) -> bool:
	if _attack_windup_timer <= 0.0:
		return false
	_attack_windup_timer = max(0.0, _attack_windup_timer - delta)
	velocity = Vector2.ZERO
	if _attack_windup_timer > 0.0:
		return true
	_execute_queued_attack()
	return true


func _execute_queued_attack() -> void:
	if dead:
		return
	if target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(_pending_attack_damage)
		print("Enemy hit ", target.name, " for ", _pending_attack_damage, " damage!")
	_pending_attack_damage = 0.0
	_windup_attack_is_strong = false


func _apply_reaction(amount: float) -> void:
	if amount >= stagger_damage_threshold:
		_start_stagger_reaction()
	else:
		_start_hit_recoil_reaction()


func apply_melee_impact(attack_kind: String, knockback_direction: Vector2, knockback_force: float) -> void:
	if dead:
		return
	_custom_ambient_knockout_flip_h = knockback_direction.x > 0.0
	_last_move_direction = knockback_direction if knockback_direction.length_squared() > 0.0001 else _last_move_direction
	if attack_kind == "heavy":
		_stagger_timer = max(_stagger_timer, stagger_duration * 1.2)
		_recoil_timer = 0.0
	else:
		_recoil_timer = max(_recoil_timer, hit_recoil_duration * 1.2)
	velocity = knockback_direction.normalized() * knockback_force
	move_and_slide()
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _start_hit_recoil_reaction() -> void:
	_recoil_timer = max(_recoil_timer, hit_recoil_duration)
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _start_stagger_reaction() -> void:
	_stagger_timer = max(_stagger_timer, stagger_duration)
	_recoil_timer = 0.0
	_attack_windup_timer = 0.0
	_pending_attack_damage = 0.0
	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)


func _spawn_damage_popup(amount: float) -> void:
	var popup := DAMAGE_POPUP_SCENE.instantiate()
	popup.text = str(int(amount))
	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-10, 10), -20)


func _update_reaction_timers(delta: float) -> bool:
	if _stagger_timer > 0.0:
		_stagger_timer = max(0.0, _stagger_timer - delta)
		velocity = Vector2.ZERO
		if _uses_directional_animation_set():
			_update_directional_animation(_last_move_direction, false)
		return true
	if _recoil_timer > 0.0:
		_recoil_timer = max(0.0, _recoil_timer - delta)
		velocity = Vector2.ZERO
		if _uses_directional_animation_set():
			_update_directional_animation(_last_move_direction, false)
		return true
	return false


func _update_assault_state(delta: float) -> bool:
	_assault_state_timer = max(0.0, _assault_state_timer - delta)
	match _assault_state:
		AssaultState.STAGING:
			return _update_staging_state()
		AssaultState.PROBING:
			if _assault_state_timer <= 0.0:
				_enter_assault_state(AssaultState.COMMIT)
			return _update_probing_state()
		AssaultState.REGROUP:
			if _assault_state_timer <= 0.0:
				_enter_assault_state(AssaultState.PROBING)
			return _update_regroup_state()
		_:
			return false


func _update_staging_state() -> bool:
	velocity = Vector2.ZERO
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, false)
	if _assault_state_timer <= 0.0:
		_enter_assault_state(AssaultState.PROBING)
	return true


func _update_probing_state() -> bool:
	var sensed_target := _find_best_target_in_range(detection_range * assault_commit_detection_multiplier)
	if sensed_target != null:
		target = sensed_target
		_enter_assault_state(AssaultState.COMMIT)
		return false
	if _assault_probe_destination.distance_to(_spawn_position) <= 1.0:
		_refresh_probe_destination()
	var move_direction := (_assault_probe_destination - global_position).normalized()
	if global_position.distance_to(_assault_probe_destination) <= path_tolerance:
		_refresh_probe_destination()
		move_direction = (_assault_probe_destination - global_position).normalized()
	velocity = move_direction * speed * assault_probe_speed_multiplier if move_direction.length_squared() > 0.0001 else Vector2.ZERO
	move_and_slide()
	if move_direction.length_squared() > 0.0001:
		_last_move_direction = move_direction
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, velocity.length_squared() > 0.0001)
	return true


func _update_regroup_state() -> bool:
	target = null
	clear_path()
	var fallback_target := _spawn_position
	var retreat_direction := (fallback_target - global_position).normalized()
	velocity = retreat_direction * speed * assault_regroup_speed_multiplier if retreat_direction.length_squared() > 0.0001 else Vector2.ZERO
	move_and_slide()
	if retreat_direction.length_squared() > 0.0001:
		_last_move_direction = retreat_direction
	if _uses_directional_animation_set():
		_update_directional_animation(_last_move_direction, velocity.length_squared() > 0.0001)
	return true


func _enter_assault_state(next_state: int) -> void:
	_assault_state = next_state
	match _assault_state:
		AssaultState.STAGING:
			target = null
			clear_path()
			_assault_state_timer = randf_range(
				min(assault_staging_duration_min, assault_staging_duration_max),
				max(assault_staging_duration_min, assault_staging_duration_max)
			)
		AssaultState.PROBING:
			target = null
			clear_path()
			_assault_state_timer = randf_range(
				min(assault_probe_duration_min, assault_probe_duration_max),
				max(assault_probe_duration_min, assault_probe_duration_max)
			)
			_refresh_probe_destination()
		AssaultState.COMMIT:
			_assault_state_timer = 0.0
		AssaultState.REGROUP:
			target = null
			clear_path()
			_assault_state_timer = max(0.1, assault_regroup_duration)


func _refresh_probe_destination() -> void:
	var offset := Vector2(
		randf_range(-96.0, 96.0),
		randf_range(-96.0, 96.0)
	)
	_assault_probe_destination = _spawn_position + offset


func _find_best_target_in_range(max_range: float) -> Node2D:
	var best: Node2D = null
	var best_priority := 999
	var best_distance := INF
	var groups: Array = OBJECTIVE_GROUPS.get(attack_objective, OBJECTIVE_GROUPS["breach_command"])
	for group_name in groups:
		var priority = int(TARGET_PRIORITY.get(group_name, 999))
		for candidate in get_tree().get_nodes_in_group(group_name):
			if not (candidate is Node2D):
				continue
			var node := candidate as Node2D
			if _is_target_destroyed(node):
				continue
			var dist := global_position.distance_to(node.global_position)
			if dist > max_range:
				continue
			if priority < best_priority or (priority == best_priority and dist < best_distance):
				best = node
				best_priority = priority
				best_distance = dist
	return best


func _on_assault_damage_taken(amount: float) -> void:
	if passive or dead:
		return
	if _assault_state == AssaultState.STAGING or _assault_state == AssaultState.PROBING:
		if amount >= assault_damage_commit_threshold:
			_enter_assault_state(AssaultState.COMMIT)
		return
	if _assault_state == AssaultState.COMMIT and health > 0.0 and health <= max_health * 0.35:
		_enter_assault_state(AssaultState.REGROUP)

func is_dead() -> bool:
	return dead


func _uses_directional_animation_set() -> bool:
	return (uses_directional_charset or _uses_custom_ambient_animation_set() or _uses_procedural_variant_animation_set()) and animated_sprite != null


func _uses_procedural_variant_animation_set() -> bool:
	return _uses_procedural_variant_visuals and animated_sprite != null


func _uses_custom_ambient_animation_set() -> bool:
	return custom_ambient_animation_enabled and passive and animated_sprite != null


func _has_animation(name: String) -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	return animated_sprite.sprite_frames.has_animation(name)


func _play_animation(name: String, allow_restart: bool = true) -> void:
	if not _has_animation(name):
		return
	if not allow_restart and animated_sprite.animation == name and animated_sprite.is_playing():
		return
	if allow_restart and animated_sprite.animation == name:
		if animated_sprite.is_playing():
			animated_sprite.set_frame_and_progress(0, 0.0)
		else:
			animated_sprite.play(name)
		return
	animated_sprite.play(name)


func _ensure_directional_animations() -> void:
	if animated_sprite == null or _has_directional_animation_assets():
		return
	if _uses_procedural_variant_animation_set():
		animated_sprite.sprite_frames = WOLF_ANIMATION_LIBRARY.get_wolf_sprite_frames()
		return
	if _uses_custom_ambient_animation_set():
		_ensure_custom_ambient_animations()
		return
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrames.new()
	if not ResourceLoader.exists(directional_charset_sheet_path):
		return
	var texture := load(directional_charset_sheet_path)
	if not (texture is Texture2D):
		return
	var tex := texture as Texture2D
	var safe_frame_size: int = max(1, directional_charset_frame_size)
	var safe_row_start: int = max(0, directional_charset_row_start)
	var sheet_rows := int(tex.get_height() / safe_frame_size)
	var sheet_cols := int(tex.get_width() / safe_frame_size)
	if sheet_rows < safe_row_start + 4 or sheet_cols < DIRECTIONAL_SUFFIXES.size():
		return

	var frames: SpriteFrames = animated_sprite.sprite_frames
	for dir_index in range(DIRECTIONAL_SUFFIXES.size()):
		var suffix: String = String(DIRECTIONAL_SUFFIXES[dir_index])
		var anim_name := _get_directional_animation_name(StringName(suffix))
		if frames.has_animation(anim_name):
			frames.remove_animation(anim_name)
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, directional_charset_fps)
		for frame_index in range(4):
			frames.add_frame(anim_name, _build_directional_atlas(tex, dir_index, safe_row_start + frame_index, safe_frame_size))


func _build_directional_atlas(texture: Texture2D, dir_index: int, row_index: int, frame_size: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(dir_index * frame_size), float(row_index * frame_size), float(frame_size), float(frame_size))
	return atlas


func _update_directional_animation(direction: Vector2, is_moving: bool) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if _uses_procedural_variant_animation_set():
		_update_procedural_variant_animation(direction, is_moving)
		return
	if _uses_custom_ambient_animation_set():
		_update_custom_ambient_animation(direction, is_moving)
		return
	var anim_name := _get_directional_animation_name(_get_directional_charset_suffix(direction))
	if not _has_animation(anim_name):
		return
	if is_moving:
		_play_animation(anim_name, false)
		return
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
	animated_sprite.stop()
	animated_sprite.set_frame_and_progress(0, 0.0)


func _get_directional_charset_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var angle := wrapf(direction.angle(), 0.0, TAU)
	var sector := int(round(angle / (PI / 4.0))) % DIRECTIONAL_SUFFIXES.size()
	var angle_to_index := [2, 3, 4, 5, 6, 7, 0, 1]
	return DIRECTIONAL_SUFFIXES[angle_to_index[sector]]


func _get_directional_animation_name(suffix: StringName) -> String:
	return "%s_%s" % [directional_animation_prefix, String(suffix)]


func _has_directional_animation_assets() -> bool:
	if _uses_custom_ambient_animation_set():
		return _has_animation(String(CUSTOM_AMBIENT_EAST_ANIMATION)) and _has_animation(String(CUSTOM_AMBIENT_NORTH_ANIMATION)) and _has_animation(String(CUSTOM_AMBIENT_SOUTH_ANIMATION))
	for suffix in DIRECTIONAL_SUFFIXES:
		if _has_animation(_get_directional_animation_name(suffix)):
			return true
	return false


func _ensure_custom_ambient_animations() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrames.new()
	var frames: SpriteFrames = animated_sprite.sprite_frames
	_build_custom_ambient_east_animation(frames)
	_build_custom_ambient_north_south_animations(frames)
	_build_custom_ambient_knockout_animation(frames)


func _build_custom_ambient_east_animation(frames: SpriteFrames) -> void:
	var texture: Texture2D = _load_enemy_texture(custom_ambient_east_sheet_path)
	if texture == null:
		return
	var frame_width: int = max(1, custom_ambient_east_frame_size.x)
	var frame_height: int = max(1, custom_ambient_east_frame_size.y)
	var frame_count: int = max(1, texture.get_width() / frame_width)
	_rebuild_animation(frames, String(CUSTOM_AMBIENT_EAST_ANIMATION), frame_count, true, custom_ambient_east_fps, func(frame_index: int) -> AtlasTexture:
		return _build_custom_region_atlas(texture, frame_index * frame_width, 0, frame_width, frame_height)
	)


func _build_custom_ambient_north_south_animations(frames: SpriteFrames) -> void:
	if not custom_ambient_north_sheet_path.is_empty() and not custom_ambient_south_sheet_path.is_empty():
		_build_custom_ambient_strip_animation(
			frames,
			CUSTOM_AMBIENT_NORTH_ANIMATION,
			custom_ambient_north_sheet_path,
			custom_ambient_north_south_frame_size,
			custom_ambient_north_south_fps
		)
		_build_custom_ambient_strip_animation(
			frames,
			CUSTOM_AMBIENT_SOUTH_ANIMATION,
			custom_ambient_south_sheet_path,
			custom_ambient_north_south_frame_size,
			custom_ambient_north_south_fps
		)
		return
	var texture: Texture2D = _load_enemy_texture(custom_ambient_north_south_sheet_path)
	if texture == null:
		return
	var frame_width: int = max(1, custom_ambient_north_south_frame_size.x)
	var frame_height: int = max(1, custom_ambient_north_south_frame_size.y)
	var columns: int = max(1, custom_ambient_north_south_columns)
	_rebuild_animation(frames, String(CUSTOM_AMBIENT_NORTH_ANIMATION), columns, true, custom_ambient_north_south_fps, func(frame_index: int) -> AtlasTexture:
		return _build_custom_region_atlas(texture, frame_index * frame_width, 0, frame_width, frame_height)
	)
	_rebuild_animation(frames, String(CUSTOM_AMBIENT_SOUTH_ANIMATION), columns, true, custom_ambient_north_south_fps, func(frame_index: int) -> AtlasTexture:
		return _build_custom_region_atlas(texture, frame_index * frame_width, frame_height, frame_width, frame_height)
	)


func _build_custom_ambient_strip_animation(frames: SpriteFrames, animation_name: StringName, sheet_path: String, frame_size: Vector2i, fps: float) -> void:
	var texture: Texture2D = _load_enemy_texture(sheet_path)
	if texture == null:
		return
	var frame_width: int = max(1, frame_size.x)
	var frame_height: int = max(1, frame_size.y)
	var frame_count: int = max(1, texture.get_width() / frame_width)
	_rebuild_animation(frames, String(animation_name), frame_count, true, fps, func(frame_index: int) -> AtlasTexture:
		return _build_custom_region_atlas(texture, frame_index * frame_width, 0, frame_width, frame_height)
	)


func _build_custom_ambient_knockout_animation(frames: SpriteFrames) -> void:
	var texture: Texture2D = _load_enemy_texture(custom_ambient_knockout_sheet_path)
	if texture == null:
		return
	var frame_width: int = max(1, custom_ambient_knockout_frame_size.x)
	var frame_height: int = max(1, custom_ambient_knockout_frame_size.y)
	var columns: int = max(1, custom_ambient_knockout_columns)
	var rows: int = max(1, custom_ambient_knockout_rows)
	var frame_count: int = columns * rows
	_rebuild_animation(frames, String(CUSTOM_AMBIENT_KO_ANIMATION), frame_count, false, custom_ambient_knockout_fps, func(frame_index: int) -> AtlasTexture:
		var col: int = frame_index % columns
		var row: int = frame_index / columns
		return _build_custom_region_atlas(texture, col * frame_width, row * frame_height, frame_width, frame_height)
	)


func _rebuild_animation(frames: SpriteFrames, animation_name: String, frame_count: int, loop: bool, fps: float, atlas_builder: Callable) -> void:
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, fps)
	for frame_index in range(frame_count):
		var atlas_variant: Variant = atlas_builder.call(frame_index)
		if atlas_variant is AtlasTexture:
			frames.add_frame(animation_name, atlas_variant as AtlasTexture)


func _build_custom_region_atlas(texture: Texture2D, x: int, y: int, width: int, height: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(x), float(y), float(width), float(height))
	return atlas


func _load_enemy_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource := load(path)
	if resource is Texture2D:
		return resource as Texture2D
	return null


func _update_custom_ambient_animation(direction: Vector2, is_moving: bool) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var animation_name := CUSTOM_AMBIENT_SOUTH_ANIMATION
	var flip_h := false
	if absf(direction.x) >= absf(direction.y) and direction.length_squared() > 0.0001:
		animation_name = CUSTOM_AMBIENT_EAST_ANIMATION
		flip_h = direction.x < 0.0
	elif direction.y < 0.0:
		animation_name = CUSTOM_AMBIENT_NORTH_ANIMATION
	animated_sprite.flip_h = flip_h
	animated_sprite.scale = _get_custom_ambient_scale_for_animation(animation_name)
	_base_sprite_scale = animated_sprite.scale
	if not _has_animation(String(animation_name)):
		return
	if is_moving:
		_play_animation(String(animation_name), false)
		return
	if animated_sprite.animation != String(animation_name):
		animated_sprite.play(String(animation_name))
	animated_sprite.stop()
	animated_sprite.set_frame_and_progress(0, 0.0)


func _update_procedural_variant_animation(direction: Vector2, is_moving: bool, force_attack: bool = false) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var direction_suffix := _get_procedural_variant_direction_suffix(direction)
	animated_sprite.flip_h = direction_suffix == "west"
	var animation_name := "idle_%s" % direction_suffix
	if force_attack:
		animation_name = "bite_%s" % direction_suffix
	elif is_moving:
		animation_name = "run_%s" % direction_suffix
	if not _has_animation(animation_name):
		animation_name = String(WOLF_ATTACK_ANIMATION if force_attack else (WOLF_MOVE_ANIMATION if is_moving else WOLF_IDLE_ANIMATION))
		if not _has_animation(animation_name):
			return
	if is_moving or force_attack:
		_play_animation(animation_name, false)
		return
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	animated_sprite.stop()
	animated_sprite.set_frame_and_progress(0, 0.0)


func _get_procedural_variant_direction_suffix(direction: Vector2) -> String:
	var facing := direction
	if facing.length_squared() <= 0.0001:
		facing = _last_move_direction
	if facing.length_squared() <= 0.0001:
		return "east"
	if absf(facing.x) >= absf(facing.y):
		return "west" if facing.x < 0.0 else "east"
	return "north" if facing.y < 0.0 else "south"


func _play_procedural_variant_death() -> void:
	if animated_sprite == null or not _has_animation(String(WOLF_DEATH_ANIMATION)):
		queue_free()
		return
	animated_sprite.play(String(WOLF_DEATH_ANIMATION))
	await animated_sprite.animation_finished
	queue_free()


func _get_custom_ambient_scale_for_animation(animation_name: StringName) -> Vector2:
	if animation_name == CUSTOM_AMBIENT_EAST_ANIMATION:
		return custom_ambient_east_scale
	if animation_name == CUSTOM_AMBIENT_KO_ANIMATION:
		return custom_ambient_knockout_scale
	return custom_ambient_north_south_scale


func _play_custom_ambient_knockout() -> void:
	if animated_sprite == null or not _has_animation(String(CUSTOM_AMBIENT_KO_ANIMATION)):
		queue_free()
		return
	animated_sprite.flip_h = _custom_ambient_knockout_flip_h
	animated_sprite.scale = _get_custom_ambient_scale_for_animation(CUSTOM_AMBIENT_KO_ANIMATION)
	_base_sprite_scale = animated_sprite.scale
	animated_sprite.play(String(CUSTOM_AMBIENT_KO_ANIMATION))
	await animated_sprite.animation_finished
	queue_free()


func set_threat_highlight(enabled: bool) -> void:
	_threat_highlight_enabled = enabled
	if not _threat_highlight_enabled and animated_sprite:
		animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		animated_sprite.scale = _base_sprite_scale


func _update_threat_highlight_visual(delta: float) -> void:
	if animated_sprite == null:
		return
	if not _threat_highlight_enabled:
		return
	_threat_highlight_time += delta
	var pulse: float = 0.5 + 0.5 * sin(_threat_highlight_time * 7.5)
	var intensity: float = lerp(1.0, 1.2, pulse)
	animated_sprite.modulate = Color(intensity, 0.72, 0.72, 1.0)
	animated_sprite.scale = _base_sprite_scale * lerp(1.0, 1.06, pulse)
