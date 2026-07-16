extends Camera2D
class_name CameraController

## CUSTODIAN Camera System
## Readability → Weight → Immersion
##
## Features:
## - Lookahead (leads player movement)
## - Smooth follow with weight
## - Micro bob while moving
## - Off-center framing
## - Combat state machine
## - Attack reactions synced to frames
## - Screen shake system

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# Base Settings
@export_group("Base")
@export var base_zoom: Vector2 = Vector2(0.84, 0.84)
@export var follow_enabled: bool = true
@export var follow_lerp_speed: float = 8.0  # Godot uses different lerp (higher = faster)

# Zoom Profiles
@export_group("Zoom Profiles")
@export var move_zoom: Vector2 = Vector2(0.90, 0.90)
@export var interaction_zoom: Vector2 = Vector2(0.78, 0.78)
@export var melee_zoom: Vector2 = Vector2(0.80, 0.80)
@export var melee_move_zoom: Vector2 = Vector2(0.84, 0.84)
@export var ranged_zoom: Vector2 = Vector2(0.90, 0.90)
@export var ranged_move_zoom: Vector2 = Vector2(0.94, 0.94)
@export var hitstun_zoom: Vector2 = Vector2(0.88, 0.88)
@export var sector_entry_zoom: Vector2 = Vector2(0.90, 0.90)
@export var auto_zoom_enabled: bool = true

# Lookahead
@export_group("Lookahead")
@export var lookahead_enabled: bool = true
@export var lookahead_strength: float = 40.0  # pixels
@export var lookahead_damping: float = 0.15

@export_group("Ranged Aim Camera")
@export var ranged_aim_camera_enabled: bool = true
@export var ranged_aim_zoom_multiplier: float = 1.07
@export var ranged_aim_camera_lead_px: float = 32.0
@export var ranged_aim_camera_enter_sec: float = 0.22
@export var ranged_aim_camera_exit_sec: float = 0.13
@export var ranged_aim_camera_lead_smoothing: float = 12.0
@export var ranged_aim_reticle_emphasis: float = 1.15

# Micro Bob
@export_group("Micro Bob")
@export var bob_enabled: bool = true
@export var bob_strength: float = 2.0
@export var bob_frequency: float = 0.005
@export var bob_decay_speed: float = 8.0

# Off-Center
@export_group("Off-Center")
@export var player_offset: Vector2 = Vector2(0, -52)  # Push player lower on screen

# Combat Reactions
@export_group("Combat")
@export var attack_push_light: float = 10.0
@export var attack_push_heavy: float = 20.0
@export var heavy_zoom: Vector2 = Vector2(0.74, 0.74)
@export var zoom_transition_speed: float = 3.0
@export var combat_state_hold_time: float = 0.18
@export var heavy_state_hold_time: float = 0.22
@export var hitstun_state_hold_time: float = 0.30

# Screen Shake
@export_group("Shake")
@export var max_shake_offset: float = 12.0
@export var shake_decay_speed: float = 20.0
@export var shake_multiplier: float = 1.0

# Threat Framing
@export_group("Threat Framing")
@export var threat_framing_enabled: bool = true
@export var threat_scan_radius: float = 560.0
@export var threat_offset_strength: float = 26.0
@export var threat_offset_damping: float = 0.10

# Map Bounds
@export_group("Map")
@export var map_padding: float = 200.0
@export var edge_view_slack_ratio: float = 0.35

# Zoom Limits
@export_group("Zoom")
@export var min_zoom: Vector2 = Vector2(0.1, 0.1)
@export var max_zoom: Vector2 = Vector2(1.5, 1.5)
@export var zoom_step: float = 1.1

# ═══════════════════════════════════════════════════════════════════════════════
# ENUMS
# ═══════════════════════════════════════════════════════════════════════════════

enum CameraState {
	EXPLORE,       # Normal walking
	COMBAT,        # In active combat
	HEAVY_ATTACK, # Windup/heavy attack
	HITSTUN,       # Player took damage
	SECTOR_ENTRY,  # Entering new sector
	IDLE           # Standing still
}

# ═══════════════════════════════════════════════════════════════════════════════
# VARIABLES
# ═══════════════════════════════════════════════════════════════════════════════

# State
var current_state: CameraState = CameraState.EXPLORE
var target_zoom: Vector2

# References
var operator_ref: Node2D = null
var follow_target: Node2D = null
var _runtime_map: Node = null
var map_bounds := Rect2()

# Movement
var _velocity: Vector2 = Vector2.ZERO
var _last_position: Vector2 = Vector2.ZERO

# Lookahead
var _lookahead: Vector2 = Vector2.ZERO
var _ranged_aim_camera_active: bool = false
var _ranged_aim_camera_direction: Vector2 = Vector2.RIGHT
var _current_aim_zoom_multiplier: float = 1.0
var _current_aim_camera_lead: Vector2 = Vector2.ZERO

# Micro Bob
var _current_bob: float = 0.0
var _target_bob: float = 0.0

# Shake
var _shake_power: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _shake_decay_rate: float = 0.0

# Combat Push
var _push_offset: Vector2 = Vector2.ZERO
var _push_decay: float = 10.0

# Threat Framing
var _threat_offset: Vector2 = Vector2.ZERO

# Transient State Lock
var _state_hold_remaining: float = 0.0
var _held_state: CameraState = CameraState.EXPLORE

# Zoom Tween
var _zoom_tween: Tween = null
var _locked_zoom: Vector2 = base_zoom

# Input
var dragging := false
var drag_start := Vector2.ZERO

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	add_to_group("camera")

	# Initialize
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	zoom = base_zoom
	target_zoom = base_zoom
	_locked_zoom = base_zoom
	
	# Find operator
	operator_ref = get_node_or_null("/root/GameRoot/World/Operator")
	follow_target = operator_ref
	_last_position = global_position
	
	# Rebuild bounds after delay
	await get_tree().create_timer(0.5).timeout
	_rebuild_bounds()


func _process(delta):
	_restore_follow_on_player_movement()
	_update_movement(delta)
	_update_state_machine(delta)
	_refresh_contextual_zoom()
	_update_ranged_aim_camera(delta)
	target_zoom = (target_zoom * _current_aim_zoom_multiplier).clamp(min_zoom, max_zoom)
	_update_lookahead(delta)
	_update_threat_offset(delta)
	_update_bob(delta)
	_update_shake(delta)
	_update_push(delta)
	_update_zoom(delta)
	_apply_camera_position(delta)
	_clamp_to_bounds()


func _unhandled_input(event):
	if _is_terminal_open():
		dragging = false
		return
	
	# Toggle tracking / auto zoom
	if event.is_action_pressed("camera_follow_toggle"):
		toggle_follow()

	if event.is_action_pressed("camera_auto_zoom_toggle"):
		toggle_auto_zoom()
	
	# Middle mouse - pan
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				drag_start = event.position
				dragging = true
				follow_enabled = false
			else:
				dragging = false
	
	if event is InputEventMouseMotion and dragging:
		var diff = drag_start - event.position
		global_position += diff * 1.0
		drag_start = event.position
	
	# Scroll wheel - zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()


# ═══════════════════════════════════════════════════════════════════════════════
# MOVEMENT & STATE
# ═══════════════════════════════════════════════════════════════════════════════

func _update_movement(delta: float):
	var target := _get_follow_target()
	if target == null:
		return
	
	# Calculate velocity
	var new_pos = target.global_position
	_velocity = (new_pos - _last_position) / delta
	_last_position = new_pos


func _update_state_machine(delta: float):
	if _get_follow_target() == null:
		return

	if _state_hold_remaining > 0.0:
		_state_hold_remaining = max(0.0, _state_hold_remaining - delta)
		set_state(_held_state)
		return

	var is_moving = _velocity.length_squared() > 100.0  # Moving if velocity > 10
	var heavy_anticipating := _get_operator_bool("_melee_heavy_anticipating")
	var melee_active := _get_operator_bool("_melee_active")
	var block_active := _get_operator_bool("_block_active")
	var fire_cooldown := _get_operator_float("fire_cooldown_remaining")
	var in_combat := heavy_anticipating or melee_active or block_active or fire_cooldown > 0.03

	if heavy_anticipating:
		set_state(CameraState.HEAVY_ATTACK)
	elif in_combat:
		set_state(CameraState.COMBAT)
	elif is_moving:
		set_state(CameraState.EXPLORE)
	else:
		set_state(CameraState.IDLE)


func _refresh_contextual_zoom() -> void:
	if not auto_zoom_enabled:
		target_zoom = _locked_zoom.clamp(min_zoom, max_zoom)
		return

	match current_state:
		CameraState.EXPLORE, CameraState.IDLE:
			target_zoom = _get_noncombat_zoom()
		CameraState.COMBAT:
			target_zoom = _get_combat_zoom()
		CameraState.HEAVY_ATTACK:
			target_zoom = heavy_zoom
		CameraState.HITSTUN:
			target_zoom = hitstun_zoom
		CameraState.SECTOR_ENTRY:
			target_zoom = sector_entry_zoom


func _get_noncombat_zoom() -> Vector2:
	if _has_interaction_focus():
		return interaction_zoom

	var loadout_mode := _get_operator_loadout_mode()
	var is_moving := _velocity.length_squared() > 100.0
	match loadout_mode:
		"ranged":
			return ranged_move_zoom if is_moving else ranged_zoom
		"melee":
			return melee_move_zoom if is_moving else melee_zoom
		_:
			return move_zoom if is_moving else base_zoom


func _get_combat_zoom() -> Vector2:
	var loadout_mode := _get_operator_loadout_mode()
	if loadout_mode == "ranged":
		return ranged_zoom
	if loadout_mode == "melee":
		return melee_zoom
	return base_zoom


func _get_operator_loadout_mode() -> String:
	if operator_ref == null:
		return ""
	return String(operator_ref.get("combat_loadout_mode"))


func _has_interaction_focus() -> bool:
	if _is_terminal_open():
		return true
	if operator_ref == null:
		return false
	if operator_ref.has_method("get_interaction_prompt"):
		return not String(operator_ref.call("get_interaction_prompt")).is_empty()
	return operator_ref.get("interaction_target") != null


func _update_lookahead(delta: float):
	if not lookahead_enabled or _get_follow_target() == null:
		_lookahead = Vector2.ZERO
		return
	
	# Target lookahead based on velocity
	var target_lookahead = _velocity.normalized() * lookahead_strength
	
	# Smooth lookahead
	_lookahead = _lookahead.lerp(target_lookahead, lookahead_damping)


func set_ranged_aim_camera_active(active: bool, direction: Vector2) -> void:
	_ranged_aim_camera_active = active and ranged_aim_camera_enabled
	if direction.length_squared() > 0.0001:
		_ranged_aim_camera_direction = direction.normalized()


func _update_ranged_aim_camera(delta: float) -> void:
	var target_multiplier := ranged_aim_zoom_multiplier if _ranged_aim_camera_active else 1.0
	var response := ranged_aim_camera_enter_sec if _ranged_aim_camera_active else ranged_aim_camera_exit_sec
	var zoom_weight := 1.0 - exp(-delta / maxf(response, 0.001))
	_current_aim_zoom_multiplier = lerpf(_current_aim_zoom_multiplier, target_multiplier, zoom_weight)
	var target_lead := _ranged_aim_camera_direction * ranged_aim_camera_lead_px if _ranged_aim_camera_active else Vector2.ZERO
	var lead_weight := 1.0 - exp(-ranged_aim_camera_lead_smoothing * delta)
	_current_aim_camera_lead = _current_aim_camera_lead.lerp(target_lead, lead_weight)


func _update_bob(delta: float):
	if not bob_enabled or _get_follow_target() == null:
		_current_bob = 0.0
		return
	
	var is_moving = _velocity.length_squared() > 100.0
	var in_combat = current_state == CameraState.COMBAT or current_state == CameraState.HEAVY_ATTACK
	
	# No bob during combat
	if in_combat:
		_target_bob = 0.0
	else:
		if is_moving:
			_target_bob = sin(Time.get_ticks_msec() * bob_frequency) * bob_strength
		else:
			_target_bob = 0.0
	
	# Smooth bob
	_current_bob = lerp(_current_bob, _target_bob, bob_decay_speed * delta)


func _update_threat_offset(delta: float):
	var target := _get_follow_target()
	if not threat_framing_enabled or target == null or current_state == CameraState.IDLE:
		_threat_offset = _threat_offset.lerp(Vector2.ZERO, threat_offset_damping)
		return

	var threat_center := Vector2.ZERO
	var threat_count := 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D):
			continue
		if enemy == operator_ref:
			continue
		if enemy.has_method("is_passive_enemy") and enemy.is_passive_enemy():
			continue
		var enemy_node := enemy as Node2D
		var to_enemy := enemy_node.global_position - target.global_position
		if to_enemy.length() > threat_scan_radius:
			continue
		threat_center += enemy_node.global_position
		threat_count += 1

	var target_offset := Vector2.ZERO
	if threat_count > 0:
		threat_center /= float(threat_count)
		var bias = threat_center - target.global_position
		if bias.length_squared() > 0.001:
			target_offset = bias.normalized() * min(threat_offset_strength, bias.length() * 0.20)

	_threat_offset = _threat_offset.lerp(target_offset, threat_offset_damping)


func _update_shake(delta: float):
	if _shake_power <= 0.0:
		_shake_offset = Vector2.ZERO
		_shake_decay_rate = 0.0
		return

	_shake_offset = Vector2(
		randf_range(-_shake_power, _shake_power),
		randf_range(-_shake_power, _shake_power)
	)
	var decay_rate := _shake_decay_rate if _shake_decay_rate > 0.0 else shake_decay_speed
	_shake_power = max(0.0, _shake_power - decay_rate * delta)


func _update_push(delta: float):
	# Decay push offset
	_push_offset = _push_offset.lerp(Vector2.ZERO, _push_decay * delta)


func _update_zoom(delta: float):
	# Smooth zoom transition
	if zoom != target_zoom:
		zoom = zoom.lerp(target_zoom, zoom_transition_speed * delta)


func _apply_camera_position(delta: float):
	var target := _get_follow_target()
	if not follow_enabled or target == null:
		return
	
	# Calculate target position
	var target_pos = target.global_position
	
	# Add offset (off-center)
	target_pos += player_offset
	
	# Add lookahead
	target_pos += _lookahead

	# Aim lead composes with movement, threat framing, push, and shake.
	target_pos += _current_aim_camera_lead

	# Bias framing slightly toward nearby threats during combat.
	target_pos += _threat_offset

	# Add bob
	target_pos.y += _current_bob
	
	# Apply lerp for smooth follow (Godot's smoothing is different)
	var lerp_factor = clamp(follow_lerp_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target_pos, lerp_factor)
	
	# Apply shake and push
	global_position += _shake_offset + _push_offset


func _restore_follow_on_player_movement() -> void:
	if follow_enabled or dragging:
		return
	if Input.is_action_pressed("move_left") \
		or Input.is_action_pressed("move_right") \
		or Input.is_action_pressed("move_up") \
		or Input.is_action_pressed("move_down"):
		set_follow_target(_get_follow_target())


# ═══════════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

func set_state(new_state: CameraState):
	if current_state == new_state:
		return
	
	current_state = new_state
	
	match new_state:
		CameraState.EXPLORE:
			follow_lerp_speed = 8.0
			player_offset = Vector2(0, -52)
		
		CameraState.COMBAT:
			follow_lerp_speed = 10.0  # More responsive
			player_offset = Vector2(0, -40)  # Less offset
		
		CameraState.HEAVY_ATTACK:
			target_zoom = heavy_zoom
			follow_lerp_speed = 6.0  # Slower = weight
			player_offset = Vector2(0, -32)
			_current_bob = 0.0  # Stop bob
		
		CameraState.HITSTUN:
			target_zoom = hitstun_zoom
			follow_lerp_speed = 12.0  # Fast follow
			player_offset = Vector2(0, -60)
			_current_bob = 0.0

		CameraState.SECTOR_ENTRY:
			target_zoom = sector_entry_zoom
			follow_lerp_speed = 6.0
			player_offset = Vector2(0, -52)
			_current_bob = 0.0

		CameraState.IDLE:
			follow_lerp_speed = 6.0
			player_offset = Vector2(0, -52)


# ═══════════════════════════════════════════════════════════════════════════════
# COMBAT REACTIONS
# ═══════════════════════════════════════════════════════════════════════════════

func apply_attack_push(direction: Vector2, is_heavy: bool = false):
	var push_strength = attack_push_heavy if is_heavy else attack_push_light
	_push_offset += direction.normalized() * push_strength


func apply_shake(power: float = 1.0, duration: float = 0.12):
	var actual_power = power * shake_multiplier
	_shake_power = min(_shake_power + actual_power, max_shake_offset)
	_shake_decay_rate = max(_shake_decay_rate, actual_power / max(duration, 0.01))


func shake(power: float = 1.0, duration: float = 0.12):
	apply_shake(power, duration)


func on_attack_windup(is_heavy: bool = false):
	_hold_state(CameraState.HEAVY_ATTACK if is_heavy else CameraState.COMBAT, heavy_state_hold_time if is_heavy else combat_state_hold_time)


func on_attack_impact(direction: Vector2, is_heavy: bool = false):
	apply_attack_push(direction, is_heavy)
	apply_shake(3.2 if is_heavy else 1.8, 0.15 if is_heavy else 0.08)
	_hold_state(CameraState.HEAVY_ATTACK if is_heavy else CameraState.COMBAT, 0.12 if is_heavy else 0.08)


func on_damage_taken(hit_direction: Vector2):
	_hold_state(CameraState.HITSTUN, hitstun_state_hold_time)
	apply_shake(5.0, 0.18)
	_push_offset += hit_direction.normalized() * 15.0


func on_enemy_killed():
	apply_shake(2.0, 0.10)


func on_sector_entry():
	_hold_state(CameraState.SECTOR_ENTRY, 0.45)


func _hold_state(state: CameraState, duration: float):
	_held_state = state
	_state_hold_remaining = max(_state_hold_remaining, duration)
	set_state(state)


func _get_operator_bool(property_name: String) -> bool:
	if operator_ref == null:
		return false
	return bool(operator_ref.get(property_name))


func _get_operator_float(property_name: String) -> float:
	if operator_ref == null:
		return 0.0
	var value = operator_ref.get(property_name)
	if value == null:
		return 0.0
	return float(value)


# ═══════════════════════════════════════════════════════════════════════════════
# ZOOM CONTROLS
# ═══════════════════════════════════════════════════════════════════════════════

func zoom_in():
	var source_zoom := _locked_zoom if not auto_zoom_enabled else zoom
	var new_zoom = source_zoom * zoom_step
	new_zoom = new_zoom.clamp(min_zoom, max_zoom)
	_locked_zoom = new_zoom
	if not auto_zoom_enabled:
		target_zoom = new_zoom


func zoom_out():
	var source_zoom := _locked_zoom if not auto_zoom_enabled else zoom
	var new_zoom = source_zoom / zoom_step
	new_zoom = new_zoom.clamp(min_zoom, max_zoom)
	_locked_zoom = new_zoom
	if not auto_zoom_enabled:
		target_zoom = new_zoom


func set_target_zoom(new_zoom: Vector2, duration: float = 0.3):
	target_zoom = new_zoom.clamp(min_zoom, max_zoom)
	
	if _zoom_tween:
		_zoom_tween.kill()
	
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "zoom", target_zoom, duration)


func reset_zoom():
	set_target_zoom(base_zoom, 0.3)
	_locked_zoom = base_zoom


# ═══════════════════════════════════════════════════════════════════════════════
# MAP BOUNDS
# ═══════════════════════════════════════════════════════════════════════════════

func set_runtime_map(map_instance: Node) -> void:
	if not is_in_group("camera"):
		add_to_group("camera")
	if operator_ref == null or not is_instance_valid(operator_ref):
		operator_ref = get_node_or_null("/root/GameRoot/World/Operator")
	if follow_target == null or not is_instance_valid(follow_target):
		follow_target = operator_ref
	_runtime_map = map_instance
	_rebuild_bounds()
	on_sector_entry()
	if follow_enabled and operator_ref:
		snap_to_player_spawn(operator_ref.global_position)


func snap_to_player_spawn(spawn_position: Vector2) -> void:
	global_position = spawn_position + player_offset
	_last_position = spawn_position
	_velocity = Vector2.ZERO
	_lookahead = Vector2.ZERO
	_current_bob = 0.0
	_target_bob = 0.0
	_threat_offset = Vector2.ZERO
	_push_offset = Vector2.ZERO
	_shake_offset = Vector2.ZERO
	_ranged_aim_camera_active = false
	_current_aim_zoom_multiplier = 1.0
	_current_aim_camera_lead = Vector2.ZERO


func get_ranged_aim_camera_snapshot() -> Dictionary:
	return {
		"active": _ranged_aim_camera_active,
		"direction": _ranged_aim_camera_direction,
		"zoom_multiplier": _current_aim_zoom_multiplier,
		"lead": _current_aim_camera_lead,
	}


func _rebuild_bounds():
	var world_loader = get_tree().get_first_node_in_group("contract_world_loader")
	if world_loader != null:
		if world_loader.has_method("is_contract_activation_aborted") and bool(world_loader.call("is_contract_activation_aborted")):
			map_bounds = Rect2()
			return
		if world_loader.has_method("is_contract_world_pending") and bool(world_loader.call("is_contract_world_pending")):
			map_bounds = Rect2()
			return
	if not _rebuild_bounds_from_connected_map() and not _rebuild_bounds_from_procgen():
		map_bounds = Rect2()
		push_warning("[Camera] Map bounds rebuild failed; disabling camera clamp for this session")


func _rebuild_bounds_from_connected_map() -> bool:
	var map_instance: Node = _runtime_map
	if map_instance == null or not map_instance.has_method("get_camera_bounds"):
		return false
	var bounds_variant: Variant = map_instance.call("get_camera_bounds")
	if not (bounds_variant is Rect2):
		return false
	var bounds := bounds_variant as Rect2
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return false
	map_bounds = bounds.grow(map_padding)
	return true


func _rebuild_bounds_from_procgen() -> bool:
	var map_instance: Node = _runtime_map
	if map_instance == null:
		map_instance = get_node_or_null("/root/GameRoot/World/ProcGenRuntime/ProcGenMap")
	if not (map_instance is ProcGenTilemap):
		return false
	
	var procgen_map := map_instance as ProcGenTilemap
	if procgen_map.floor_tilemap == null or procgen_map.procgen_node == null:
		return false
	
	var tilemap: TileMapLayer = procgen_map.floor_tilemap
	var map_size: Vector2i = procgen_map.procgen_node.map_size
	if map_size.x <= 0 or map_size.y <= 0:
		return false
	
	var corners := [
		tilemap.to_global(tilemap.map_to_local(Vector2i(0, 0))),
		tilemap.to_global(tilemap.map_to_local(Vector2i(map_size.x - 1, 0))),
		tilemap.to_global(tilemap.map_to_local(Vector2i(0, map_size.y - 1))),
		tilemap.to_global(tilemap.map_to_local(Vector2i(map_size.x - 1, map_size.y - 1))),
	]
	
	var min_point = Vector2(INF, INF)
	var max_point = Vector2(-INF, -INF)
	for p in corners:
		min_point.x = min(min_point.x, p.x)
		min_point.y = min(min_point.y, p.y)
		max_point.x = max(max_point.x, p.x)
		max_point.y = max(max_point.y, p.y)
	
	var half_cell := tilemap.tile_set.tile_size * 0.5
	min_point -= half_cell + Vector2(map_padding, map_padding)
	max_point += half_cell + Vector2(map_padding, map_padding)
	map_bounds = Rect2(min_point, max_point - min_point)
	return true


func _clamp_to_bounds():
	if map_bounds.size.x <= 0.0 or map_bounds.size.y <= 0.0:
		return
	var viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	
	var zoom_factor = clamp(zoom.x, 0.3, 1.0)
	var half_view = viewport_size * 0.5 * zoom_factor
	var slack_ratio = clamp(edge_view_slack_ratio, 0.0, 0.95)
	var clamp_half_view = half_view * (1.0 - slack_ratio)
	
	var x_min = map_bounds.position.x + clamp_half_view.x
	var x_max = map_bounds.position.x + map_bounds.size.x - clamp_half_view.x
	var y_min = map_bounds.position.y + clamp_half_view.y
	var y_max = map_bounds.position.y + map_bounds.size.y - clamp_half_view.y
	
	if x_min > x_max:
		global_position.x = map_bounds.position.x + map_bounds.size.x * 0.5
	else:
		global_position.x = clamp(global_position.x, x_min, x_max)
	
	if y_min > y_max:
		global_position.y = map_bounds.position.y + map_bounds.size.y * 0.5
	else:
		global_position.y = clamp(global_position.y, y_min, y_max)


# ═══════════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

func _is_terminal_open() -> bool:
	var ui = get_node_or_null("/root/GameRoot/UI")
	if ui and ui.has_method("is_terminal_open"):
		return bool(ui.is_terminal_open())
	return false


func get_current_state() -> CameraState:
	return current_state


func is_following() -> bool:
	return follow_enabled


func toggle_follow():
	follow_enabled = !follow_enabled
	print("CAMERA FOLLOW: ", "ON" if follow_enabled else "OFF")
	if follow_enabled:
		dragging = false
		var target := _get_follow_target()
		if target != null:
			global_position = target.global_position + player_offset


func set_follow_target(target: Node2D) -> void:
	if target == null:
		follow_target = operator_ref
	else:
		follow_target = target
	follow_enabled = true
	_last_position = follow_target.global_position if follow_target != null else global_position
	_velocity = Vector2.ZERO
	_lookahead = Vector2.ZERO
	_threat_offset = Vector2.ZERO


func _get_follow_target() -> Node2D:
	if follow_target != null and is_instance_valid(follow_target):
		return follow_target
	if operator_ref == null or not is_instance_valid(operator_ref):
		operator_ref = get_node_or_null("/root/GameRoot/World/Operator")
	follow_target = operator_ref
	return follow_target


func is_auto_zoom_enabled() -> bool:
	return auto_zoom_enabled


func toggle_auto_zoom():
	auto_zoom_enabled = !auto_zoom_enabled
	if auto_zoom_enabled:
		print("CAMERA AUTO ZOOM: ON")
	else:
		_locked_zoom = zoom
		target_zoom = _locked_zoom
		print("CAMERA AUTO ZOOM: LOCKED @ ", _locked_zoom)
