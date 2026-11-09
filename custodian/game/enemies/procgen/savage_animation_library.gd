extends RefCounted
class_name SavageAnimationLibrary

## Nearest-available-sector projection for Savage's sparse idle/move art (idle
## authors e/n/s/se/sw/w, move authors only e/w). Inlined from the retired
## shared `DirectionalAnimationFallback` when Operator C2b deleted it as the
## armed/dodge nearest-sector search became dead there; this was the one
## surviving non-Operator consumer of the same algorithm.
const SECTOR_ORDER: Array[StringName] = [
	&"n", &"ne", &"e", &"se", &"s", &"sw", &"w", &"nw",
]
const _TIE_ORDER: Array[StringName] = [
	&"s", &"n", &"e", &"w", &"se", &"sw", &"ne", &"nw",
]
const _SECTOR_VECTORS := {
	&"n": Vector2.UP,
	&"ne": Vector2(0.70710678, -0.70710678),
	&"e": Vector2.RIGHT,
	&"se": Vector2(0.70710678, 0.70710678),
	&"s": Vector2.DOWN,
	&"sw": Vector2(-0.70710678, 0.70710678),
	&"w": Vector2.LEFT,
	&"nw": Vector2(-0.70710678, -0.70710678),
}


static func _vector_to_sector(direction: Vector2, default_sector: StringName = &"s") -> StringName:
	if direction.length_squared() <= 0.0001:
		return default_sector
	var angle := wrapf(direction.angle(), 0.0, TAU)
	var sector_index := int(round(angle / (PI / 4.0))) % 8
	var angle_order: Array[StringName] = [
		&"e", &"se", &"s", &"sw", &"w", &"nw", &"n", &"ne",
	]
	return angle_order[sector_index]


static func _nearest_available_sector(
	requested_sector: StringName,
	available_sectors: Array[StringName],
	previous_sector: StringName = &""
) -> StringName:
	if available_sectors.is_empty():
		return &""
	if available_sectors.has(requested_sector):
		return requested_sector
	var requested_vector: Vector2 = _SECTOR_VECTORS.get(requested_sector, _SECTOR_VECTORS[&"s"])
	var best_dot := -INF
	var tied: Array[StringName] = []
	for candidate: StringName in available_sectors:
		if not _SECTOR_VECTORS.has(candidate):
			continue
		var candidate_vector: Vector2 = _SECTOR_VECTORS[candidate]
		var candidate_dot := requested_vector.dot(candidate_vector)
		if candidate_dot > best_dot + 0.0001:
			best_dot = candidate_dot
			tied.assign([candidate])
		elif is_equal_approx(candidate_dot, best_dot):
			tied.append(candidate)
	if tied.is_empty():
		return &""
	if tied.has(previous_sector):
		return previous_sector
	for candidate: StringName in _TIE_ORDER:
		if tied.has(candidate):
			return candidate
	return tied[0]

const ANIMATION_SPECS := {
	"idle_e": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__e__9f__128.png",
		"frame_size": Vector2i(128, 128),
		"fps": 6.0,
		"loop": true,
	},
	"idle_n": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__n__5f__96.png",
		"frame_size": Vector2i(96, 96),
		"fps": 6.0,
		"loop": true,
	},
	"idle_s": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__s__9f__95.png",
		"frame_size": Vector2i(95, 95),
		"fps": 6.0,
		"loop": true,
	},
	"idle_se": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__se__5f__96.png",
		"frame_size": Vector2i(96, 96),
		"fps": 6.0,
		"loop": true,
	},
	"idle_sw": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__sw__4f__96.png",
		"frame_size": Vector2i(96, 96),
		"fps": 6.0,
		"loop": true,
	},
	"idle_w": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__idle_01__w__9f__128.png",
		"frame_size": Vector2i(128, 128),
		"fps": 6.0,
		"loop": true,
	},
	"move_e": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__run_01__e__8f__96.png",
		"frame_size": Vector2i(96, 96),
		"fps": 10.0,
		"loop": true,
	},
	"move_w": {
		"path": "res://content/sprites/enemies/enemy_savage/runtime/body/locomotion/enemy_savage__body__locomotion__run_01__w__8f__96.png",
		"frame_size": Vector2i(96, 96),
		"fps": 10.0,
		"loop": true,
	},
}

static var _cached_frames: SpriteFrames = null


static func get_savage_sprite_frames() -> SpriteFrames:
	if _cached_frames != null:
		return _cached_frames
	var frames := SpriteFrames.new()
	for animation_name in ANIMATION_SPECS:
		_add_strip_animation(frames, String(animation_name), ANIMATION_SPECS[animation_name])
	_cached_frames = frames
	return _cached_frames


static func get_idle_animation(direction: Vector2) -> StringName:
	var requested_sector := _vector_to_sector(direction)
	var resolved_sector := _nearest_available_sector(
		requested_sector,
		_get_available_sectors("idle_")
	)
	return (
		StringName("idle_%s" % String(resolved_sector))
		if not resolved_sector.is_empty()
		else &""
	)


static func get_movement_animation(
	direction: Vector2,
	previous_sector: StringName = &""
) -> StringName:
	var requested_sector := _vector_to_sector(direction)
	var resolved_sector := _nearest_available_sector(
		requested_sector,
		_get_available_sectors("move_"),
		previous_sector
	)
	return (
		StringName("move_%s" % String(resolved_sector))
		if not resolved_sector.is_empty()
		else &""
	)


static func _add_strip_animation(frames: SpriteFrames, animation_name: String, spec: Dictionary) -> void:
	var path := String(spec["path"])
	if not ResourceLoader.exists(path):
		push_warning("[SavageAnimationLibrary] Missing savage sheet: %s" % path)
		return
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("[SavageAnimationLibrary] Savage sheet is not a Texture2D: %s" % path)
		return
	var frame_size: Vector2i = spec["frame_size"]
	if texture.get_height() != frame_size.y or texture.get_width() % frame_size.x != 0:
		push_warning("[SavageAnimationLibrary] Savage sheet has unexpected dimensions: %s" % path)
		return
	var frame_count := int(texture.get_width() / frame_size.x)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, bool(spec.get("loop", true)))
	frames.set_animation_speed(animation_name, float(spec.get("fps", 6.0)))
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(float(frame_index * frame_size.x), 0.0, float(frame_size.x), float(frame_size.y))
		frames.add_frame(animation_name, atlas)

static func _get_available_sectors(prefix: String) -> Array[StringName]:
	var sectors: Array[StringName] = []
	for sector: StringName in SECTOR_ORDER:
		if ANIMATION_SPECS.has("%s%s" % [prefix, String(sector)]):
			sectors.append(sector)
	return sectors
