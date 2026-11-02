extends AuthoredLevel2D
class_name LordsOfPainTestGallery

const BOUNDARY_SEGMENTS := [
]

const AUTHORING_MARKERS := {
	"spawn": {
		"node_name": "Spawn_Main",
		"label": "MAIN ENTRY",
		"kind": "spawn",
		"position": Vector2.ZERO,
	},
	"return_main": {
		"node_name": "Return_Main",
		"label": "RETURN TO MAIN WORLD",
		"kind": "level_exit",
		"position": Vector2(96.0, 0.0),
	},
}

const MANIFEST_PATH := "res://content/data/dev/lords_of_pain/gallery_manifest.json"
const MERIDIAN_FLOOR := "res://content/tiles/procgen/surfaces/hardened/meridian_hardened_floor_base_v1_32.png"
const DIRECTIONS := ["n", "nne", "ne", "nee", "e", "see", "se", "sse", "s", "ssw", "sw", "sww", "w", "nww", "nw", "nnw"]
const COLORS := {"stone": Color("#434750"), "hardstand": Color("#6b7075"), "aisle": Color("#88867d")}
var _manifest: Dictionary
var _actor_state := 0
var _actor_direction := 0
var _gold_collected := false
var _readout: Label
var _gold_sprite: AnimatedSprite2D
var _actor_specs: Array[Dictionary] = []


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS


func _ready() -> void:
	super._ready()
	_manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	_build_gallery()


func _build_gallery() -> void:
	var background := get_node("BackgroundRoot")
	var playable := get_node("PlayableRoot")
	var props := get_node("PropsRoot")
	# Three connected lanes make terrain comparison and the two animated actors easy to inspect.
	_add_floor(background, Rect2(-1856, -992, 1152, 1984), COLORS.stone, "STONE COURT")
	_add_ground_stone_tiles(background)
	_add_floor(background, Rect2(-576, -992, 1152, 1984), COLORS.hardstand, "HARDSTAND")
	_add_meridian_floor(background)
	_add_floor(background, Rect2(704, -992, 1152, 1984), COLORS.aisle, "ACTOR + VFX LAB")
	_add_label(background, "SPAWN / RETURN CONCOURSE", Vector2(0, -900), 24)
	_add_label(background, "LORDS OF PAIN · DEMO PACK", Vector2(-1770, -900), 28)
	_add_label(background, "CUSTODIAN HARDENED FLOOR", Vector2(-510, -900), 20)
	_add_label(background, "16 DIRECTION ACTOR DISPLAYS", Vector2(770, -900), 20)
	var stone_a := _spawn_state_sprite(playable, "dev_lop_ground_stone", "ground_stone", Vector2(-1400, -250), 512)
	var stone_b := _spawn_state_sprite(playable, "dev_lop_ground_stone", "ground_stone", Vector2(-850, -250), 512)
	var stone_c := _spawn_state_sprite(playable, "dev_lop_ground_stone", "ground_stone", Vector2(-1400, 320), 512)
	if stone_b != null: stone_b.modulate = Color(0.82, 0.82, 0.9)
	if stone_c != null: stone_c.modulate = Color(0.45, 0.45, 0.5)
	_add_label(playable, "Ground Stone · Base / Variant tint / Darken tint", Vector2(-1730, -560), 17)
	_gold_sprite = _spawn_state_sprite(props, "dev_lop_gold_drop", "idle_s", Vector2(0, 100), 256)
	_spawn_state_sprite(props, "dev_lop_glint", "glint", Vector2(0, -140), 256)
	_add_label(props, "E · collect / reset Gold Drop", Vector2(-235, 320), 20)
	_add_label(props, "Glint loop sample", Vector2(-170, -330), 18)
	_add_actor_display(playable, "dev_lop_warrior", ["armed_idle", "armed_walk"], Vector2(1150, -250), "WARRIOR")
	_add_actor_display(playable, "dev_lop_skeleton", ["default_walk", "special_death"], Vector2(1150, 450), "SKELETON")
	_readout = Label.new()
	_readout.name = "GalleryReadout"
	_readout.position = Vector2(1390, -480)
	_readout.custom_minimum_size = Vector2(520, 0)
	_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readout.add_theme_font_size_override("font_size", 17)
	playable.add_child(_readout)
	_update_readout()
	var ui := CanvasLayer.new()
	ui.name = "GalleryInstructions"
	add_child(ui)
	var instructions := Label.new()
	instructions.text = "LORDS OF PAIN TEST GALLERY   ·   E collect/reset   ·   arrows cycle actor direction/state"
	instructions.position = Vector2(24, 24)
	instructions.add_theme_font_size_override("font_size", 18)
	ui.add_child(instructions)
	_add_ui_sample(ui, "dev_lop_highlight", "highlight_yellow", "HIGHLIGHT", Vector2(24, 500))
	_add_ui_sample(ui, "dev_lop_loot_indicator", "loot_indicator_yellow", "LOOT INDICATOR", Vector2(196, 500))


func _add_floor(parent: Node, rect: Rect2, color: Color, node_name: String) -> void:
	var floor := Polygon2D.new()
	floor.name = node_name.replace(" ", "")
	floor.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	floor.color = color
	floor.z_index = -10
	parent.add_child(floor)


func _add_meridian_floor(parent: Node) -> void:
	var texture := load(MERIDIAN_FLOOR) as Texture2D
	if texture == null: return
	for row in range(30):
		for column in range(9):
			var tile := Sprite2D.new()
			tile.texture = texture
			tile.name = "MeridianFloor_%02d_%02d" % [row, column]
			tile.scale = Vector2(0.5, 0.5)
			tile.position = Vector2(-512 + column * 128, -928 + row * 64)
			tile.z_index = -9
			parent.add_child(tile)


func _add_ground_stone_tiles(parent: Node) -> void:
	var entry := _find_entry("dev_lop_ground_stone", "ground_stone")
	if entry.is_empty(): return
	var texture := load(str(entry.get("runtime_path", ""))) as Texture2D
	if texture == null: return
	for row in range(10):
		for column in range(6):
			var tile := Sprite2D.new()
			tile.name = "GroundStone_%02d_%02d" % [row, column]
			tile.texture = texture
			tile.position = Vector2(-1760 + column * 192, -896 + row * 192)
			tile.scale = Vector2(0.75, 0.75)
			tile.z_index = -9
			parent.add_child(tile)


func _add_label(parent: Node, text: String, position: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)


func _spawn_state_sprite(parent: Node, family: String, state: String, position: Vector2, frame_size: int) -> AnimatedSprite2D:
	var entry := _find_entry(family, state)
	if entry.is_empty():
		return null
	var texture := load(str(entry.runtime_path)) as Texture2D
	if texture == null:
		return null
	var frames := SpriteFrames.new()
	frames.add_animation("sample")
	frames.set_animation_speed("sample", float(entry.get("fps", 8)))
	frames.set_animation_loop("sample", bool(entry.get("loop", true)))
	var size: Array = entry.get("frame_size", [frame_size, frame_size])
	for i in range(int(entry.get("frame_count", 1))):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * int(size[0]), 0, int(size[0]), int(size[1]))
		frames.add_frame("sample", atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = position
	sprite.name = "%s_%s" % [family, state]
	parent.add_child(sprite)
	if family == "dev_lop_gold_drop": sprite.scale = Vector2(3.0, 3.0)
	if family == "dev_lop_glint": sprite.scale = Vector2(4.0, 4.0)
	sprite.play("sample")
	return sprite


func _add_ui_sample(parent: CanvasLayer, family: String, state: String, caption: String, position: Vector2) -> void:
	var entry := _find_entry(family, state)
	if entry.is_empty(): return
	var sample := TextureRect.new()
	sample.name = family
	sample.texture = load(str(entry.get("runtime_path", "")))
	sample.position = position
	sample.custom_minimum_size = Vector2(160, 160)
	sample.size = Vector2(160, 160)
	sample.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sample.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(sample)
	var label := Label.new()
	label.text = caption
	label.position = position + Vector2(0, 164)
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)


func _add_actor_display(parent: Node, family: String, states: Array[String], position: Vector2, title: String) -> void:
	var holder := Node2D.new()
	holder.name = "%sDisplay" % title
	holder.position = position
	parent.add_child(holder)
	_add_label(holder, title, Vector2(-90, -210), 22)
	_actor_specs.append({"family": family, "states": states, "holder": holder, "title": title})
	_refresh_actor_displays()


func _add_sprite_from_entry(parent: Node, entry: Dictionary, position: Vector2, node_name: String) -> AnimatedSprite2D:
	if entry.is_empty(): return null
	var texture := load(str(entry.get("runtime_path", ""))) as Texture2D
	if texture == null: return null
	var size: Array = entry.get("frame_size", [256, 256])
	var frames := SpriteFrames.new()
	frames.add_animation("sample")
	frames.set_animation_speed("sample", float(entry.get("fps", 8)))
	frames.set_animation_loop("sample", bool(entry.get("loop", true)))
	for i in range(int(entry.get("frame_count", 1))):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * int(size[0]), 0, int(size[0]), int(size[1]))
		frames.add_frame("sample", atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.name = node_name
	sprite.position = position
	sprite.sprite_frames = frames
	parent.add_child(sprite)
	sprite.play("sample")
	return sprite


func _find_entry(family: String, state: String) -> Dictionary:
	for raw: Variant in _manifest.get("states", []):
		if raw is Dictionary and raw.get("family_id") == family and raw.get("state_id") == state:
			return raw
	return {}


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_E:
			_gold_collected = not _gold_collected
			if _gold_sprite != null: _gold_sprite.visible = not _gold_collected
			_update_readout()
		KEY_LEFT, KEY_RIGHT:
			_actor_direction = wrapi(_actor_direction + (1 if event.keycode == KEY_RIGHT else -1), 0, DIRECTIONS.size())
			_update_readout()
		KEY_UP, KEY_DOWN:
			_actor_state = wrapi(_actor_state + (1 if event.keycode == KEY_DOWN else -1), 0, 2)
			_update_readout()


func _update_readout() -> void:
	if _readout == null: return
	var state_names: Array[String] = []
	for spec in _actor_specs:
		var state_id := "%s_%s" % [spec.states[_actor_state], DIRECTIONS[_actor_direction]]
		var entry := _find_entry(spec.family, state_id)
		var provenance: Array = entry.get("source_files", [])
		var source_file := str(provenance[0]).get_file() if not provenance.is_empty() else "source unavailable"
		state_names.append("%s · %s · %d frames\nLords of Pain DEMO · %s" % [spec.title, state_id, int(entry.get("frame_count", 0)), source_file])
	_readout.text = "%s\nGold Drop: %s\nArrows: direction / animation" % ["\n".join(state_names), "collected" if _gold_collected else "available"]
	_refresh_actor_displays()


func _refresh_actor_displays() -> void:
	for spec in _actor_specs:
		var holder: Node2D = spec.holder
		var old := holder.get_node_or_null("ActorSprite")
		if old != null:
			holder.remove_child(old)
			old.free()
		var state := "%s_%s" % [spec.states[_actor_state], DIRECTIONS[_actor_direction]]
		_add_sprite_from_entry(holder, _find_entry(spec.family, state), Vector2.ZERO, "ActorSprite")
