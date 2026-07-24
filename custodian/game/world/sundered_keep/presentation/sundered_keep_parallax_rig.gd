@tool
extends Node2D
class_name SunderedKeepParallaxRig


enum Profile {
	VISTA_APPROACH,
	RETURN_CAUSEWAY,
}


const SOFT_RECT_FEATHER_SHADER := preload(
	"res://game/world/approaches/sundered_keep/soft_rect_feather.gdshader"
)

const FAR_CLIFF_ISLANDS_PATH := \
	"res://content/backgrounds/sundered_keep/approach/parallax/far_cliff_islands.png"
const LOWER_CLIFF_DEPTH_PATH := \
	"res://content/backgrounds/sundered_keep/approach/parallax/lower_cliff_depth.png"
const CAUSEWAY_FAR_ARCHES_PATH := \
	"res://content/backgrounds/sundered_keep/approach/parallax/causeway_far_arches.png"
const OCEAN_MIST_LEFT_PATH := \
	"res://content/backgrounds/sundered_keep/approach/parallax/ocean_mist_strip_left.png"
const OCEAN_MIST_RIGHT_PATH := \
	"res://content/backgrounds/sundered_keep/approach/parallax/ocean_mist_strip_right.png"
const NEAR_MIST_LEFT_PATH := \
	"res://content/backgrounds/sundered_keep/approach/parallax/near_edge_mist_left.png"
const NEAR_MIST_RIGHT_PATH := \
	"res://content/backgrounds/sundered_keep/approach/parallax/near_edge_mist_right.png"
const FOREGROUND_ARCH_PATH := \
	"res://content/backgrounds/sundered_keep/approach/parallax/foreground_ruined_arch.png"

const DISTANT_KEEP_PATH := \
	"res://content/backgrounds/sundered_keep/distant_sundered_keep.png"

const STRIP_OVERLAP_PX := 96.0

@export_group("Layer Review Gates")
@export var show_far_cliff_islands := false
@export var show_causeway_far_arches := false
@export var show_lower_cliff_depth := false
@export var show_ocean_mist := false
@export var show_near_edge_mist := false
@export var show_foreground_ruined_arch := false

var _texture_cache: Dictionary = {}
var _drift_layers: Array[Dictionary] = []
var _drift_time := 0.0
var _missing_assets := 0


func _ready() -> void:
	z_as_relative = false
	z_index = 0
	set_process(not Engine.is_editor_hint())


func build(p_profile: int, world_rect: Rect2) -> void:
	_clear_runtime_children()
	_drift_layers.clear()
	_drift_time = 0.0
	_missing_assets = 0

	z_as_relative = false
	z_index = 0
	set_meta("parallax_profile", p_profile)
	set_meta("coverage_rect", world_rect)
	set_meta("layer_review_state", get_layer_review_state())

	var base_root := _make_group("BaseDepth", 1.0)
	var reveal_root := _make_group(
		"RevealDepth",
		0.0 if p_profile == Profile.VISTA_APPROACH else 1.0
	)
	var foreground_root := _make_group(
		"ForegroundDepth",
		0.55 if p_profile == Profile.VISTA_APPROACH else 1.0
	)

	match p_profile:
		Profile.VISTA_APPROACH:
			_build_vista_approach(
				base_root,
				reveal_root,
				foreground_root,
				world_rect
			)
		Profile.RETURN_CAUSEWAY:
			_build_return_causeway(
				base_root,
				reveal_root,
				foreground_root,
				world_rect
			)
		_:
			push_error(
				"[SunderedKeepParallaxRig] Unknown profile: %s" % p_profile
			)


func get_missing_asset_count() -> int:
	return _missing_assets


func get_layer_review_state() -> Dictionary:
	return {
		"far_cliff_islands": show_far_cliff_islands,
		"causeway_far_arches": show_causeway_far_arches,
		"lower_cliff_depth": show_lower_cliff_depth,
		"ocean_mist": show_ocean_mist,
		"near_edge_mist": show_near_edge_mist,
		"foreground_ruined_arch": show_foreground_ruined_arch,
	}


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_drift_time += maxf(delta, 0.0)

	for entry in _drift_layers:
		var layer := entry.get("node") as Parallax2D
		if layer == null or not is_instance_valid(layer):
			continue

		var amplitude := entry.get("amplitude", Vector2.ZERO) as Vector2
		var speed := entry.get("speed", Vector2.ONE) as Vector2

		layer.scroll_offset = Vector2(
			sin(_drift_time * speed.x) * amplitude.x,
			cos(_drift_time * speed.y) * amplitude.y
		)


func _build_vista_approach(
	base_root: Node2D,
	reveal_root: Node2D,
	foreground_root: Node2D,
	world_rect: Rect2
) -> void:
	var padded := world_rect.grow(128.0)
	var world_end := world_rect.position + world_rect.size

	var far_cliffs_rect := Rect2(
		Vector2(padded.position.x, world_rect.position.y + 80.0),
		Vector2(padded.size.x, 1100.0)
	)
	var arches_rect := Rect2(
		Vector2(padded.position.x + 100.0, world_rect.position.y + 160.0),
		Vector2(padded.size.x - 80.0, 1050.0)
	)
	var lower_cliffs_rect := Rect2(
		Vector2(padded.position.x, world_rect.position.y + 360.0),
		Vector2(padded.size.x, 1500.0)
	)
	var ocean_mist_rect := Rect2(
		Vector2(padded.position.x, world_rect.position.y + 720.0),
		Vector2(padded.size.x, 600.0)
	)
	var near_mist_rect := Rect2(
		Vector2(padded.position.x, world_rect.position.y + 980.0),
		Vector2(padded.size.x, 600.0)
	)
	var foreground_arch_rect := Rect2(
		Vector2(world_end.x - 980.0, world_rect.position.y + 360.0),
		Vector2(980.0, 980.0)
	)

	if show_far_cliff_islands:
		_add_single_layer(
			base_root,
			"FarCliffIslands_Parallax2D",
			"FarCliffIslands",
			FAR_CLIFF_ISLANDS_PATH,
			far_cliffs_rect,
			Vector2(0.08, 0.04),
			-218,
			Color(0.58, 0.66, 0.74, 0.22),
			Vector4(0.08, 0.08, 0.12, 0.18)
		)
	if show_causeway_far_arches:
		_add_single_layer(
			reveal_root,
			"CausewayFarArches_Parallax2D",
			"CausewayFarArches",
			CAUSEWAY_FAR_ARCHES_PATH,
			arches_rect,
			Vector2(0.14, 0.07),
			-212,
			Color(0.52, 0.60, 0.68, 0.16),
			Vector4(0.08, 0.08, 0.12, 0.20)
		)
	if show_lower_cliff_depth:
		_add_single_layer(
			base_root,
			"LowerCliffDepth_Parallax2D",
			"LowerCliffDepth",
			LOWER_CLIFF_DEPTH_PATH,
			lower_cliffs_rect,
			Vector2(0.24, 0.13),
			-205,
			Color(0.50, 0.56, 0.62, 0.28),
			Vector4(0.08, 0.08, 0.10, 0.16)
		)
	if show_ocean_mist:
		_add_split_layer(
			base_root,
			"OceanMist_Parallax2D",
			"OceanMist",
			OCEAN_MIST_LEFT_PATH,
			OCEAN_MIST_RIGHT_PATH,
			ocean_mist_rect,
			Vector2(0.42, 0.24),
			-194,
			Color(0.76, 0.82, 0.86, 0.14),
			Vector2(8.0, 2.0),
			Vector2(0.12, 0.09)
		)
	if show_near_edge_mist:
		_add_split_layer(
			foreground_root,
			"NearEdgeMist_Parallax2D",
			"NearEdgeMist",
			NEAR_MIST_LEFT_PATH,
			NEAR_MIST_RIGHT_PATH,
			near_mist_rect,
			Vector2(0.82, 0.72),
			92,
			Color(0.80, 0.84, 0.88, 0.08),
			Vector2(14.0, 4.0),
			Vector2(0.09, 0.07)
		)
	if show_foreground_ruined_arch:
		_add_single_layer(
			foreground_root,
			"ForegroundRuinedArch_Parallax2D",
			"ForegroundRuinedArch",
			FOREGROUND_ARCH_PATH,
			foreground_arch_rect,
			Vector2(1.04, 1.02),
			118,
			Color(0.82, 0.84, 0.88, 0.0),
			Vector4.ZERO
		)


func _build_return_causeway(
	base_root: Node2D,
	reveal_root: Node2D,
	foreground_root: Node2D,
	world_rect: Rect2
) -> void:
	var width := world_rect.size.x
	var map_center_x := world_rect.position.x + width * 0.5

	var keep_rect := Rect2(
		Vector2(map_center_x - 270.0, world_rect.position.y + 395.0),
		Vector2(540.0, 250.0)
	)
	var far_cliffs_rect := Rect2(
		world_rect.position + Vector2(0.0, 120.0),
		Vector2(width, 1152.0)
	)
	var arches_rect := Rect2(
		world_rect.position + Vector2(0.0, 220.0),
		Vector2(width, 1152.0)
	)
	var lower_cliffs_rect := Rect2(
		world_rect.position + Vector2(0.0, 380.0),
		Vector2(width, 1536.0)
	)
	var ocean_mist_rect := Rect2(
		world_rect.position + Vector2(0.0, 540.0),
		Vector2(width, 576.0)
	)
	var near_mist_rect := Rect2(
		world_rect.position + Vector2(0.0, 900.0),
		Vector2(width, 576.0)
	)
	var foreground_arch_rect := Rect2(
		Vector2(map_center_x - 540.0, world_rect.position.y + 250.0),
		Vector2(1080.0, 1080.0)
	)

	_add_single_layer(
		base_root,
		"DistantKeep_Parallax2D",
		"DistantSunderedKeepLandmark",
		DISTANT_KEEP_PATH,
		keep_rect,
		Vector2(0.18, 0.12),
		-128,
		Color(0.78, 0.82, 0.88, 0.76),
		Vector4(0.08, 0.08, 0.10, 0.16)
	)
	if show_far_cliff_islands:
		_add_single_layer(
			base_root,
			"FarCliffIslands_Parallax2D",
			"FarCliffIslands",
			FAR_CLIFF_ISLANDS_PATH,
			far_cliffs_rect,
			Vector2(0.22, 0.12),
			-124,
			Color(0.54, 0.61, 0.68, 0.22),
			Vector4(0.08, 0.08, 0.12, 0.18)
		)
	if show_causeway_far_arches:
		_add_single_layer(
			reveal_root,
			"CausewayFarArches_Parallax2D",
			"CausewayFarArches",
			CAUSEWAY_FAR_ARCHES_PATH,
			arches_rect,
			Vector2(0.30, 0.18),
			-120,
			Color(0.48, 0.55, 0.62, 0.16),
			Vector4(0.08, 0.08, 0.12, 0.18)
		)
	if show_lower_cliff_depth:
		_add_single_layer(
			base_root,
			"LowerCliffDepth_Parallax2D",
			"LowerCliffDepth",
			LOWER_CLIFF_DEPTH_PATH,
			lower_cliffs_rect,
			Vector2(0.36, 0.22),
			-116,
			Color(0.46, 0.51, 0.57, 0.28),
			Vector4(0.08, 0.08, 0.10, 0.16)
		)
	if show_ocean_mist:
		_add_split_layer(
			base_root,
			"OceanMist_Parallax2D",
			"OceanMist",
			OCEAN_MIST_LEFT_PATH,
			OCEAN_MIST_RIGHT_PATH,
			ocean_mist_rect,
			Vector2(0.46, 0.28),
			-110,
			Color(0.74, 0.80, 0.84, 0.14),
			Vector2(8.0, 2.0),
			Vector2(0.12, 0.09)
		)
	if show_foreground_ruined_arch:
		_add_single_layer(
			foreground_root,
			"ForegroundRuinedArch_Parallax2D",
			"ForegroundRuinedArch",
			FOREGROUND_ARCH_PATH,
			foreground_arch_rect,
			Vector2(1.04, 1.02),
			22,
			Color(0.82, 0.84, 0.88, 0.0),
			Vector4.ZERO
		)
	if show_near_edge_mist:
		_add_split_layer(
			foreground_root,
			"NearEdgeMist_Parallax2D",
			"NearEdgeMist",
			NEAR_MIST_LEFT_PATH,
			NEAR_MIST_RIGHT_PATH,
			near_mist_rect,
			Vector2(0.82, 0.72),
			24,
			Color(0.80, 0.84, 0.88, 0.08),
			Vector2(14.0, 4.0),
			Vector2(0.09, 0.07)
		)


func _add_single_layer(
	parent: Node2D,
	layer_name: String,
	sprite_name: String,
	texture_path: String,
	target_rect: Rect2,
	scroll_scale: Vector2,
	z: int,
	tint: Color,
	feather: Vector4
) -> void:
	var layer := _make_layer(parent, layer_name, scroll_scale, z)
	_add_fitted_sprite(
		layer,
		sprite_name,
		texture_path,
		target_rect,
		tint,
		feather
	)


func _add_split_layer(
	parent: Node2D,
	layer_name: String,
	sprite_prefix: String,
	left_path: String,
	right_path: String,
	target_rect: Rect2,
	scroll_scale: Vector2,
	z: int,
	tint: Color,
	drift_amplitude: Vector2,
	drift_speed: Vector2
) -> void:
	var layer := _make_layer(parent, layer_name, scroll_scale, z)
	var half_width := target_rect.size.x * 0.5
	var left_rect := Rect2(
		target_rect.position,
		Vector2(half_width + STRIP_OVERLAP_PX, target_rect.size.y)
	)
	var right_rect := Rect2(
		target_rect.position + Vector2(
			half_width - STRIP_OVERLAP_PX,
			0.0
		),
		Vector2(half_width + STRIP_OVERLAP_PX, target_rect.size.y)
	)

	_add_fitted_sprite(
		layer,
		"%sLeft" % sprite_prefix,
		left_path,
		left_rect,
		tint,
		Vector4(0.06, 0.18, 0.10, 0.12)
	)
	_add_fitted_sprite(
		layer,
		"%sRight" % sprite_prefix,
		right_path,
		right_rect,
		tint,
		Vector4(0.18, 0.06, 0.10, 0.12)
	)

	_drift_layers.append({
		"node": layer,
		"amplitude": drift_amplitude,
		"speed": drift_speed,
	})


func _make_group(group_name: String, alpha: float) -> Node2D:
	var group := Node2D.new()
	group.name = group_name
	group.z_as_relative = false
	group.z_index = 0
	group.modulate.a = alpha
	add_child(group)
	return group


func _make_layer(
	parent: Node2D,
	layer_name: String,
	scroll_scale: Vector2,
	z: int
) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.name = layer_name
	layer.follow_viewport = true
	layer.ignore_camera_scroll = false
	layer.scroll_scale = scroll_scale
	layer.scroll_offset = Vector2.ZERO
	layer.repeat_size = Vector2.ZERO
	layer.repeat_times = 1
	layer.z_as_relative = false
	layer.z_index = z
	parent.add_child(layer)
	return layer


func _add_fitted_sprite(
	parent: Node,
	sprite_name: String,
	texture_path: String,
	target_rect: Rect2,
	tint: Color,
	feather: Vector4
) -> Sprite2D:
	var texture := _load_texture(texture_path)
	if texture == null:
		return null

	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = false
	sprite.position = target_rect.position
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	sprite.z_as_relative = true
	sprite.z_index = 0

	var texture_size := texture.get_size()
	sprite.scale = Vector2(
		target_rect.size.x / maxf(texture_size.x, 1.0),
		target_rect.size.y / maxf(texture_size.y, 1.0)
	)

	if (
		feather.x > 0.0
		or feather.y > 0.0
		or feather.z > 0.0
		or feather.w > 0.0
	):
		var material := ShaderMaterial.new()
		material.shader = SOFT_RECT_FEATHER_SHADER
		material.set_shader_parameter("feather_left", feather.x)
		material.set_shader_parameter("feather_right", feather.y)
		material.set_shader_parameter("feather_top", feather.z)
		material.set_shader_parameter("feather_bottom", feather.w)
		sprite.material = material

	parent.add_child(sprite)
	return sprite


func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	if not ResourceLoader.exists(path):
		_missing_assets += 1
		_texture_cache[path] = null
		push_error(
			"[SunderedKeepParallaxRig] Missing required texture: %s" % path
		)
		return null

	var texture := load(path) as Texture2D
	if texture == null:
		_missing_assets += 1
		push_error(
			"[SunderedKeepParallaxRig] Failed to load texture: %s" % path
		)

	_texture_cache[path] = texture
	return texture


func _clear_runtime_children() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
