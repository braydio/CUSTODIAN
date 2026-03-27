extends CharacterBody2D
class_name EnemyDroneLegacy

const DRONE_HIT_TEXTURE_PATH := "res://assets/sprites/enemies/drone/runtime/reaction/drone_hit.png"
const DAMAGE_POPUP_SCENE := preload("res://entities/ui/damage_popup.tscn")
const DRONE_STAGGER_TEXTURE_PATH := "res://assets/sprites/enemies/drone/runtime/reaction/drone_stagger.png"
const DRONE_ATTACK_WINDUP_TEXTURE_PATH := "res://assets/sprites/enemies/drone/runtime/attack/drone_attack_windup.png"
const DRONE_FIRING_TEXTURE_PATH := "res://assets/sprites/enemies/drone/runtime/attack/drone_firing.png"
const DRONE_IDLE_TEXTURE_PATH := "res://assets/sprites/enemies/drone/runtime/idle/drone_idle.png"
const AXUL_DIRECTIONAL_SHEET_PATH := "res://assets/sprites/additional-charsets/Small-8-Direction-Characters_by_AxulArt/Small-8-Direction-Characters_by_AxulArt.png"
const DIRECTIONAL_SUFFIXES := [&"n", &"ne", &"e", &"se", &"s", &"sw", &"w", &"nw"]

@export var enemy_name: String = "DRONE"
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
@export var uses_directional_charset: bool = false
@export_file("*.png") var directional_charset_sheet_path: String = AXUL_DIRECTIONAL_SHEET_PATH
@export var directional_charset_row_start: int = 2
@export var directional_charset_frame_size: int = 16
@export var directional_charset_fps: float = 8.0
@export var directional_charset_scale: Vector2 = Vector2(1.75, 1.75)

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
	if _uses_directional_charset():
		_ensure_directional_charset_animations()
		if visual:
			visual.visible = false
		if animated_sprite:
			animated_sprite.scale = directional_charset_scale
			_base_sprite_scale = animated_sprite.scale
		_update_directional_charset_animation(_last_move_direction, false)
	elif _is_standard_drone():
		_ensure_drone_runtime_animations()
		if visual:
			visual.visible = false
		_play_animation("drone_idle")
	if animated_sprite:
		_base_sprite_scale = animated_sprite.scale
	damage_timer = damage_interval
	_refresh_target()
	update_visuals()

func _physics_process(delta):
	if dead:
		return
	_update_threat_highlight_visual(delta)
	if _update_reaction_timers(delta):
		return
	if _update_attack_windup(delta):
		return

	target_refresh_timer -= delta
	if target_refresh_timer <= 0.0 or target == null or not is_instance_valid(target) or _is_target_destroyed(target):
		target_refresh_timer = retarget_interval
		_refresh_target()

	if target:
		var direction = (target.global_position - global_position).normalized()
		var dist = global_position.distance_to(target.global_position)
		var attack_range = _get_attack_range(target)
		if dist > attack_range:
			velocity = direction * speed
			move_and_slide()
			_last_move_direction = direction if direction.length_squared() > 0.0001 else _last_move_direction
			if _uses_directional_charset():
				_update_directional_charset_animation(_last_move_direction, true)
			elif _is_standard_drone():
				_play_animation("drone_idle")
		else:
			velocity = Vector2.ZERO
			if direction.length_squared() > 0.0001:
				_last_move_direction = direction
			if _uses_directional_charset():
				_update_directional_charset_animation(_last_move_direction, false)
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
			if _is_standard_drone() and not used_strong_attack:
				used_strong_attack = true
				dealt_damage = damage * strong_attack_multiplier
				is_strong = true
			_start_attack_windup(dealt_damage, is_strong)

func _refresh_target():
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
	return best

func _is_target_destroyed(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return true
	if node.has_method("is_dead"):
		return bool(node.is_dead())
	return false

func _get_attack_range(node: Node2D) -> float:
	if node.is_in_group("player"):
		return 40.0
	return structure_attack_range

func apply_difficulty_modifiers(hp_scale: float, damage_scale: float):
	max_health = max(1.0, max_health * hp_scale)
	health = max(1.0, health * hp_scale)
	damage = max(1.0, damage * damage_scale)
	update_visuals()

func take_damage(amount: float):
	if dead:
		return
	
	health -= amount
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
	print("ENEMY DESTROYED: ", enemy_name)
	if _is_standard_drone() and _has_animation("drone_explode"):
		_play_animation("drone_explode", false)
		await animated_sprite.animation_finished
	queue_free()


func _start_attack_windup(queued_damage: float, is_strong: bool) -> void:
	_pending_attack_damage = queued_damage
	_attack_windup_timer = max(0.01, attack_windup_duration)
	_windup_attack_is_strong = is_strong
	velocity = Vector2.ZERO
	if _is_standard_drone():
		if _has_animation("drone_attack_windup"):
			_play_animation("drone_attack_windup")
		elif is_strong:
			_play_animation("drone_missiles")
		else:
			_play_animation("drone_firing")


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
	if _is_standard_drone():
		if _windup_attack_is_strong:
			_play_animation("drone_missiles")
		else:
			_play_animation("drone_firing")
	_pending_attack_damage = 0.0
	_windup_attack_is_strong = false


func _apply_reaction(amount: float) -> void:
	if amount >= stagger_damage_threshold:
		_start_stagger_reaction()
	else:
		_start_hit_recoil_reaction()


func _start_hit_recoil_reaction() -> void:
	_recoil_timer = max(_recoil_timer, hit_recoil_duration)
	if _is_standard_drone() and _has_animation("drone_hit"):
		_play_animation("drone_hit")


func _start_stagger_reaction() -> void:
	_stagger_timer = max(_stagger_timer, stagger_duration)
	_recoil_timer = 0.0
	_attack_windup_timer = 0.0
	_pending_attack_damage = 0.0
	velocity = Vector2.ZERO
	if _is_standard_drone() and _has_animation("drone_stagger"):
		_play_animation("drone_stagger")


func _spawn_damage_popup(amount: float) -> void:
	var popup := DAMAGE_POPUP_SCENE.instantiate()
	popup.text = str(int(amount))
	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-10, 10), -20)


func _update_reaction_timers(delta: float) -> bool:
	if _stagger_timer > 0.0:
		_stagger_timer = max(0.0, _stagger_timer - delta)
		velocity = Vector2.ZERO
		if _uses_directional_charset():
			_update_directional_charset_animation(_last_move_direction, false)
		return true
	if _recoil_timer > 0.0:
		_recoil_timer = max(0.0, _recoil_timer - delta)
		velocity = Vector2.ZERO
		if _uses_directional_charset():
			_update_directional_charset_animation(_last_move_direction, false)
		return true
	return false

func is_dead() -> bool:
	return dead


func _is_standard_drone() -> bool:
	return animated_sprite != null and enemy_name == "DRONE"


func _uses_directional_charset() -> bool:
	return uses_directional_charset and animated_sprite != null


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


func _ensure_drone_runtime_animations() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = animated_sprite.sprite_frames
	_replace_strip_animation(frames, "drone_idle", DRONE_IDLE_TEXTURE_PATH, 128, 7.0, true)
	_replace_strip_animation(frames, "drone_firing", DRONE_FIRING_TEXTURE_PATH, 128, 9.0, true)
	_replace_strip_animation(frames, "drone_attack_windup", DRONE_ATTACK_WINDUP_TEXTURE_PATH, 128, 10.0, false)
	_replace_strip_animation(frames, "drone_hit", DRONE_HIT_TEXTURE_PATH, 128, 12.0, false)
	_replace_strip_animation(frames, "drone_stagger", DRONE_STAGGER_TEXTURE_PATH, 128, 10.0, false)


func _replace_strip_animation(frames: SpriteFrames, animation_name: String, texture_path: String, frame_size: int, speed: float, loop: bool) -> void:
	if not ResourceLoader.exists(texture_path):
		return
	var texture: Resource = load(texture_path)
	if not (texture is Texture2D):
		return
	var tex: Texture2D = texture as Texture2D
	var safe_frame_size: int = max(1, frame_size)
	var frame_count: int = int(floor(float(tex.get_width()) / float(safe_frame_size)))
	if frame_count <= 0:
		return
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, speed)
	for i in range(frame_count):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(float(i * safe_frame_size), 0.0, float(safe_frame_size), float(safe_frame_size))
		frames.add_frame(animation_name, atlas, 1.0)


func _ensure_directional_charset_animations() -> void:
	if animated_sprite == null:
		return
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

	var frames := SpriteFrames.new()
	for dir_index in range(DIRECTIONAL_SUFFIXES.size()):
		var suffix: String = String(DIRECTIONAL_SUFFIXES[dir_index])
		var idle_name: String = "idle_%s" % suffix
		var walk_name: String = "walk_%s" % suffix
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, true)
		frames.set_animation_speed(idle_name, 1.0)
		frames.add_frame(idle_name, _build_directional_atlas(tex, dir_index, safe_row_start, safe_frame_size))

		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, directional_charset_fps)
		for frame_index in range(4):
			frames.add_frame(walk_name, _build_directional_atlas(tex, dir_index, safe_row_start + frame_index, safe_frame_size))
	animated_sprite.sprite_frames = frames


func _build_directional_atlas(texture: Texture2D, dir_index: int, row_index: int, frame_size: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(dir_index * frame_size), float(row_index * frame_size), float(frame_size), float(frame_size))
	return atlas


func _update_directional_charset_animation(direction: Vector2, is_moving: bool) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var suffix := _get_directional_charset_suffix(direction)
	var anim_name := "%s_%s" % ["walk" if is_moving else "idle", suffix]
	_play_animation(anim_name, false)


func _get_directional_charset_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var angle := wrapf(direction.angle(), 0.0, TAU)
	var sector := int(round(angle / (PI / 4.0))) % DIRECTIONAL_SUFFIXES.size()
	var angle_to_index := [2, 3, 4, 5, 6, 7, 0, 1]
	return DIRECTIONAL_SUFFIXES[angle_to_index[sector]]


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
